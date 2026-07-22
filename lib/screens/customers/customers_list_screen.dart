import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/customer_service.dart';
import '../../models/customer.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import 'customer_form_screen.dart';

class CustomersListScreen extends StatefulWidget {
  final AuthService authService;

  const CustomersListScreen({super.key, required this.authService});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final _service = CustomerService();
  List<Customer>? _customers;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try { final data = await _service.getAll(); if (mounted) setState(() { _customers = data; _isLoading = false; }); }
    catch (e) { if (mounted) setState(() { _error = e.toString(); _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingWidget();
    if (_error != null) return AppErrorWidget(message: _error!, onRetry: _load);
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF1A56DB),
      child: _customers!.isEmpty
          ? _emptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _customers!.length,
              itemBuilder: (_, i) {
                final c = _customers![i];
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
                          color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.people_rounded, color: Color(0xFFEC4899), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14)),
                            if (c.phone != null || c.email != null) ...[
                              const SizedBox(height: 2),
                              Text(c.phone ?? c.email ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF), fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _iconBtn(Icons.edit_outlined, const Color(0xFF1A56DB), () => _navigateToForm(customer: c)),
                          const SizedBox(width: 4),
                          _iconBtn(Icons.delete_outline_rounded, const Color(0xFFEF4444), () => _delete(c)),
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
          Icon(Icons.people_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('لا توجد عملاء', style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF), fontSize: 16)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () => _navigateToForm(), icon: const Icon(Icons.add), label: Text('إضافة عميل', style: GoogleFonts.cairo(fontWeight: FontWeight.w600))),
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

  Future<void> _navigateToForm({Customer? customer}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CustomerFormScreen(authService: widget.authService, customer: customer)),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Customer c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الحذف', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        content: Text('هل أنت متأكد من حذف "${c.name}"؟', style: GoogleFonts.cairo()),
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
    try { await _service.delete(c.id!); _load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e', style: GoogleFonts.cairo()))); }
  }
}
