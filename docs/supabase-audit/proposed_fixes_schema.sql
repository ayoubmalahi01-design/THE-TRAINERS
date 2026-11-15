-- ============================================================================
-- THE TRAINERS – تدريب — PROPOSED ADDITIVE SCHEMA FIXES (NOT EXECUTED)
-- Target project: rxkyryaplszuklagvidi
-- Mode: READ-ONLY audit deliverable. Review before running. Do not run blindly.
-- ============================================================================

-- §1  messages.read_at (P0) — safe additive fix; column is nullable; table is empty.
alter table public.messages
  add column if not exists read_at timestamptz;

-- §2  conversation_members.id (P1) — RECOMMENDATION ONLY.
-- Live DB uses a composite PK (conversation_id, profile_id); SQL declares id uuid PK.
-- Nothing in the app references conversation_members.id. Recommended: update the SQL
-- file to drop the id column (match live). NOT auto-applied here because changing a
-- PK is not additive and could break anything externally referencing it (none found,
-- but cannot verify via REST). If you prefer parity the other way, uncomment:
-- alter table public.conversation_members add column if not exists id uuid default gen_random_uuid();
-- (would require dropping/recreating the PK — NOT recommended on a populated DB).

-- §3  Five tables missing from repo SQL (P1) — reproducibility fix.
-- These exist in the live DB and are used by the app, but have no CREATE TABLE in
-- THE_TRAINERS_SETUP.sql. Add them so a fresh project reproduces the schema.
-- Column lists derived from the app (src/App.tsx) and live DB probes.

create table if not exists public.admin_notices (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete cascade,
  title text not null, body text not null,
  author_id uuid not null references public.profiles(id) on delete cascade,
  is_published boolean not null default true,
  published_at timestamptz, created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid references public.institutions(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null, table_name text not null, record_id text,
  old_data jsonb, new_data jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.coach_notebooks (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete cascade,
  coach_id uuid not null references public.profiles(id) on delete cascade,
  title text not null, body text not null,
  entry_date date not null default current_date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  title text not null, body text not null,
  notification_type text not null default 'info',
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.student_notes (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  note_type text not null default 'general',
  body text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- §4  message_reads reconciliation (P0) — DO NOT RUN BLINDLY.
-- Live schema differs from SQL (live: read_at, message_id; SQL: conversation_id, profile_id, last_read_at).
-- Table is empty, so either migration is data-safe, but the RPCs (unread_counts, mark_conversation_read)
-- must be reconciled first (read pg_proc in the Dashboard). Choose ONE option after review:

-- Option A (make live match SQL): only if the live RPCs are rewritten to use conversation_id/profile_id/last_read_at.
-- alter table public.message_reads add column if not exists conversation_id uuid references public.conversations(id) on delete cascade;
-- alter table public.message_reads add column if not exists profile_id uuid references public.profiles(id) on delete cascade;
-- alter table public.message_reads add column if not exists last_read_at timestamptz not null default now();
-- (then drop read_at/message_id only after confirming no RPC depends on them)

-- Option B (make SQL match live): update THE_TRAINERS_SETUP.sql and the RPCs to use read_at/message_id.
-- No live ALTER needed; only documentation + RPC rewrite. Recommended if the live RPCs already work against read_at/message_id.

-- §5  Note: institutions uses `email` (not `contact_email`) and `logo_path` (not `logo_url`).
-- No change needed; documented for parity. The earlier audit's `contact_email`/`logo_url` probes were false positives.
