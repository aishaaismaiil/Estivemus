-- Estivemus: camada de dados da app (fase 1). Corre este ficheiro no SQL Editor do Supabase.
-- Guarda os dados da app como documentos, com regras de privacidade (RLS) por coleção.
create table if not exists docs (
  col text not null,
  id text not null,
  owner uuid not null default auth.uid(),
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (col, id)
);
alter table docs enable row level security;

-- reconhecimento mútuo: eu reconheço o outro E o outro reconhece-me
create or replace function docs_mutual(other text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from docs a where a.col='recs' and a.id=other and a.data->'yes' ? auth.uid()::text)
     and exists (select 1 from docs b where b.col='recs' and b.id=auth.uid()::text and b.data->'yes' ? other)
$$;

create or replace function docs_keep_owner() returns trigger language plpgsql as $$
begin new.owner := old.owner; new.updated_at := now(); return new; end $$;
drop trigger if exists docs_keep_owner on docs;
create trigger docs_keep_owner before update on docs for each row execute function docs_keep_owner();

drop policy if exists docs_select on docs;
create policy docs_select on docs for select to authenticated using (
  owner = auth.uid()
  or col in ('profiles','institutions','photos','events')
  or (col = 'recs' and data->'yes' ? auth.uid()::text)   -- só vê quem me reconheceu
  or (col = 'contacts' and docs_mutual(id))              -- contacto só quando é mútuo
);
drop policy if exists docs_insert on docs;
create policy docs_insert on docs for insert to authenticated with check (
  owner = auth.uid()
  and (col not in ('profiles','recs','contacts') or id = auth.uid()::text)
);
drop policy if exists docs_update on docs;
create policy docs_update on docs for update to authenticated
  using (owner = auth.uid() or col in ('events','photos'))
  with check (true);
drop policy if exists docs_delete on docs;
create policy docs_delete on docs for delete to authenticated using (owner = auth.uid());
