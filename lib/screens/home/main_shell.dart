import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/profile.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../categories/categories_list_screen.dart';
import '../items/items_list_screen.dart';
import '../items/item_form_screen.dart';
import '../warehouses/warehouses_list_screen.dart';
import '../suppliers/suppliers_list_screen.dart';
import '../customers/customers_list_screen.dart';
import '../inventory/movements_list_screen.dart';
import '../inventory/movement_form_screen.dart';
import '../users/users_management_screen.dart';

class MainShell extends StatefulWidget {
  final AuthService authService;

  const MainShell({super.key, required this.authService});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  Profile? _profile;
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await widget.authService.getProfile();
      if (mounted) setState(() { _profile = profile; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await widget.authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen(authService: widget.authService)),
        (_) => false,
      );
    }
  }

  bool get _isAdmin => _profile?.role.value == 'admin';
  bool get _isManagerOrAdmin =>
      _profile?.role.value == 'admin' || _profile?.role.value == 'warehouse_manager';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screens = [
      DashboardScreen(authService: widget.authService),
      ItemsListScreen(authService: widget.authService),
      CategoriesListScreen(authService: widget.authService),
      WarehousesListScreen(authService: widget.authService),
      SuppliersListScreen(authService: widget.authService),
      CustomersListScreen(authService: widget.authService),
      MovementsListScreen(authService: widget.authService),
      if (_isAdmin) UsersManagementScreen(authService: widget.authService),
    ];

    final screenTitles = [
      'لوحة التحكم',
      'الأصناف',
      'التصنيفات',
      'المستودعات',
      'الموردين',
      'العملاء',
      'حركات المخزون',
      if (_isAdmin) 'إدارة المستخدمين',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitles[_selectedIndex]),
        actions: [
          if (_profile != null)
            PopupMenuButton<String>(
              icon: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  _profile!.fullName.isNotEmpty
                      ? _profile!.fullName[0].toUpperCase()
                      : '?',
                ),
              ),
              onSelected: (v) {
                if (v == 'logout') _logout();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_profile!.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(_profile!.role.displayName,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج')),
              ],
            ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'الرئيسية'),
          const NavigationDestination(icon: Icon(Icons.inventory_outlined), selectedIcon: Icon(Icons.inventory), label: 'الأصناف'),
          const NavigationDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: 'التصنيفات'),
          const NavigationDestination(icon: Icon(Icons.warehouse_outlined), selectedIcon: Icon(Icons.warehouse), label: 'المستودعات'),
          const NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'الموردين'),
          const NavigationDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people), label: 'العملاء'),
          const NavigationDestination(icon: Icon(Icons.swap_horiz_outlined), selectedIcon: Icon(Icons.swap_horiz), label: 'الحركات'),
          if (_isAdmin)
            const NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings), label: 'المستخدمين'),
        ],
      ),
      floatingActionButton: _isManagerOrAdmin ? FloatingActionButton(
        onPressed: () => _showQuickActions(context),
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('حركة إدخال جديدة'),
              subtitle: const Text('إضافة كمية للمخزون'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MovementFormScreen(
                      authService: widget.authService,
                      initialType: 'in',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('حركة إخراج جديدة'),
              subtitle: const Text('صرف كمية من المخزون'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MovementFormScreen(
                      authService: widget.authService,
                      initialType: 'out',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_outlined),
              title: const Text('صنف جديد'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ItemFormScreen(authService: widget.authService),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
