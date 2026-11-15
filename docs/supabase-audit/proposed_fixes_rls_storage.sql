-- ============================================================================
-- THE TRAINERS – تدريب — PROPOSED RLS / STORAGE / POLICY TEMPLATES (NOT EXECUTED)
-- Target project: rxkyryaplszuklagvidi
-- Mode: READ-ONLY audit deliverable. Templates only — apply after verifying the
-- current state in the Dashboard (pg_policies, storage.buckets, storage.objects).
-- ============================================================================

-- §1  Enable RLS on every app table (idempotent).
do $$ declare t text; begin
  foreach t in array array[
    'institutions','profiles','classes','students','student_medical_records',
    'coach_shifts','daily_reports','report_templates','report_exports',
    'conversations','conversation_members','messages','message_reads',
    'attendance_records','absence_followups','invitations','otp_codes',
    'admin_notices','audit_logs','coach_notebooks','notifications','student_notes'
  ] loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

-- §2  Storage buckets (create manually in Dashboard → Storage if missing).
-- Expected buckets: trainer-avatars (private), trainer-media (private), trainer-medical (private).
-- Suggested policies (apply in Dashboard → Storage → Policies, or via SQL after confirming buckets exist):

-- trainer-avatars: authenticated users can read avatars within their institution;
--   users can upload/update/delete only their own avatar path.
-- (template; adjust to your actual path convention: {institution_id}/{user_id}/avatar-*)
--
-- create policy "avatars_read_institution" on storage.objects for select to authenticated
--   using (bucket_id = 'trainer-avatars' and (storage.foldername(name))[1] = public.current_institution_id()::text);
-- create policy "avatars_write_own" on storage.objects for insert to authenticated
--   with check (bucket_id = 'trainer-avatars' and (storage.foldername(name))[2] = auth.uid()::text);
-- create policy "avatars_update_own" on storage.objects for update to authenticated
--   using (bucket_id = 'trainer-avatars' and (storage.foldername(name))[2] = auth.uid()::text);
-- create policy "avatars_delete_own" on storage.objects for delete to authenticated
--   using (bucket_id = 'trainer-avatars' and (storage.foldername(name))[2] = auth.uid()::text);

-- trainer-media: read by conversation members / institution; write by sender.
-- trainer-medical: read/write by institution admins and the recording coach.

-- §3  RLS policy verification query (run in Dashboard SQL Editor, read-only):
-- select schemaname, tablename, policyname, cmd, qual, with_check
-- from pg_policies where schemaname in ('public','storage') order by schemaname, tablename, policyname;

-- §4  Auth / triggers verification (read-only):
-- select tgname, tgrelid::regclass from pg_trigger where not tgisinternal;
-- select proname from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public';

-- §5  Edge Functions: deploy from supabase/functions/ (not a SQL change):
--   supabase functions deploy invite-user verify-otp send-whatsapp send-sms
--   supabase secrets set OTP_DELIVERY_SECRET=... (plus provider credentials)

-- No policies or buckets were created by this file. All statements above that are
-- uncommented (§1) only enable RLS, which is safe and idempotent. Storage and
-- detailed policies remain commented templates — apply only after review.
