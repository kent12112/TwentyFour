drop policy if exists "Allow member to upload to thier own roll's frame" on storage.objects;
create policy "Allow member to upload to thier own roll's frame"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'frames'
    and public.is_roll_member((storage.foldername(objects.name))[1]::uuid)
    and (
      select status from public.rolls
      where rolls.id = (storage.foldername(objects.name))[1]::uuid
    ) = 'shooting'
  );

drop policy if exists "Allow member to view their own roll's frame" on storage.objects;
create policy "Allow member to view their own roll's frame"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'frames'
    and public.is_roll_member((storage.foldername(objects.name))[1]::uuid)
    and (
      select status from public.rolls
      where rolls.id = (storage.foldername(objects.name))[1]::uuid
    ) = 'developed'
  );
