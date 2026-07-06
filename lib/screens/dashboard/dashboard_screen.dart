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
      color: const Color(0xFF2D3142),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats Grid
          Row(
            children: [
              Expanded(child: _StatCard(
                icon: Icons.inventory_2_rounded, label: 'إجمالي الأصناف',
                value: '$totalItems', color: const Color(0xFF4299E1), bg: const Color(0xFF4299E1),
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                icon: Icons.warehouse_rounded, label: 'المستودعات',
                value: '$totalWarehouses', color: const Color(0xFF48BB78), bg: const Color(0xFF48BB78),
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                icon: Icons.warning_amber_rounded, label: 'مخزون منخفض',
                value: '$lowStockCount',
                color: lowStockCount > 0 ? const Color(0xFFE53E3E) : const Color(0xFFA0AEC0),
                bg: lowStockCount > 0 ? const Color(0xFFE53E3E) : const Color(0xFFA0AEC0),
              )),
            ],
          ),
          const SizedBox(height: 24),
          // Recent Movements
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'آخر الحركات',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D3142),
                ),
              ),
              if (recentMovements.isNotEmpty)
                TextButton(
                  onPressed: () {},
                  child: const Text('عرض الكل'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (recentMovements.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECF1)),
              ),
              child: Column(
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('لا توجد حركات بعد', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                ],
              ),
            )
          else
            ...recentMovements.map((m) => _MovementCard(movement: m)),
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
  final Color bg;

  const _StatCard({
    required this.icon, required this.label,
    required this.value, required this.color, required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: bg),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800, color: color,
          )),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500,
          ), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _MovementCard extends StatelessWidget {
  final InventoryMovement movement;

  const _MovementCard({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isIn = movement.type == MovementType.in_;
    final isOut = movement.type == MovementType.out;
    final color = isIn ? const Color(0xFF48BB78) : isOut ? const Color(0xFFE53E3E) : const Color(0xFFED8936);
    final icon = isIn ? Icons.add_rounded : isOut ? Icons.remove_rounded : Icons.swap_horiz_rounded;
    final label = isIn ? 'إدخال' : isOut ? 'إخراج' : 'تحويل';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.itemName ?? 'غير معروف',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '$label · ${movement.warehouseName ?? ""}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${movement.quantity}',
                style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16, color: color,
                ),
              ),
              if (movement.createdAt != null)
                Text(
                  '${movement.createdAt!.day}/${movement.createdAt!.month}/${movement.createdAt!.year}',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
