import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/inventory_service.dart';
import '../../services/report_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class ReportsScreen extends StatefulWidget {
  final AuthService authService;

  const ReportsScreen({super.key, required this.authService});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _inventoryService = InventoryService();
  final _reportService = ReportService();
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _movementSummary;
  Map<String, dynamic>? _stockByWarehouse;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _inventoryService.getDashboardStats(),
        _reportService.getMovementSummary(),
        _reportService.getStockByWarehouse(),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0];
          _movementSummary = results[1];
          _stockByWarehouse = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingWidget(message: 'جاري تحميل التقارير...');
    if (_error != null) return AppErrorWidget(message: _error!, onRetry: _load);

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF2D3142),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('نظرة عامة', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2D3142),
          )),
          const SizedBox(height: 12),
          _buildStatsRow(),
          const SizedBox(height: 24),
          const Text('ملخص الحركات', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2D3142),
          )),
          const SizedBox(height: 12),
          _buildMovementSummary(),
          const SizedBox(height: 24),
          const Text('المخزون حسب المستودع', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2D3142),
          )),
          const SizedBox(height: 12),
          _buildWarehouseStock(),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalItems = _stats?['total_items'] as int? ?? 0;
    final totalWarehouses = _stats?['total_warehouses'] as int? ?? 0;
    final lowStock = _stats?['low_stock_count'] as int? ?? 0;
    final totalMovements = _movementSummary?['total_movements'] as int? ?? 0;

    return Row(
      children: [
        Expanded(child: _MiniCard(
          icon: Icons.inventory_2_rounded, label: 'الأصناف',
          value: '$totalItems', color: const Color(0xFF4299E1),
        )),
        const SizedBox(width: 8),
        Expanded(child: _MiniCard(
          icon: Icons.warehouse_rounded, label: 'المستودعات',
          value: '$totalWarehouses', color: const Color(0xFF48BB78),
        )),
        const SizedBox(width: 8),
        Expanded(child: _MiniCard(
          icon: Icons.warning_amber_rounded, label: 'مخزون منخفض',
          value: '$lowStock', color: lowStock > 0 ? const Color(0xFFE53E3E) : const Color(0xFFA0AEC0),
        )),
        const SizedBox(width: 8),
        Expanded(child: _MiniCard(
          icon: Icons.swap_horiz_rounded, label: 'الحركات',
          value: '$totalMovements', color: const Color(0xFF805AD5),
        )),
      ],
    );
  }

  Widget _buildMovementSummary() {
    final ms = _movementSummary;
    if (ms == null) return const SizedBox();
    final totalIn = ms['total_in'] as double;
    final totalOut = ms['total_out'] as double;
    final countIn = ms['count_in'] as int;
    final countOut = ms['count_out'] as int;
    final countTransfer = ms['count_transfer'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      child: Column(
        children: [
          _bar('إدخال', totalIn, Colors.green, countIn),
          const SizedBox(height: 10),
          _bar('إخراج', totalOut, Colors.red, countOut),
          const SizedBox(height: 10),
          _bar('تحويل', 0, Colors.orange, countTransfer, showQty: false),
        ],
      ),
    );
  }

  Widget _bar(String label, double value, Color color, int count, {bool showQty = true}) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.5,
              backgroundColor: color.withValues(alpha: 0.1),
              color: color,
              minHeight: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          showQty ? '${value.toStringAsFixed(0)} ($count)' : '$count',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildWarehouseStock() {
    final warehouses = (_stockByWarehouse?['warehouses'] as List?) ?? [];
    if (warehouses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF1)),
        ),
        child: Center(child: Text('لا توجد بيانات', style: TextStyle(color: Colors.grey.shade500))),
      );
    }
    return Column(
      children: warehouses.map((w) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF1)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF48BB78).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warehouse_rounded, color: Color(0xFF48BB78), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${w['items']} أصناف', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Text(
              (w['total_qty'] as double).toStringAsFixed(0),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF2D3142)),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
