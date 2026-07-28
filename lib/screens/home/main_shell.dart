import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/local_storage_service.dart';
import '../../models/profile.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../categories/categories_list_screen.dart';
import '../items/items_list_screen.dart';
import '../warehouses/warehouses_list_screen.dart';
import '../suppliers/suppliers_list_screen.dart';
import '../customers/customers_list_screen.dart';
import '../inventory/movements_list_screen.dart';
import '../inventory/movement_form_screen.dart';
import '../../models/inventory_transaction.dart';
import '../reports/reports_screen.dart';
import '../users/users_management_screen.dart';
import '../branches/branches_list_screen.dart';
import '../branches/branch_form_screen.dart';
import '../units/units_list_screen.dart';
import '../units/unit_form_screen.dart';
import '../items/item_form_screen.dart';
import '../categories/category_form_screen.dart';
import '../warehouses/warehouse_form_screen.dart';
import '../suppliers/supplier_form_screen.dart';
import '../customers/customer_form_screen.dart';

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
  int _pendingSync = 0;
  bool _sidebarExpanded = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _checkSyncQueue();
  }

  void _checkSyncQueue() async {
    _pendingSync = await LocalStorageService.instance.getQueueLength();
    if (mounted) setState(() {});
    Future.delayed(const Duration(seconds: 10), _checkSyncQueue);
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
    _NavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard_rounded, label: 'لوحة التحكم', color: const Color(0xFF1A56DB)),
    _NavItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2_rounded, label: 'الأصناف', color: const Color(0xFF0EA5E9)),
    _NavItem(icon: Icons.category_outlined, selectedIcon: Icons.category_rounded, label: 'التصنيفات', color: const Color(0xFF8B5CF6)),
    _NavItem(icon: Icons.warehouse_outlined, selectedIcon: Icons.warehouse_rounded, label: 'المستودعات', color: const Color(0xFF10B981)),
    _NavItem(icon: Icons.local_shipping_outlined, selectedIcon: Icons.local_shipping_rounded, label: 'الموردين', color: const Color(0xFFF59E0B)),
    _NavItem(icon: Icons.people_outline, selectedIcon: Icons.people_rounded, label: 'العملاء', color: const Color(0xFFEC4899)),
    _NavItem(icon: Icons.swap_horiz_outlined, selectedIcon: Icons.swap_horiz_rounded, label: 'الحركات', color: const Color(0xFFEF4444)),
    _NavItem(icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart_rounded, label: 'التقارير', color: const Color(0xFF6366F1)),
    _NavItem(icon: Icons.business_outlined, selectedIcon: Icons.business_rounded, label: 'الفروع', color: const Color(0xFF3B82F6)),
    _NavItem(icon: Icons.straighten_outlined, selectedIcon: Icons.straighten_rounded, label: 'الوحدات', color: const Color(0xFF8B5CF6)),
    if (_isAdmin)
      _NavItem(icon: Icons.admin_panel_settings_outlined, selectedIcon: Icons.admin_panel_settings_rounded, label: 'المستخدمين', color: const Color(0xFF7C3AED)),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(
        child: SizedBox(
          width: 48, height: 48,
          child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1A56DB)),
        ),
      ));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;

    return Scaffold(
      key: _scaffoldKey,
      appBar: isWide ? null : AppBar(
        title: Text(_navItems[_selectedIndex].label),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          if (_pendingSync > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: const Color(0xFFF59E0B)),
                      ),
                      const SizedBox(width: 4),
                      Text('$_pendingSync', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFF59E0B))),
                    ],
                  ),
                ),
              ),
            ),
          if (_isManagerOrAdmin && _selectedIndex >= 1 && _selectedIndex <= 9 && _selectedIndex != 7)
            IconButton(
              icon: const Icon(Icons.add_circle_rounded),
              tooltip: 'إضافة ${_navItems[_selectedIndex].label}',
              onPressed: _onAddPressed,
            ),
          if (_profile != null)
            PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              icon: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                radius: 16,
                child: Text(
                  _profile!.fullName.isNotEmpty ? _profile!.fullName[0].toUpperCase() : '?',
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
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
                      Text(_profile!.fullName, style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                      Text(_profile!.role.displayName,
                          style: GoogleFonts.cairo(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 8),
                      Text('تسجيل الخروج', style: GoogleFonts.cairo(color: const Color(0xFFEF4444))),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      drawer: isWide ? null : _buildDrawer(context),
      floatingActionButton: (_isManagerOrAdmin && _selectedIndex >= 1 && _selectedIndex <= 9 && _selectedIndex != 7)
          ? FloatingActionButton.extended(
              onPressed: _onAddPressed,
              backgroundColor: _navItems[_selectedIndex].color,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text('إضافة ${_navItems[_selectedIndex].label}', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
            )
          : null,
      body: Row(
        children: [
          if (isWide) _buildSideNav(context),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                DashboardScreen(authService: widget.authService),
                ItemsListScreen(authService: widget.authService),
                CategoriesListScreen(authService: widget.authService),
                WarehousesListScreen(authService: widget.authService),
                SuppliersListScreen(authService: widget.authService),
                CustomersListScreen(authService: widget.authService),
                MovementsListScreen(authService: widget.authService),
                ReportsScreen(authService: widget.authService),
                BranchesListScreen(authService: widget.authService),
                UnitsListScreen(authService: widget.authService),
                if (_isAdmin) UsersManagementScreen(authService: widget.authService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: 280,
      child: SafeArea(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A56DB), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      _profile?.fullName.isNotEmpty == true ? _profile!.fullName[0].toUpperCase() : '?',
                      style: GoogleFonts.cairo(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _profile?.fullName ?? '',
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _profile?.role.displayName ?? '',
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Nav Items
            Expanded(
              child: ListView.builder(
                itemCount: _navItems.length,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (_, i) {
                  final item = _navItems[i];
                  final isSelected = i == _selectedIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: isSelected ? item.color.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() => _selectedIndex = i);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? item.selectedIcon : item.icon,
                                color: isSelected ? item.color : const Color(0xFF9CA3AF),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: GoogleFonts.cairo(
                                    color: isSelected ? item.color : const Color(0xFF4B5563),
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: item.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Logout
            Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: const Color(0xFFEF4444).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _logout,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
                        const SizedBox(width: 12),
                        Text('تسجيل الخروج', style: GoogleFonts.cairo(color: const Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideNav(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _sidebarExpanded ? 240 : 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: BorderDirectional(end: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: _sidebarExpanded ? 16 : 0, vertical: 16),
            child: _sidebarExpanded
                ? Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF1A56DB), Color(0xFF3B82F6)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'المخزون',
                          style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1F2937)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _sidebarExpanded = false),
                        child: const Icon(Icons.chevron_left_rounded, color: Color(0xFF9CA3AF), size: 20),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF1A56DB), Color(0xFF3B82F6)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => setState(() => _sidebarExpanded = true),
                        child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 18),
                      ),
                    ],
                  ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 8),
          // Nav Items
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              padding: EdgeInsets.symmetric(horizontal: _sidebarExpanded ? 10 : 6, vertical: 4),
              itemBuilder: (_, i) {
                final item = _navItems[i];
                final isSelected = i == _selectedIndex;
                return Tooltip(
                  message: !_sidebarExpanded ? item.label : '',
                  preferBelow: false,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: isSelected ? item.color.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _selectedIndex = i),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: _sidebarExpanded ? 12 : 0,
                            vertical: _sidebarExpanded ? 10 : 10,
                          ),
                          child: _sidebarExpanded
                              ? Row(
                                  children: [
                                    Icon(
                                      isSelected ? item.selectedIcon : item.icon,
                                      color: isSelected ? item.color : const Color(0xFF9CA3AF),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        style: GoogleFonts.cairo(
                                          color: isSelected ? item.color : const Color(0xFF6B7280),
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Icon(
                                      isSelected ? item.selectedIcon : item.icon,
                                      color: isSelected ? item.color : const Color(0xFF9CA3AF),
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // User Profile
          if (_profile != null && _sidebarExpanded)
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF1A56DB).withValues(alpha: 0.1),
                    child: Text(
                      _profile!.fullName.isNotEmpty ? _profile!.fullName[0].toUpperCase() : '?',
                      style: GoogleFonts.cairo(color: const Color(0xFF1A56DB), fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile!.fullName,
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _profile!.role.displayName,
                          style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _onAddPressed() {
    if (_selectedIndex == 0) {
      _showQuickActions();
      return;
    }
    final Widget screen = switch (_selectedIndex) {
      1 => ItemFormScreen(authService: widget.authService),
      2 => CategoryFormScreen(authService: widget.authService),
      3 => WarehouseFormScreen(authService: widget.authService),
      4 => SupplierFormScreen(authService: widget.authService),
      5 => CustomerFormScreen(authService: widget.authService),
      6 => MovementFormScreen(authService: widget.authService, initialType: TransactionType.purchaseReceipt),
      8 => BranchFormScreen(authService: widget.authService),
      9 => UnitFormScreen(authService: widget.authService),
      _ => const SizedBox.shrink(),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _showQuickActions() {
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
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('إضافة جديدة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981)),
              ),
              title: Text('إيصال استلام', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              subtitle: Text('استلام بضاعة من مورد', style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF9CA3AF))),
              onTap: () { Navigator.pop(ctx); Navigator.of(context).push(MaterialPageRoute(builder: (_) => MovementFormScreen(authService: widget.authService, initialType: TransactionType.purchaseReceipt))); },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFEF4444)),
              ),
              title: Text('صرف مبيعات', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              subtitle: Text('صرف بضاعة لعميل', style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF9CA3AF))),
              onTap: () { Navigator.pop(ctx); Navigator.of(context).push(MaterialPageRoute(builder: (_) => MovementFormScreen(authService: widget.authService, initialType: TransactionType.salesIssue))); },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF1A56DB).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF1A56DB)),
              ),
              title: Text('صنف جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              onTap: () { Navigator.pop(ctx); Navigator.of(context).push(MaterialPageRoute(builder: (_) => ItemFormScreen(authService: widget.authService))); },
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
  final Color color;

  const _NavItem({required this.icon, required this.selectedIcon, required this.label, required this.color});
}
