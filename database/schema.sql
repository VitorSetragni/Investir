-- Execute no SQL Editor do Supabase antes de subir o backend.
-- Tabelas privadas: os apps consultam somente a API FastAPI.
create table if not exists public.snapshots (
 kind varchar(12) primary key check (kind in ('stocks','fiis')),
 reference varchar(7), filename text, sha256 varchar(64),
 imported_at timestamptz, imported_by varchar(128),
 revision integer not null default 0, count integer not null default 0
);
create table if not exists public.assets (
 ticker varchar(12) primary key,
 kind varchar(12) not null references public.snapshots(kind),
 name text not null, category varchar(30) not null, segment text not null,
 source_row integer not null, data json not null, assessment json not null
);
create index if not exists ix_assets_kind on public.assets(kind);
create index if not exists ix_assets_category on public.assets(category);
create table if not exists public.market_cache (
 ticker varchar(12) primary key, fetched_at timestamptz not null, payload json not null
);
insert into public.snapshots(kind) values ('stocks'),('fiis') on conflict do nothing;
alter table public.snapshots enable row level security;
alter table public.assets enable row level security;
alter table public.market_cache enable row level security;
-- Negação explícita e restritiva: o cliente usa FastAPI, não a Data API.
do $policies$
declare table_name text;
begin
 foreach table_name in array array['assets','snapshots','market_cache'] loop
  if not exists (select 1 from pg_policies where schemaname='public' and tablename=table_name and policyname='deny_direct_client_access') then
   execute format('create policy deny_direct_client_access on public.%I as restrictive for all to anon, authenticated using (false) with check (false)',table_name);
  end if;
 end loop;
end
$policies$;
revoke all on public.snapshots, public.assets, public.market_cache from anon, authenticated;
-- Backend usa a conexão Postgres do proprietário via pooler TLS.
