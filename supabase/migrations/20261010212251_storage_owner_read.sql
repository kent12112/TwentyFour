drop policy if exists "Photographers can read their own uploads" on storage.objects;
create policy "Photographers can read their own uploads"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'frames'
    and owner_id = auth.uid()::text
    );
