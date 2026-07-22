import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/supplier_service.dart';
import '../../models/supplier.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import 'supplier_form_screen.dart';

class SuppliersListScreen extends StatefulWidget {
  final AuthService authService;

  const SuppliersListScreen({super.key, required this.authService});

  @override
  State<SuppliersListScreen> createState() => _SuppliersListScreenState();
}

class _SuppliersListScreenState extends State<SuppliersListScreen> {
  final _service = SupplierService();
  List<Supplier>? _suppliers;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try { final data = await _service.getAll(); if (mounted) setState(() { _suppliers = data; _isLoading = false; }); }
    catch (e) { if (mounted) setState(() { _error = e.toString(); _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingWidget();
    if (_error != null) return AppErrorWidget(message: _error!, onRetry: _load);
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF1A56DB),
      child: _suppliers!.isEmpty
          ? _emptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _suppliers!.length,
              itemBuilder: (_, i) {
                final s = _suppliers![i];
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
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.local_shipping_rounded, color: Color(0xFFF59E0B), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14)),
                            if (s.phone != null || s.email != null) ...[
                              const SizedBox(height: 2),
                              Text(s.phone ?? s.email ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF), fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _iconBtn(Icons.edit_outlined, const Color(0xFF1A56DB), () => _navigateToForm(supplier: s)),
                          const SizedBox(width: 4),
                          _iconBtn(Icons.delete_outline_rounded, const Color(0xFFEF4444), () => _delete(s)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('لا توجد موردين', style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF), fontSize: 16)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () => _navigateToForm(), icon: const Icon(Icons.add), label: Text('إضافة مورد', style: GoogleFonts.cairo(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Future<void> _navigateToForm({Supplier? supplier}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SupplierFormScreen(authService: widget.authService, supplier: supplier)),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Supplier s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الحذف', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        content: Text('هل أنت متأكد من حذف "${s.name}"؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: GoogleFonts.cairo())),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: Text('حذف', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try { await _service.delete(s.id!); _load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e', style: GoogleFonts.cairo()))); }
  }
}
