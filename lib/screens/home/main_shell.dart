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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  List<_NavItem> get _navItems => [
    const _NavItem(icon: Icons.dashboard_rounded, selectedIcon: Icons.dashboard, label: 'لوحة التحكم'),
    const _NavItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2, label: 'الأصناف'),
    const _NavItem(icon: Icons.category_outlined, selectedIcon: Icons.category, label: 'التصنيفات'),
    const _NavItem(icon: Icons.warehouse_outlined, selectedIcon: Icons.warehouse, label: 'المستودعات'),
    const _NavItem(icon: Icons.local_shipping_outlined, selectedIcon: Icons.local_shipping, label: 'الموردين'),
    const _NavItem(icon: Icons.people_outline, selectedIcon: Icons.people, label: 'العملاء'),
    const _NavItem(icon: Icons.swap_horiz_rounded, selectedIcon: Icons.swap_horiz, label: 'الحركات'),
    if (_isAdmin)
      const _NavItem(icon: Icons.admin_panel_settings_outlined, selectedIcon: Icons.admin_panel_settings, label: 'المستخدمين'),
  ];

  List<Widget> get _screens => [
    DashboardScreen(authService: widget.authService),
    ItemsListScreen(authService: widget.authService),
    CategoriesListScreen(authService: widget.authService),
    WarehousesListScreen(authService: widget.authService),
    SuppliersListScreen(authService: widget.authService),
    CustomersListScreen(authService: widget.authService),
    MovementsListScreen(authService: widget.authService),
    if (_isAdmin) UsersManagementScreen(authService: widget.authService),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_navItems[_selectedIndex].label),
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        actions: [
          if (_isManagerOrAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'إضافة جديدة',
              onPressed: () => _showQuickActions(context),
            ),
          if (_profile != null)
            PopupMenuButton<String>(
              icon: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                radius: 16,
                child: Text(
                  _profile!.fullName.isNotEmpty ? _profile!.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
      drawer: isWide ? null : _buildDrawer(context),
      body: Row(
        children: [
          if (isWide) _buildSideNav(context),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFF2D3142)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      _profile?.fullName.isNotEmpty == true ? _profile!.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _profile?.fullName ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _profile?.role.displayName ?? '',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _navItems.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (_, i) {
                  final item = _navItems[i];
                  final isSelected = i == _selectedIndex;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2D3142).withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        color: isSelected ? const Color(0xFF2D3142) : const Color(0xFF9098B1),
                        size: 22,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF2D3142) : const Color(0xFF4A5568),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: () {
                        setState(() => _selectedIndex = i);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Color(0xFFE53E3E)),
                title: const Text('تسجيل الخروج', style: TextStyle(color: Color(0xFFE53E3E))),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideNav(BuildContext context) {
    return Container(
      width: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: BorderDirectional(end: BorderSide(color: Color(0xFFE8ECF1))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2D3142),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              labelType: NavigationRailLabelType.all,
              leading: const SizedBox(height: 8),
              destinations: _navItems.map((item) => NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: Text(item.label),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('إضافة جديدة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF48BB78).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF48BB78)),
              ),
              title: const Text('حركة إدخال'),
              subtitle: const Text('إضافة كمية للمخزون'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MovementFormScreen(authService: widget.authService, initialType: 'in'),
                ));
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFE53E3E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFE53E3E)),
              ),
              title: const Text('حركة إخراج'),
              subtitle: const Text('صرف كمية من المخزون'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MovementFormScreen(authService: widget.authService, initialType: 'out'),
                ));
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF2D3142).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2D3142)),
              ),
              title: const Text('صنف جديد'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ItemFormScreen(authService: widget.authService),
                ));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({required this.icon, required this.selectedIcon, required this.label});
}
