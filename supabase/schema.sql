-- Estivemus: esquema Postgres (Supabase). NÃO TESTADO. Rever antes de usar.
create extension if not exists pgcrypto;

create table profiles (
  id uuid primary key references auth.users on delete cascade,
  name text not null check (char_length(name) between 2 and 120),
  school_name text, about text, contact text, photo text,
  show_surname boolean not null default false,
  hidden boolean not null default false,
  allow_tags boolean not null default true,
  adult_confirmed boolean not null default false check (adult_confirmed),
  created_at timestamptz not null default now()
);
create table institutions (
  id uuid primary key default gen_random_uuid(),
  name text not null, municipality text, country text not null default 'PT',
  created_by uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (lower(name), lower(coalesce(municipality,'')), country)
);
create table education (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  institution_id uuid not null references institutions(id),
  levels text[] not null check (levels <@ array['creche','pre','c1','c2','c3','sec','sup']),
  year_from int not null check (year_from between 1930 and 2100),
  year_to int not null, ongoing boolean not null default false,
  class_name text, note text, era_photo_id uuid,
  check (year_to >= year_from)
);
create index on education (institution_id, year_from, year_to);
create table photos (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references institutions(id),
  year int not null, caption text, storage_path text not null, is_era boolean not null default false,
  uploaded_by uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table photo_tags (
  id uuid primary key default gen_random_uuid(),
  photo_id uuid not null references photos(id) on delete cascade,
  tagged_user uuid not null references profiles(id) on delete cascade,
  tagged_by uuid not null references profiles(id) on delete cascade,
  x numeric not null, y numeric not null,
  status text not null default 'pending' check (status in ('pending','ok'))
);
create table recognitions (
  from_user uuid not null references profiles(id) on delete cascade,
  to_user uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (from_user, to_user), check (from_user <> to_user)
);
create table swipes_no (user_id uuid references profiles(id) on delete cascade, other uuid references profiles(id) on delete cascade, primary key (user_id, other));
create table blocks (user_id uuid references profiles(id) on delete cascade, other uuid references profiles(id) on delete cascade, primary key (user_id, other));
create table events (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references institutions(id),
  title text not null, dates date[] not null, created_by uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table event_votes (event_id uuid references events(id) on delete cascade, user_id uuid references profiles(id) on delete cascade, date_index int not null, primary key (event_id,user_id));
create table reports (id uuid primary key default gen_random_uuid(), reporter uuid references profiles(id) on delete set null, kind text, target uuid, created_at timestamptz default now());

-- Pessoas que partilharam instituição/ano com o utilizador autenticado
create or replace function shares_with_me(other uuid) returns boolean language sql stable security definer set search_path=public as $$
  select exists (select 1 from education a join education b on a.institution_id=b.institution_id
    and a.year_from<=b.year_to and b.year_from<=a.year_to
    where a.user_id=auth.uid() and b.user_id=other)
$$;
create or replace function mutual(other uuid) returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from recognitions where from_user=auth.uid() and to_user=other)
     and exists(select 1 from recognitions where from_user=other and to_user=auth.uid())
$$;

alter table profiles enable row level security; alter table institutions enable row level security;
alter table education enable row level security; alter table photos enable row level security;
alter table photo_tags enable row level security; alter table recognitions enable row level security;
alter table swipes_no enable row level security; alter table blocks enable row level security;
alter table events enable row level security; alter table event_votes enable row level security;
alter table reports enable row level security;

-- Perfis: o próprio escreve; membros veem perfis não escondidos (contacto só via view/função quando "mutual")
create policy p_self on profiles for all using (id=auth.uid()) with check (id=auth.uid());
create policy p_read on profiles for select using (auth.uid() is not null and not hidden
  and not exists(select 1 from blocks b where b.user_id=profiles.id and b.other=auth.uid()));
create policy i_read on institutions for select using (auth.uid() is not null);
create policy i_ins on institutions for insert with check (created_by=auth.uid());
create policy e_self on education for all using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy e_read on education for select using (auth.uid() is not null);
create policy ph_read on photos for select using (uploaded_by=auth.uid() or exists(
  select 1 from education e where e.user_id=auth.uid() and e.institution_id=photos.institution_id and photos.year between e.year_from and e.year_to));
create policy ph_write on photos for all using (uploaded_by=auth.uid()) with check (uploaded_by=auth.uid());
create policy t_read on photo_tags for select using (tagged_user=auth.uid() or tagged_by=auth.uid() or status='ok');
create policy t_ins on photo_tags for insert with check (tagged_by=auth.uid());
create policy t_upd on photo_tags for update using (tagged_user=auth.uid());
create policy t_del on photo_tags for delete using (tagged_user=auth.uid() or tagged_by=auth.uid());
create policy r_ins on recognitions for insert with check (from_user=auth.uid());
create policy r_read on recognitions for select using (from_user=auth.uid() or to_user=auth.uid());
create policy r_del on recognitions for delete using (from_user=auth.uid());
create policy sn_all on swipes_no for all using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy bl_all on blocks for all using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy ev_read on events for select using (exists(select 1 from education e where e.user_id=auth.uid() and e.institution_id=events.institution_id));
create policy ev_ins on events for insert with check (created_by=auth.uid());
create policy v_all on event_votes for all using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy rep_ins on reports for insert with check (reporter=auth.uid());
-- Nota: o campo profiles.contact NÃO deve ser lido diretamente; expor por função que verifica mutual(id).
