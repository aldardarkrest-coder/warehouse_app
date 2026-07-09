-- ============================================================
-- نظام إدارة المخزون والمستودعات - Supabase Schema
-- Inventory & Warehouse Management System
-- ============================================================

-- 0. قبل تشغيل هذا الملف: اذهب إلى Supabase Dashboard → Authentication → Settings
--    و عطّل "Confirm email" (إيقاف تأكيد البريد الإلكتروني).
--    بعد تشغيل الملف، أنشئ حساب مدير أول من التطبيق، ثم نفّذ:
--    UPDATE public.profiles SET is_active = true, role = 'admin' WHERE email = 'your@email.com';

-- Extensions
create extension if not exists "uuid-ossp";

-- 1. Custom Types
-- تم الاستغناء عن الـ enum types واستخدام text with check لتجنب مشكلة duplicate type

-- ============================================================
-- TABLES
-- ============================================================

-- 1.1 Profiles (extends auth.users)
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text not null,
  full_name   text not null,
  role        text not null default 'employee' check (role in ('admin', 'warehouse_manager', 'employee')),
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 1.2 Categories
create table if not exists public.categories (
  id          uuid primary key default uuid_generate_v4(),
  name        text not null,
  description text,
  parent_id   uuid references public.categories(id) on delete set null,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 1.3 Warehouses
create table if not exists public.warehouses (
  id          uuid primary key default uuid_generate_v4(),
  name        text not null,
  location    text,
  description text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 1.4 Items
create table if not exists public.items (
  id              uuid primary key default uuid_generate_v4(),
  name            text not null,
  description     text,
  sku             text unique not null,
  category_id     uuid references public.categories(id) on delete set null,
  unit            text not null default 'piece',
  min_stock_level numeric not null default 0 check (min_stock_level >= 0),
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- 1.5 Suppliers
create table if not exists public.suppliers (
  id             uuid primary key default uuid_generate_v4(),
  name           text not null,
  contact_person text,
  email          text,
  phone          text,
  address        text,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- 1.6 Customers
create table if not exists public.customers (
  id             uuid primary key default uuid_generate_v4(),
  name           text not null,
  contact_person text,
  email          text,
  phone          text,
  address        text,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- 1.7 Inventory Items (stock levels per item per warehouse)
create table if not exists public.inventory_items (
  id           uuid primary key default uuid_generate_v4(),
  item_id      uuid not null references public.items(id) on delete cascade,
  warehouse_id uuid not null references public.warehouses(id) on delete cascade,
  quantity     numeric not null default 0 check (quantity >= 0),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique(item_id, warehouse_id)
);

-- 1.8 Inventory Movements
create table if not exists public.inventory_movements (
  id             uuid primary key default uuid_generate_v4(),
  item_id        uuid not null references public.items(id) on delete restrict,
  warehouse_id   uuid not null references public.warehouses(id) on delete restrict,
  type           text not null check (type in ('in', 'out', 'transfer')),
  quantity       numeric not null check (quantity > 0),
  reference_type text,  -- 'purchase_order', 'sales_order', 'adjustment', 'transfer'
  reference_id   text,
  notes          text,
  created_by     uuid not null references auth.users(id),
  created_at     timestamptz not null default now()
);

-- 1.9 Audit Log
create table if not exists public.audit_log (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid references auth.users(id),
  action      text not null,
  table_name  text not null,
  record_id   uuid,
  old_data    jsonb,
  new_data    jsonb,
  ip_address  text,
  created_at  timestamptz not null default now()
);

-- ============================================================
-- INDEXES
-- ============================================================
create index if not exists idx_categories_parent on public.categories(parent_id);
create index if not exists idx_items_category on public.items(category_id);
create index if not exists idx_items_sku on public.items(sku);
create index if not exists idx_inventory_items_item on public.inventory_items(item_id);
create index if not exists idx_inventory_items_warehouse on public.inventory_items(warehouse_id);
create index if not exists idx_movements_item on public.inventory_movements(item_id);
create index if not exists idx_movements_warehouse on public.inventory_movements(warehouse_id);
create index if not exists idx_movements_created on public.inventory_movements(created_at desc);
create index if not exists idx_movements_created_by on public.inventory_movements(created_by);
create index if not exists idx_audit_user on public.audit_log(user_id);
create index if not exists idx_audit_table on public.audit_log(table_name);
create index if not exists idx_audit_created on public.audit_log(created_at desc);

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, role, is_active)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    'employee',
    false
  );
  return new;
end;
$$;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Update timestamp trigger
create or replace function public.update_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger update_profiles_updated_at
  before update on public.profiles
  for each row execute function public.update_updated_at();

create trigger update_categories_updated_at
  before update on public.categories
  for each row execute function public.update_updated_at();

create trigger update_warehouses_updated_at
  before update on public.warehouses
  for each row execute function public.update_updated_at();

create trigger update_items_updated_at
  before update on public.items
  for each row execute function public.update_updated_at();

create trigger update_suppliers_updated_at
  before update on public.suppliers
  for each row execute function public.update_updated_at();

create trigger update_customers_updated_at
  before update on public.customers
  for each row execute function public.update_updated_at();

create trigger update_inventory_items_updated_at
  before update on public.inventory_items
  for each row execute function public.update_updated_at();

-- Process inventory movement (atomic stock update)
create or replace function public.process_inventory_movement()
returns trigger
language plpgsql
security definer
as $$
begin
  if new.type = 'in' then
    insert into public.inventory_items (item_id, warehouse_id, quantity)
    values (new.item_id, new.warehouse_id, new.quantity)
    on conflict (item_id, warehouse_id)
    do update set quantity = public.inventory_items.quantity + new.quantity;
  elsif new.type = 'out' then
    insert into public.inventory_items (item_id, warehouse_id, quantity)
    values (new.item_id, new.warehouse_id, -new.quantity)
    on conflict (item_id, warehouse_id)
    do update set quantity = public.inventory_items.quantity - new.quantity;
  elsif new.type = 'transfer' then
    -- For transfers, quantity is negative from source
    -- The application should create TWO records: out from source, in to destination
    null;
  end if;
  return new;
end;
$$;

create trigger on_inventory_movement_insert
  after insert on public.inventory_movements
  for each row
  when (new.type in ('in', 'out'))
  execute function public.process_inventory_movement();

-- Audit log trigger
create or replace function public.log_audit_event()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.audit_log (user_id, action, table_name, record_id, old_data, new_data)
  values (
    auth.uid(),
    tg_op,
    tg_table_name,
    coalesce(new.id, old.id),
    case when tg_op in ('UPDATE', 'DELETE') then row_to_json(old)::jsonb else null end,
    case when tg_op in ('INSERT', 'UPDATE') then row_to_json(new)::jsonb else null end
  );
  return coalesce(new, old);
end;
$$;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

-- Helper: check if user is admin
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and is_active = true
  );
$$;

-- Helper: check if user is warehouse_manager or admin
create or replace function public.is_manager_or_admin()
returns boolean
language sql
stable
security definer
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('admin', 'warehouse_manager') and is_active = true
  );
$$;

-- Enable RLS on all tables
alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.warehouses enable row level security;
alter table public.items enable row level security;
alter table public.suppliers enable row level security;
alter table public.customers enable row level security;
alter table public.inventory_items enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.audit_log enable row level security;

-- حذف جميع السياسات الحالية للسماح بإعادة التشغيل
do $$
declare
  rec record;
begin
  for rec in select policyname, tablename from pg_policies where schemaname = 'public' loop
    execute format('drop policy if exists %I on public.%I', rec.policyname, rec.tablename);
  end loop;
end;
$$;

-- PROFILES
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Admins can view all profiles"
  on public.profiles for select
  using (public.is_admin());

create policy "Admins can update profiles"
  on public.profiles for update
  using (public.is_admin());

-- CATEGORIES
create policy "All authenticated users can view categories"
  on public.categories for select
  to authenticated
  using (true);

create policy "Managers and admins can insert categories"
  on public.categories for insert
  to authenticated
  with check (public.is_manager_or_admin());

create policy "Managers and admins can update categories"
  on public.categories for update
  to authenticated
  using (public.is_manager_or_admin());

create policy "Only admins can delete categories"
  on public.categories for delete
  to authenticated
  using (public.is_admin());

-- WAREHOUSES
create policy "All authenticated users can view warehouses"
  on public.warehouses for select
  to authenticated
  using (true);

create policy "Managers and admins can insert warehouses"
  on public.warehouses for insert
  to authenticated
  with check (public.is_manager_or_admin());

create policy "Managers and admins can update warehouses"
  on public.warehouses for update
  to authenticated
  using (public.is_manager_or_admin());

create policy "Only admins can delete warehouses"
  on public.warehouses for delete
  to authenticated
  using (public.is_admin());

-- ITEMS
create policy "All authenticated users can view items"
  on public.items for select
  to authenticated
  using (true);

create policy "Managers and admins can insert items"
  on public.items for insert
  to authenticated
  with check (public.is_manager_or_admin());

create policy "Managers and admins can update items"
  on public.items for update
  to authenticated
  using (public.is_manager_or_admin());

create policy "Only admins can delete items"
  on public.items for delete
  to authenticated
  using (public.is_admin());

-- SUPPLIERS
create policy "All authenticated users can view suppliers"
  on public.suppliers for select
  to authenticated
  using (true);

create policy "Managers and admins can insert suppliers"
  on public.suppliers for insert
  to authenticated
  with check (public.is_manager_or_admin());

create policy "Managers and admins can update suppliers"
  on public.suppliers for update
  to authenticated
  using (public.is_manager_or_admin());

create policy "Only admins can delete suppliers"
  on public.suppliers for delete
  to authenticated
  using (public.is_admin());

-- CUSTOMERS
create policy "All authenticated users can view customers"
  on public.customers for select
  to authenticated
  using (true);

create policy "Managers and admins can insert customers"
  on public.customers for insert
  to authenticated
  with check (public.is_manager_or_admin());

create policy "Managers and admins can update customers"
  on public.customers for update
  to authenticated
  using (public.is_manager_or_admin());

create policy "Only admins can delete customers"
  on public.customers for delete
  to authenticated
  using (public.is_admin());

-- INVENTORY ITEMS (stock levels)
create policy "All authenticated users can view inventory"
  on public.inventory_items for select
  to authenticated
  using (true);

create policy "Only system can modify inventory directly"
  on public.inventory_items for insert
  to authenticated
  with check (public.is_admin());

create policy "Only system can update inventory directly"
  on public.inventory_items for update
  to authenticated
  using (public.is_admin());

-- INVENTORY MOVEMENTS
create policy "All authenticated users can view movements"
  on public.inventory_movements for select
  to authenticated
  using (true);

create policy "Authenticated users can create movements"
  on public.inventory_movements for insert
  to authenticated
  with check (auth.uid() = created_by);

create policy "Only admins can update movements"
  on public.inventory_movements for update
  to authenticated
  using (public.is_admin());

-- AUDIT LOG (read-only for admins)
create policy "Only admins can view audit log"
  on public.audit_log for select
  to authenticated
  using (public.is_admin());

-- ============================================================
-- SEED DATA
-- ============================================================

-- Insert default admin user (run AFTER creating admin user in auth)
-- update public.profiles set role = 'admin' where email = 'admin@example.com';

-- Default categories
insert into public.categories (name, description) values
  ('مواد خام', 'المواد الأولية المستخدمة في الإنتاج'),
  ('منتجات تامة', 'المنتجات الجاهزة للبيع'),
  ('مستلزمات مكتبية', 'الأدوات واللوازم المكتبية'),
  ('قطع غيار', 'قطع الغيار والصيانة'),
  ('تغليف', 'مواد التغليف والتعبئة')
on conflict do nothing;

-- Default warehouses
insert into public.warehouses (name, location, description) values
  ('المستودع الرئيسي', 'المنطقة الصناعية', 'المستودع الرئيسي للشركة'),
  ('مستودع المواد الخام', 'المنطقة الصناعية - مبنى ب', 'تخزين المواد الأولية'),
  ('مستودع التوزيع', 'المنطقة التجارية', 'توزيع المنتجات للعملاء')
on conflict do nothing;

-- للتنصيبات الحالية: شغّل الأسطر التالية لتحديث columns من enum إلى text
-- ALTER TABLE public.profiles ALTER COLUMN role TYPE text;
-- ALTER TABLE public.inventory_movements ALTER COLUMN type TYPE text;


