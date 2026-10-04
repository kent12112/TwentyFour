---TABLES----

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  color text not null default '#E5484D',
  created_at timestamptz not null default now()
);

create table public.rolls (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  event_type text,
  starts_at timestamptz,
  location text,
  created_by uuid references public.profiles(id) on delete set null,
  invite_code text not null unique default substr(md5(random()::text), 1, 8),
  frame_count int not null default 24,
  frames_taken int not null default 0,
  status text not null default 'shooting' check (status in ('shooting', 'developed')),
  developed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.roll_members (
  roll_id uuid not null references public.rolls(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (roll_id, user_id)
);

create table public.frames (
  id uuid primary key default gen_random_uuid(),
  roll_id uuid not null references public.rolls(id) on delete cascade,
  frame_number int not null check (frame_number >= 1 and frame_number <= 24),
  photographer_id uuid references public.profiles(id) on delete set null,
  taken_at timestamptz not null default now(),
  storage_path text,
  status text not null default 'reserved' check (status in ('reserved', 'uploaded')),
  unique (roll_id, frame_number)
);

create table public.push_tokens (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  token text not null,
  updated_at timestamptz not null default now()
);

---RLS---
alter table public.profiles enable row level security;
alter table public.rolls enable row level security;
alter table public.roll_members enable row level security;
alter table public.frames enable row level security;
alter table public.push_tokens enable row level security;

---HELPER FUNCTIONS---
create function public.is_roll_member(p_roll_id uuid)
returns boolean
language sql
security definer
set search_path = ''
stable
as $$
  select exists (
    select 1
    from public.roll_members
    where roll_id = p_roll_id and user_id = auth.uid()
  );
$$;


---POLICIES---

--Profiles
create policy "User can create their own profiile"

  on public.profiles
  for insert
  to authenticated
  with check (auth.uid() = id);

create policy "User can update their own profile"
  on public.profiles
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "user can select their own profile"
  on public.profiles
  for select
  to authenticated
  using (auth.uid() = id);

--Rolls
create policy "Members can read their rolls"
  on public.rolls
  for select
  to authenticated
  using (public.is_roll_member(id));

--Roll Members
create policy "Members can see fellow members of thier rolls"
  on public.roll_members
  for select
  to authenticated
  using (public.is_roll_member(roll_id));

create policy "Member can see profiles of people they share a roll with"
  on public.profiles
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.roll_members
      where roll_members.user_id = profiles.id
      and public.is_roll_member(roll_members.roll_id)
    )
  );

---Frames
create policy "User can insert push otkens for their own profile"
on public.push_tokens
for insert
to authenticated
with check (auth.uid() = user_id);

---Push Tokens
create policy "User can update push tokens for thier own profile"
on public.push_tokens
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "User can select push tokens for their own profile"
on public.push_tokens
for select
to authenticated
using (auth.uid() = user_id);

create policy "Member can read frames for rolls they are a member of"
on public.frames
for select
to authenticated
using (public.is_roll_member(roll_id)
and ((select status from public.rolls
where rolls.id = frames.roll_id) = 'developed')
);

---Function---

create function public.create_roll(p_name text, p_event_type text default null, p_starts_at timestamptz default null, p_location text default null)
returns public.rolls
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_roll public.rolls;
begin
  insert into public.rolls (name, event_type, starts_at, location, created_by) values (p_name, p_event_type, p_starts_at, p_location, auth.uid())
  returning * into v_roll;
  insert into public.roll_members (roll_id, user_id) values (v_roll.id, auth.uid());
  return v_roll;
end;
$$;

create function public.join_roll(p_roll_id uuid, p_invite_code text)
returns public.rolls
language plpgsql
security definer
set search_path = ''
as $$
declare 
  v_roll public.rolls;
begin
  select * into v_roll
  from public.rolls
  where id = p_roll_id and invite_code = p_invite_code;

  if not found then
    raise exception 'Invalid roll ID or invite code';
  end if;

  insert into public.roll_members (roll_id, user_id) values (v_roll.id, auth.uid()) on conflict do nothing;

  return v_roll;
end;
$$;

create function public.claim_frame(p_roll_id uuid)
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
  -- lock and load the roll (others wait here)
  select * into v_roll
  from public.rolls
  where id = p_roll_id
  for update;

  --no such roll->stop
  if not found then
    raise exception 'Roll not found';
  end if;

  --only members can shoot
  if not public.is_roll_member(p_roll_id) then
    raise exception 'You are not a member of this roll';
  end if;

  --Roll must still be shooting and have frames left
  if v_roll.status != 'shooting' or v_roll.frames_taken >= v_roll.frame_count then
    raise exception 'Roll is full';
  end if;

  --take the next number and update the counter
  v_frame_number := v_roll.frames_taken + 1;
  update public.rolls
  set frames_taken = v_frame_number
  where id = p_roll_id;

  --reserve the frame
  insert into public.frames (roll_id, frame_number, photographer_id)
  values (p_roll_id, v_frame_number, auth.uid())
  returning * into v_frame;

  return v_frame;
end;
$$;

create function public.finalize_frame(p_frame_id uuid, p_storage_path text)
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

  if not v_frame.status = 'reserved' then
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

---STORAGE---
insert into storage.buckets (id, name, public)
values ('frames', 'frames', false)
on conflict (id) do nothing;

drop policy if exists "Allow member to upload to thier own roll's frame" on storage.objects;
create policy "Allow member to upload to thier own roll's frame"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'frames' 
  and public.is_roll_member((storage.foldername(name))[1]::uuid)
  and (
    select status from public.rolls
    where rolls.id = (storage.foldername(name))[1]::uuid
  ) = 'shooting'
);

drop policy if exists "Allow member to view their own roll's frame" on storage.objects;
create policy "Allow member to view their own roll's frame"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'frames'
  and public.is_roll_member((storage.foldername(name))[1]::uuid)
  and (
    select status from public.rolls
    where rolls.id = (storage.foldername(name))[1]::uuid
  ) = 'developed'
);

---REALTIME---
alter publication supabase_realtime add table public.rolls;

---PERMISSIONS---
revoke execute on function public.is_roll_member(uuid) from public, anon;
grant execute on function public.is_roll_member(uuid) to authenticated;

revoke execute on function public.create_roll(text, text, timestamptz, text) from public, anon;
grant execute on function public.create_roll(text, text, timestamptz, text) to authenticated;

revoke execute on function public.join_roll(uuid, text) from public, anon;
grant execute on function public.join_roll(uuid, text) to authenticated;

revoke execute on function public.claim_frame(uuid) from public, anon;
grant execute on function public.claim_frame(uuid) to authenticated;

revoke execute on function public.finalize_frame(uuid, text) from public, anon;
grant execute on function public.finalize_frame(uuid, text) to authenticated;

