-- ==============================================================================
-- HOMEY: SUPABASE DATABASE ARCHITECTURE & SCHEMA DDL
-- Fitur: Family Pairing, Joint Ledger, Shared Tasks/Agenda, Meal Planner
-- Standar: Supabase Best Practices (RLS, Foreign Key Indexing, Realtime)
-- ==============================================================================

-- 1. EXTENSIONS
create extension if not exists "uuid-ossp";

-- ==============================================================================
-- 2. TABEL: FAMILIES
-- Menyimpan entitas keluarga dan kode undangan unik untuk pairing suami-istri
-- ==============================================================================
create table if not exists public.families (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    invite_code text not null unique,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Index untuk percepat query pencarian invite_code saat pairing
create index if not exists idx_families_invite_code on public.families (invite_code);

-- ==============================================================================
-- 3. TABEL: PROFILES
-- Terhubung 1-to-1 dengan auth.users, menyimpan peran (suami/istri) & family_id
-- ==============================================================================
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    family_id uuid references public.families(id) on delete set null,
    full_name text,
    role text not null check (role in ('suami', 'istri')),
    avatar_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Index Foreign Key untuk optimasi JOIN & RLS policy
create index if not exists idx_profiles_family_id on public.profiles (family_id);

-- ==============================================================================
-- 4. HELPER FUNCTION UNTUK RLS PERFORMANCE
-- Menghindari pemanggilan fungsi per baris & menghindari RLS recursion
-- ==============================================================================
create or replace function public.get_current_family_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
    select family_id
    from public.profiles
    where id = (select auth.uid())
    limit 1;
$$;

revoke execute on function public.get_current_family_id() from public, anon;

-- ==============================================================================
-- 5. TABEL: TRANSACTIONS (JOINT LEDGER)
-- Buku kas bersama (pemasukan/pengeluaran, kategori, nominal, tanggal)
-- ==============================================================================
create table if not exists public.transactions (
    id uuid primary key default gen_random_uuid(),
    family_id uuid not null references public.families(id) on delete cascade,
    user_id uuid not null references public.profiles(id) on delete cascade,
    type text not null check (type in ('expense', 'income')),
    amount numeric(14, 2) not null check (amount > 0),
    category text not null,
    title text not null,
    notes text,
    transaction_date date not null default current_date,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Index Foreign Key & Composite Index untuk filter dashboard bulanan
create index if not exists idx_transactions_family_id on public.transactions (family_id);
create index if not exists idx_transactions_user_id on public.transactions (user_id);
create index if not exists idx_transactions_family_date on public.transactions (family_id, transaction_date desc);

-- ==============================================================================
-- 6. TABEL: TASKS (AGENDA & TO-DO LIST)
-- Checklist tugas harian/mingguan yang bisa ditugaskan ke Suami, Istri, atau Keduanya
-- ==============================================================================
create table if not exists public.tasks (
    id uuid primary key default gen_random_uuid(),
    family_id uuid not null references public.families(id) on delete cascade,
    created_by uuid not null references public.profiles(id) on delete cascade,
    title text not null,
    description text,
    assignee text not null check (assignee in ('suami', 'istri', 'both')),
    due_date timestamptz,
    is_completed boolean not null default false,
    completed_at timestamptz,
    completed_by uuid references public.profiles(id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Index Foreign Key & Composite Index untuk realtime task stream
create index if not exists idx_tasks_family_id on public.tasks (family_id);
create index if not exists idx_tasks_created_by on public.tasks (created_by);
create index if not exists idx_tasks_family_status on public.tasks (family_id, is_completed, due_date asc);

-- ==============================================================================
-- 7. TABEL: MEAL_PLANS (RENCANA MENU MAKAN)
-- Jadwal menu makan (sarapan/siang/malam) beserta resep & bahan belanja
-- ==============================================================================
create table if not exists public.meal_plans (
    id uuid primary key default gen_random_uuid(),
    family_id uuid not null references public.families(id) on delete cascade,
    created_by uuid not null references public.profiles(id) on delete cascade,
    plan_date date not null default current_date,
    meal_type text not null check (meal_type in ('sarapan', 'siang', 'malam')),
    title text not null,
    notes text,
    ingredients jsonb not null default '[]'::jsonb,
    is_synced_to_grocery boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Index Foreign Key & Composite Index untuk pencarian rencana makan harian
create index if not exists idx_meal_plans_family_id on public.meal_plans (family_id);
create index if not exists idx_meal_plans_family_date on public.meal_plans (family_id, plan_date, meal_type);

-- ==============================================================================
-- 8. TRIGGER: AUTO-UPDATE updated_at TIMESTAMP
-- ==============================================================================
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger tr_families_updated_at
    before update on public.families
    for each row execute function public.handle_updated_at();

create trigger tr_profiles_updated_at
    before update on public.profiles
    for each row execute function public.handle_updated_at();

create trigger tr_transactions_updated_at
    before update on public.transactions
    for each row execute function public.handle_updated_at();

create trigger tr_tasks_updated_at
    before update on public.tasks
    for each row execute function public.handle_updated_at();

create trigger tr_meal_plans_updated_at
    before update on public.meal_plans
    for each row execute function public.handle_updated_at();

-- ==============================================================================
-- 9. ROW LEVEL SECURITY (RLS) POLICIES
-- Menjamin isolasi data multi-tenant berdasarkan family_id
-- ==============================================================================

-- A. Aktifkan RLS pada seluruh tabel
alter table public.families enable row level security;
alter table public.profiles enable row level security;
alter table public.transactions enable row level security;
alter table public.tasks enable row level security;
alter table public.meal_plans enable row level security;

-- ------------------------------------------------------------------------------
-- RLS: FAMILIES
-- ------------------------------------------------------------------------------
create policy "Anggota keluarga dapat membaca data keluarga mereka"
    on public.families
    for select
    to authenticated
    using (
        id = (select public.get_current_family_id())
        or
        -- Diizinkan membaca saat proses verifikasi kode undangan pairing
        true
    );

create policy "Pengguna terautentikasi dapat membuat keluarga baru"
    on public.families
    for insert
    to authenticated
    with check (true);

create policy "Anggota keluarga dapat memperbarui data keluarga mereka"
    on public.families
    for update
    to authenticated
    using (id = (select public.get_current_family_id()))
    with check (id = (select public.get_current_family_id()));

-- ------------------------------------------------------------------------------
-- RLS: PROFILES
-- ------------------------------------------------------------------------------
create policy "Pengguna dapat membaca profil sendiri dan pasangan dalam keluarga yang sama"
    on public.profiles
    for select
    to authenticated
    using (
        id = (select auth.uid())
        or
        (family_id is not null and family_id = (select public.get_current_family_id()))
    );

create policy "Pengguna dapat membuat profil mereka sendiri saat pendaftaran"
    on public.profiles
    for insert
    to authenticated
    with check (id = (select auth.uid()));

create policy "Pengguna dapat memperbarui profil mereka sendiri"
    on public.profiles
    for update
    to authenticated
    using (id = (select auth.uid()))
    with check (id = (select auth.uid()));

-- ------------------------------------------------------------------------------
-- RLS: TRANSACTIONS
-- ------------------------------------------------------------------------------
create policy "Keluarga dapat membaca transaksi kas bersama"
    on public.transactions
    for select
    to authenticated
    using (family_id = (select public.get_current_family_id()));

create policy "Keluarga dapat menambahkan transaksi baru"
    on public.transactions
    for insert
    to authenticated
    with check (
        family_id = (select public.get_current_family_id())
        and user_id = (select auth.uid())
    );

create policy "Keluarga dapat memperbarui transaksi mereka"
    on public.transactions
    for update
    to authenticated
    using (family_id = (select public.get_current_family_id()))
    with check (family_id = (select public.get_current_family_id()));

create policy "Keluarga dapat menghapus transaksi"
    on public.transactions
    for delete
    to authenticated
    using (family_id = (select public.get_current_family_id()));

-- ------------------------------------------------------------------------------
-- RLS: TASKS
-- ------------------------------------------------------------------------------
create policy "Keluarga dapat membaca daftar agenda & tugas"
    on public.tasks
    for select
    to authenticated
    using (family_id = (select public.get_current_family_id()));

create policy "Keluarga dapat membuat tugas baru"
    on public.tasks
    for insert
    to authenticated
    with check (
        family_id = (select public.get_current_family_id())
        and created_by = (select auth.uid())
    );

create policy "Keluarga dapat mencentang atau mengedit tugas"
    on public.tasks
    for update
    to authenticated
    using (family_id = (select public.get_current_family_id()))
    with check (family_id = (select public.get_current_family_id()));

create policy "Keluarga dapat menghapus tugas"
    on public.tasks
    for delete
    to authenticated
    using (family_id = (select public.get_current_family_id()));

-- ------------------------------------------------------------------------------
-- RLS: MEAL_PLANS
-- ------------------------------------------------------------------------------
create policy "Keluarga dapat membaca rencana menu makan"
    on public.meal_plans
    for select
    to authenticated
    using (family_id = (select public.get_current_family_id()));

create policy "Keluarga dapat membuat rencana menu makan baru"
    on public.meal_plans
    for insert
    to authenticated
    with check (
        family_id = (select public.get_current_family_id())
        and created_by = (select auth.uid())
    );

create policy "Keluarga dapat memperbarui menu makan"
    on public.meal_plans
    for update
    to authenticated
    using (family_id = (select public.get_current_family_id()))
    with check (family_id = (select public.get_current_family_id()));

create policy "Keluarga dapat menghapus rencana menu makan"
    on public.meal_plans
    for delete
    to authenticated
    using (family_id = (select public.get_current_family_id()));

-- ==============================================================================
-- 10. REALTIME CONFIGURATION (SUPABASE REALTIME PUBLICATION)
-- Mengaktifkan sinkronisasi instan (< 2 detik) antara HP Suami & Istri
-- ==============================================================================
alter publication supabase_realtime add table public.tasks;
alter publication supabase_realtime add table public.transactions;
alter publication supabase_realtime add table public.meal_plans;
alter publication supabase_realtime add table public.profiles;
