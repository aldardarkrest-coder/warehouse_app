# نظام إدارة المخزون والمستودعات (Inventory Management System)

## Requirements (EARS Format)

While a user is authenticated, when they access the dashboard, the system shall display current stock levels, low-stock alerts, and recent movements.

While a user has admin role, when they manage users, the system shall allow creating/editing/deactivating users with specific roles.

While a user is authenticated, when they perform CRUD on categories/items/warehouses/suppliers/customers, the system shall validate input, enforce authorization, and persist changes via Supabase.

While a user is authenticated, when they record an inventory movement (in/out/transfer), the system shall update stock quantities atomically and log the transaction.

While a user is authenticated, when they view any resource, the system shall filter data based on their authorization scope.

## Architecture

### Frontend (Flutter)
- **State Management**: ChangeNotifier + Provider pattern
- **Routing**: Named routes with GoRouter
- **HTTP Client**: Supabase Flutter SDK (built-in RLS enforcement)
- **UI**: Material 3 with Arabic RTL support
- **Validation**: Client-side form validation + Supabase RLS

### Backend (Supabase)
- **Database**: PostgreSQL with Row Level Security
- **Auth**: Supabase Auth (email/password)
- **Realtime**: Supabase Realtime for live stock updates
- **Storage**: Supabase Storage (for item images - optional)

### Security
- **Auth**: Supabase Auth with JWT tokens
- **Authz**: Row Level Security policies on all tables
- **Input Validation**: Server-side CHECK constraints + client-side validation
- **Audit**: `audit_log` table for all security-relevant events

## Database Schema

### Tables
1. `profiles` - Extended user info (id, email, full_name, role, created_at)
2. `categories` - Hierarchical item categories (id, name, description, parent_id, is_active)
3. `warehouses` - Physical/virtual warehouses (id, name, location, description, is_active)
4. `items` - Products/stock items (id, name, description, sku, category_id, unit, min_stock_level, is_active)
5. `suppliers` - Vendors (id, name, contact_person, email, phone, address, is_active)
6. `customers` - Buyers (id, name, contact_person, email, phone, address, is_active)
7. `inventory_items` - Stock levels per item per warehouse (id, item_id, warehouse_id, quantity)
8. `inventory_movements` - All stock transactions (id, item_id, warehouse_id, type, quantity, reference_type, reference_id, notes, created_by, created_at)

### RLS Policies
- Admins: Full access to all tables
- Warehouse Managers: CRUD on movements, read on items/warehouses
- Employees: Read-only on inventory, create movements

## Implementation Plan

- [x] Step 1: Technical design document
- [ ] Step 2: SQL schema + RLS policies
- [ ] Step 3: Flutter project setup (pubspec, config)
- [ ] Step 4: Data models
- [ ] Step 5: Services layer
- [ ] Step 6: Auth screens (login/register)
- [ ] Step 7: Dashboard screen
- [ ] Step 8: Category CRUD screens
- [ ] Step 9: Warehouse CRUD screens
- [ ] Step 10: Item CRUD screens
- [ ] Step 11: Supplier CRUD screens
- [ ] Step 12: Customer CRUD screens
- [ ] Step 13: Inventory movement screens
- [ ] Step 14: User management (admin)
- [ ] Step 15: Security audit
