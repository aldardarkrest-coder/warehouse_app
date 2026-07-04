import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/inventory_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../models/inventory_movement.dart';

class DashboardScreen extends StatefulWidget {
  final AuthService authService;

  const DashboardScreen({super.key, required this.authService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _inventoryService = InventoryService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final stats = await _inventoryService.getDashboardStats();
      if (mounted) setState(() { _stats = stats; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingWidget(message: 'جاري تحميل البيانات...');
    if (_error != null) return AppErrorWidget(message: _error!, onRetry: _loadStats);
    if (_stats == null) return const AppErrorWidget(message: 'لا توجد بيانات');

    final lowStockCount = _stats!['low_stock_count'] as int;
    final totalItems = _stats!['total_items'] as int;
    final totalWarehouses = _stats!['total_warehouses'] as int;
    final recentMovements = _stats!['recent_movements'] as List<InventoryMovement>;

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('نظرة عامة', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatCard(
                icon: Icons.inventory, label: 'إجمالي الأصناف',
                value: '$totalItems', color: Colors.blue,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                icon: Icons.warehouse, label: 'المستودعات',
                value: '$totalWarehouses', color: Colors.green,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                icon: Icons.warning_amber, label: 'مخزون منخفض',
                value: '$lowStockCount',
                color: lowStockCount > 0 ? Colors.red : Colors.grey,
              )),
            ],
          ),
          const SizedBox(height: 24),
          Text('آخر الحركات', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (recentMovements.isEmpty)
            const Card(child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('لا توجد حركات بعد')),
            ))
          else
            ...recentMovements.map((m) => Card(
              child: ListTile(
                leading: Icon(
                  m.type == MovementType.in_
                      ? Icons.add_circle
                      : m.type == MovementType.out
                          ? Icons.remove_circle
                          : Icons.swap_horiz,
                  color: m.type == MovementType.in_
                      ? Colors.green
                      : m.type == MovementType.out
                          ? Colors.red
                          : Colors.orange,
                ),
                title: Text(m.itemName ?? 'غير معروف'),
                subtitle: Text('${m.type.displayName} - ${m.quantity}'),
                trailing: Text(m.createdAt != null
                    ? '${m.createdAt!.day}/${m.createdAt!.month}/${m.createdAt!.year}'
                    : ''),
              ),
            )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon, required this.label,
    required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold, color: color,
            )),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
