-- Rangliste für Cursed Descent
-- Einmal im Supabase-Dashboard unter "SQL Editor" ausführen.

create table if not exists public.laeufe (
  id         bigint generated always as identity primary key,
  erstellt   timestamptz not null default now(),
  spieler_id uuid not null,
  name       text not null check (char_length(name) between 1 and 20),
  modus      text not null check (modus in ('normal', 'tag')),
  tag        text check (tag is null or tag ~ '^\d{4}-\d{1,2}-\d{1,2}$'),
  raum       int  not null check (raum between 1 and 1000),
  bosse      int  not null check (bosse between 0 and 200),
  level      int  not null check (level between 1 and 1000),
  klasse     text not null check (klasse in ('krieger', 'schurke', 'magier')),
  fluch      int  not null check (fluch between 0 and 5),
  ergebnis   text not null check (ergebnis in ('Sieg', 'Niederlage', 'Geflohen'))
);

create index if not exists laeufe_modus_tag on public.laeufe (modus, tag, raum desc);

-- Jeder darf lesen und eintragen, aber nichts ändern oder löschen
alter table public.laeufe enable row level security;
drop policy if exists "lesen" on public.laeufe;
drop policy if exists "eintragen" on public.laeufe;
create policy "lesen" on public.laeufe for select to anon using (true);
create policy "eintragen" on public.laeufe for insert to anon with check (true);
grant select, insert on public.laeufe to anon;

-- Bester Lauf je Spieler: Allzeit (alle Modi) und je Tag im Tages-Dungeon
create or replace view public.rangliste_allzeit with (security_invoker = true) as
  select distinct on (spieler_id) spieler_id, name, raum, bosse, level, klasse, fluch, erstellt
  from public.laeufe
  order by spieler_id, raum desc, bosse desc, fluch desc, erstellt;

create or replace view public.rangliste_tag with (security_invoker = true) as
  select distinct on (tag, spieler_id) tag, spieler_id, name, raum, bosse, level, erstellt
  from public.laeufe
  where modus = 'tag'
  order by tag, spieler_id, raum desc, bosse desc, erstellt;

grant select on public.rangliste_allzeit, public.rangliste_tag to anon;
