import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/inventory_service.dart';
import '../../models/inventory_transaction.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

const _typeMeta = {
  TransactionType.purchaseReceipt: _TM(Icons.shopping_cart_rounded, Color(0xFF10B981)),
  TransactionType.salesIssue: _TM(Icons.point_of_sale_rounded, Color(0xFFEF4444)),
  TransactionType.transfer: _TM(Icons.swap_horiz_rounded, Color(0xFFF59E0B)),
  TransactionType.adjustmentIn: _TM(Icons.add_circle_rounded, Color(0xFF22C55E)),
  TransactionType.adjustmentOut: _TM(Icons.remove_circle_rounded, Color(0xFFDC2626)),
  TransactionType.customerReturn: _TM(Icons.assignment_return_rounded, Color(0xFF3B82F6)),
  TransactionType.supplierReturn: _TM(Icons.assignment_return_rounded, Color(0xFFF97316)),
  TransactionType.stockCount: _TM(Icons.inventory_2_rounded, Color(0xFF8B5CF6)),
  TransactionType.openingBalance: _TM(Icons.balance_rounded, Color(0xFF6366F1)),
};

class _TM {
  final IconData icon;
  final Color color;
  const _TM(this.icon, this.color);
}

class MovementsListScreen extends StatefulWidget {
  final AuthService authService;
  const MovementsListScreen({super.key, required this.authService});
  @override
  State<MovementsListScreen> createState() => _MovementsListScreenState();
}

class _MovementsListScreenState extends State<MovementsListScreen> {
  final _service = InventoryService();
  List<InventoryTransaction>? _transactions;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _service.getTransactions();
      if (mounted) setState(() { _transactions = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingWidget();
    if (_error != null) return AppErrorWidget(message: _error!, onRetry: _load);
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF1A56DB),
      child: _transactions!.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.swap_horiz_rounded, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('لا توجد حركات مخزون', style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF))),
          ]))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _transactions!.length,
              itemBuilder: (_, i) {
                final m = _transactions![i];
                final meta = _typeMeta[m.type] ?? _TM(Icons.receipt_long_rounded, Colors.grey);
                final isPosted = m.status == TransactionStatus.posted;

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
                          color: meta.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(meta.icon, color: meta.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.type.displayName,
                                style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              '#${m.transactionNo ?? ''} · ${m.status.displayName}',
                              style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF), fontSize: 12),
                            ),
                            if (m.createdByName != null && m.createdByName!.isNotEmpty)
                              Text(
                                'بواسطة: ${m.createdByName}',
                                style: GoogleFonts.cairo(color: const Color(0xFFD1D5DB), fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(
                            isPosted ? Icons.check_circle_rounded : Icons.schedule_rounded,
                            color: isPosted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            size: 20,
                          ),
                          if (m.createdAt != null)
                            Text(
                              '${m.createdAt!.day}/${m.createdAt!.month}/${m.createdAt!.year}',
                              style: GoogleFonts.cairo(color: const Color(0xFFD1D5DB), fontSize: 11),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
