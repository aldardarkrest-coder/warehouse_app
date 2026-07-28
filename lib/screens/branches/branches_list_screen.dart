import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/branch_service.dart';
import '../../models/branch.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import 'branch_form_screen.dart';

class BranchesListScreen extends StatefulWidget {
  final AuthService authService;
  const BranchesListScreen({super.key, required this.authService});
  @override
  State<BranchesListScreen> createState() => _BranchesListScreenState();
}

class _BranchesListScreenState extends State<BranchesListScreen> {
  final _service = BranchService();
  List<Branch>? _branches;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try { final data = await _service.getAll(); if (mounted) setState(() { _branches = data; _isLoading = false; }); }
    catch (e) { if (mounted) setState(() { _error = e.toString(); _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingWidget();
    if (_error != null) return AppErrorWidget(message: _error!, onRetry: _load);
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF1A56DB),
      child: _branches!.isEmpty
          ? _emptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _branches!.length,
              itemBuilder: (_, i) {
                final b = _branches![i];
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
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.business_rounded, color: Color(0xFF3B82F6), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.name, style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(b.code, style: GoogleFonts.cairo(color: const Color(0xFF6B7280), fontSize: 12)),
                                if (b.phone != null) ...[
                                  const SizedBox(width: 8),
                                  Text(b.phone!, style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF), fontSize: 12)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _iconBtn(Icons.edit_outlined, const Color(0xFF1A56DB), () => _navigateToForm(branch: b)),
                          const SizedBox(width: 4),
                          _iconBtn(Icons.delete_outline_rounded, const Color(0xFFEF4444), () => _delete(b)),
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
          Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('لا توجد فروع', style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF), fontSize: 16)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () => _navigateToForm(), icon: const Icon(Icons.add), label: Text('إضافة فرع', style: GoogleFonts.cairo(fontWeight: FontWeight.w600))),
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

  Future<void> _navigateToForm({Branch? branch}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BranchFormScreen(authService: widget.authService, branch: branch)),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Branch b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الحذف', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        content: Text('هل أنت متأكد من حذف "${b.name}"؟', style: GoogleFonts.cairo()),
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
    try { await _service.delete(b.id!); _load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e', style: GoogleFonts.cairo()))); }
  }
}
