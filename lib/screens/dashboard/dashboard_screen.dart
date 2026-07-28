import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/inventory_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../models/inventory_transaction.dart';

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
  void initState() { super.initState(); _loadStats(); }

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
    final recentTransactions = _stats!['recent_transactions'] as List<InventoryTransaction>;

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: const Color(0xFF1A56DB),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A56DB).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لوحة التحكم',
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'مرحباً بك في نظام إدارة المخزون',
                  style: GoogleFonts.cairo(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Stats Grid
          Row(
            children: [
              Expanded(child: _StatCard(
                icon: Icons.inventory_2_rounded, label: 'إجمالي الأصناف',
                value: '$totalItems', color: const Color(0xFF1A56DB),
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                icon: Icons.warehouse_rounded, label: 'المستودعات',
                value: '$totalWarehouses', color: const Color(0xFF10B981),
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                icon: Icons.warning_amber_rounded, label: 'مخزون منخفض',
                value: '$lowStockCount',
                color: lowStockCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
              )),
            ],
          ),
          const SizedBox(height: 24),
          // Recent Movements Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'آخر الحركات',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              if (recentTransactions.isNotEmpty)
                TextButton(
                  onPressed: () {},
                  child: Text('عرض الكل', style: GoogleFonts.cairo(color: const Color(0xFF1A56DB), fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (recentTransactions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('لا توجد حركات بعد', style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF), fontSize: 14)),
                ],
              ),
            )
          else
            ...recentTransactions.map((m) => _TransactionCard(transaction: m)),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.cairo(
            fontSize: 24, fontWeight: FontWeight.w800, color: color,
          )),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.cairo(
            fontSize: 12, color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w500,
          ), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final InventoryTransaction transaction;
  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPosted = transaction.status == TransactionStatus.posted;
    final color = isPosted ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final icon = isPosted ? Icons.check_circle_rounded : Icons.schedule_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
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
                  transaction.type.displayName,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '#${transaction.transactionNo ?? ''} · ${transaction.status.displayName}',
                  style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF), fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(icon, color: color, size: 20),
              if (transaction.createdAt != null)
                Text(
                  '${transaction.createdAt!.day}/${transaction.createdAt!.month}/${transaction.createdAt!.year}',
                  style: GoogleFonts.cairo(color: const Color(0xFFD1D5DB), fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
