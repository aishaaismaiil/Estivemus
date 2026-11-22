-- Estivemus: reforço de segurança e privacidade (v2).
-- Corre este ficheiro INTEIRO no SQL Editor do Supabase, DEPOIS de docs.sql. Pode ser corrido mais do que uma vez.
-- NÃO FOI TESTADO contra a base de dados real. Testa com duas contas de teste (A e B) antes de divulgar:
--   1) A cria perfil com a escola X, ano 2000; B cria perfil com a mesma escola e ano.
--   2) B vê a foto de A; uma terceira conta C, sem a escola X, NÃO vê a foto.
--   3) B consegue marcar A na foto (fica pendente); C não consegue alterar nada.
--   4) A perfil escondido (Privacidade > desligar "Aparecer nas procuras") deixa de aparecer a B.
-- Se algo correr mal: volta a correr docs.sql e depois  drop trigger if exists docs_guard_update on docs;

-- 1) Limites: nada de documentos gigantes nem nomes de coleção/ids estranhos
alter table docs drop constraint if exists docs_size;
alter table docs add constraint docs_size check (octet_length(data::text) <= 600000) not valid;
alter table docs drop constraint if exists docs_names;
alter table docs add constraint docs_names check (char_length(col) <= 120 and char_length(id) <= 120) not valid;

-- 2) Funções auxiliares (cast seguro: um documento mal formado nunca pode rebentar a leitura dos outros)
create or replace function docs_shares_inst(inst text, yr text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from docs p,
         jsonb_array_elements(case when jsonb_typeof(p.data->'history') = 'array' then p.data->'history' else '[]'::jsonb end) h
    where p.col = 'profiles' and p.id = auth.uid()::text
      and h->>'instId' = inst
      and case when yr ~ '^[0-9]{4}$' and (h->>'from') ~ '^[0-9]{4}$' and (h->>'to') ~ '^[0-9]{4}$'
               then (h->>'from')::int <= yr::int and yr::int <= (h->>'to')::int
               else false end
  )
$$;

create or replace function docs_in_inst(inst text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from docs p,
         jsonb_array_elements(case when jsonb_typeof(p.data->'history') = 'array' then p.data->'history' else '[]'::jsonb end) h
    where p.col = 'profiles' and p.id = auth.uid()::text and h->>'instId' = inst
  )
$$;

-- 3) Leitura: perfis escondidos ficam escondidos no servidor; fotos só para quem esteve lá nesse ano; eventos só para membros
drop policy if exists docs_select on docs;
create policy docs_select on docs for select to authenticated using (
  owner = auth.uid()
  or col = 'institutions'
  or (col = 'profiles' and coalesce(data->'privacy'->>'hidden', 'false') <> 'true')
  or (col = 'photos' and docs_shares_inst(data->>'instId', data->>'year'))
  or (col = 'events' and docs_in_inst(data->>'instId'))
  or (col = 'recs' and data->'yes' ? auth.uid()::text)
  or (col = 'contacts' and docs_mutual(id))
);

-- 4) Escrita: um não-dono só pode mexer no que lhe diz respeito (o próprio voto, as marcações que fez ou que lhe fazem a ele)
create or replace function docs_guard_update() returns trigger language plpgsql as $$
declare
  me text := auth.uid()::text;
  ov jsonb; nv jsonb; ot jsonb; nt jsonb; k text;
begin
  new.updated_at := now();
  -- chamadas feitas por funções internas (ex.: delete_my_account) não são limitadas
  if current_user not in ('authenticated', 'anon') then return new; end if;
  new.owner := old.owner; new.col := old.col; new.id := old.id;
  if auth.uid() is null or old.owner = auth.uid() then return new; end if;

  if old.col = 'events' then
    if (new.data - 'votes') is distinct from (old.data - 'votes') then
      raise exception 'sem permissão' using errcode = '42501';
    end if;
    ov := case when jsonb_typeof(old.data->'votes') = 'object' then old.data->'votes' else '{}'::jsonb end;
    nv := case when jsonb_typeof(new.data->'votes') = 'object' then new.data->'votes' else '{}'::jsonb end;
    if (ov - me) is distinct from (nv - me) then
      raise exception 'só podes alterar o teu voto' using errcode = '42501';
    end if;
  elsif old.col = 'photos' then
    if (new.data - 'tags') is distinct from (old.data - 'tags') then
      raise exception 'sem permissão' using errcode = '42501';
    end if;
    ot := case when jsonb_typeof(old.data->'tags') = 'object' then old.data->'tags' else '{}'::jsonb end;
    nt := case when jsonb_typeof(new.data->'tags') = 'object' then new.data->'tags' else '{}'::jsonb end;
    for k in select jsonb_object_keys(ot) union select jsonb_object_keys(nt) loop
      if (ot->k) is distinct from (nt->k) then
        if coalesce(ot->k->>'uid', '') <> me and coalesce(ot->k->>'by', '') <> me and coalesce(nt->k->>'by', '') <> me then
          raise exception 'só podes mexer nas tuas marcações' using errcode = '42501';
        end if;
        -- só a pessoa marcada pode aprovar a marcação
        if coalesce(nt->k->>'status', '') = 'ok' and coalesce(ot->k->>'status', '') <> 'ok' and coalesce(nt->k->>'uid', '') <> me then
          raise exception 'só a pessoa marcada pode aprovar' using errcode = '42501';
        end if;
      end if;
    end loop;
  else
    raise exception 'sem permissão' using errcode = '42501';
  end if;
  return new;
end $$;
drop trigger if exists docs_keep_owner on docs;
drop trigger if exists docs_guard_update on docs;
create trigger docs_guard_update before update on docs for each row execute function docs_guard_update();

-- 5) Apagar conta de verdade (RGPD, direito ao apagamento): dados, marcações, votos, reconhecimentos e o próprio email de login
create or replace function delete_my_account() returns void
language plpgsql security definer set search_path = public, auth as $$
declare me uuid := auth.uid();
begin
  if me is null then raise exception 'sem sessão' using errcode = '42501'; end if;
  -- tirar as minhas marcações das fotos de outras pessoas
  update docs set data = jsonb_set(data, '{tags}',
      coalesce((select jsonb_object_agg(t.k, t.v) from jsonb_each(data->'tags') as t(k, v) where t.v->>'uid' is distinct from me::text), '{}'::jsonb))
   where col = 'photos' and jsonb_typeof(data->'tags') = 'object'
     and exists (select 1 from jsonb_each(data->'tags') as t(k, v) where t.v->>'uid' = me::text);
  -- tirar os meus votos
  update docs set data = jsonb_set(data, '{votes}', (data->'votes') - me::text)
   where col = 'events' and jsonb_typeof(data->'votes') = 'object' and data->'votes' ? me::text;
  -- tirar-me dos reconhecimentos dos outros
  update docs set data = jsonb_set(data, '{yes}', (data->'yes') - me::text)
   where col = 'recs' and jsonb_typeof(data->'yes') = 'object' and data->'yes' ? me::text;
  -- as instituições que criei ficam (outros dependem delas), mas deixam de estar ligadas a mim
  update docs set owner = '00000000-0000-0000-0000-000000000000', data = data - 'by'
   where owner = me and col = 'institutions';
  delete from docs where owner = me;
  delete from auth.users where id = me;
end $$;
revoke all on function delete_my_account() from public, anon;
grant execute on function delete_my_account() to authenticated;
