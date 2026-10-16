-- Frame recovery: rolls must never get stuck at 24/24 with a frame that never uploads.
--
-- A frame now moves reserved → captured → uploaded:
--   reserved  claim_frame took the number (the photo isn't taken yet)
--   captured  the photo is saved on the phone and waiting in the upload queue
--   uploaded  finalize_frame stored it
-- A frame that is still 'reserved' after 2 minutes was abandoned (camera error, crash),
-- so it's released and its number can be shot again. 'captured' frames are never
-- released: a real photo exists and the upload queue will deliver it.

---STATUS---
-- drop the old status check, whatever Postgres named it
do $$
declare
  v_name text;
begin
  for v_name in
    select conname from pg_constraint
    where conrelid = 'public.frames'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) like '%status%'
  loop
    execute format('alter table public.frames drop constraint %I', v_name);
  end loop;
end;
$$;

alter table public.frames
  add constraint frames_status_check check (status in ('reserved', 'captured', 'uploaded'));

---HELPERS---
-- frames_taken = every frame row (reserved, captured or uploaded)
create function public.recount_frames(p_roll_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.rolls
  set frames_taken = (select count(*) from public.frames where roll_id = p_roll_id)
  where id = p_roll_id;
$$;

---CLAIM---
-- Same as before, but first clears this roll's abandoned reservations, and takes the
-- lowest free frame number so released numbers get reused (no gaps).
create or replace function public.claim_frame(p_roll_id uuid)
returns public.frames
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_roll public.rolls;
  v_frame public.frames;
  v_frame_number int;
begin
  select * into v_roll
  from public.rolls
  where id = p_roll_id
  for update;

  if not found then
    raise exception 'Roll not found';
  end if;

  if not public.is_roll_member(p_roll_id) then
    raise exception 'You are not a member of this roll';
  end if;

  if v_roll.status != 'shooting' then
    raise exception 'Roll is full';
  end if;

  -- release this roll's abandoned reservations right away
  delete from public.frames
  where roll_id = p_roll_id
    and status = 'reserved'
    and taken_at < now() - interval '2 minutes';

  -- lowest number in 1..frame_count that nobody holds
  select min(n) into v_frame_number
  from generate_series(1, v_roll.frame_count) as n
  where not exists (
    select 1 from public.frames f
    where f.roll_id = p_roll_id and f.frame_number = n
  );

  if v_frame_number is null then
    perform public.recount_frames(p_roll_id);
    raise exception 'Roll is full';
  end if;

  insert into public.frames (roll_id, frame_number, photographer_id)
  values (p_roll_id, v_frame_number, auth.uid())
  returning * into v_frame;

  perform public.recount_frames(p_roll_id);
  return v_frame;
end;
$$;

---CAPTURED---
-- The app calls this right after the photo is saved in the upload queue.
create function public.mark_captured(p_frame_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.frames
  set status = 'captured'
  where id = p_frame_id
    and photographer_id = auth.uid()
    and status = 'reserved';
$$;

---RELEASE---
-- The app calls this when taking the photo failed, so the number is freed at once.
create function public.release_frame(p_frame_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_roll_id uuid;
begin
  delete from public.frames
  where id = p_frame_id
    and photographer_id = auth.uid()
    and status = 'reserved'
  returning roll_id into v_roll_id;

  if v_roll_id is not null then
    perform public.recount_frames(v_roll_id);
  end if;
end;
$$;

-- Runs every minute (pg_cron): releases abandoned reservations on all shooting rolls.
-- Needed because a stuck 24/24 roll gets no new claim_frame calls that could clean it.
create function public.release_stale_frames()
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_roll_id uuid;
  v_count int := 0;
begin
  for v_roll_id in
    delete from public.frames f
    using public.rolls r
    where f.roll_id = r.id
      and r.status = 'shooting'
      and f.status = 'reserved'
      and f.taken_at < now() - interval '2 minutes'
    returning f.roll_id
  loop
    v_count := v_count + 1;
    perform public.recount_frames(v_roll_id);
  end loop;
  return v_count;
end;
$$;

---FINALIZE---
-- Same as before, but a frame can be finalized from 'reserved' or 'captured'.
create or replace function public.finalize_frame(p_frame_id uuid, p_storage_path text)
returns public.rolls
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_frame public.frames;
  v_roll public.rolls;
  v_uploaded int;
begin
  select * into v_frame
  from public.frames
  where id = p_frame_id
  for update;

  if not found then
    raise exception 'Frame not found';
  end if;

  if not v_frame.photographer_id = auth.uid() then
    raise exception 'You are not the photographer for this frame';
  end if;

  if v_frame.status not in ('reserved', 'captured') then
    raise exception 'Frame is not reserved';
  end if;

  select * into v_roll
  from public.rolls
  where id = v_frame.roll_id
  for update;

  update public.frames
  set status = 'uploaded', storage_path = p_storage_path
  where id = p_frame_id;

  select count(*) into v_uploaded
  from public.frames
  where roll_id = v_roll.id and status = 'uploaded';

  if v_uploaded = v_roll.frame_count then
    update public.rolls
    set status = 'developed', developed_at = now()
    where id = v_roll.id
    returning * into v_roll;
  end if;
  return v_roll;
end;
$$;

---SCHEDULE---
create extension if not exists pg_cron with schema pg_catalog;

select cron.schedule(
  'release-stale-frames',
  '* * * * *',
  $$select public.release_stale_frames()$$
);

---PERMISSIONS---
revoke execute on function public.recount_frames(uuid) from public, anon, authenticated;
revoke execute on function public.release_stale_frames() from public, anon, authenticated;

revoke execute on function public.claim_frame(uuid) from public, anon;
grant execute on function public.claim_frame(uuid) to authenticated;

revoke execute on function public.finalize_frame(uuid, text) from public, anon;
grant execute on function public.finalize_frame(uuid, text) to authenticated;

revoke execute on function public.mark_captured(uuid) from public, anon;
grant execute on function public.mark_captured(uuid) to authenticated;

revoke execute on function public.release_frame(uuid) from public, anon;
grant execute on function public.release_frame(uuid) to authenticated;
