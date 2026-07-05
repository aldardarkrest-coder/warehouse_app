import 'package:flutter/material.dart';
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
  void initState() {
    super.initState();
    _load();
  }

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
      child: _suppliers!.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.local_shipping_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16), const Text('لا توجد موردين'),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: () => _navigateToForm(), icon: const Icon(Icons.add), label: const Text('إضافة مورد')),
          ]))
          : ListView.builder(
              padding: const EdgeInsets.all(8), itemCount: _suppliers!.length,
              itemBuilder: (_, i) {
                final s = _suppliers![i];
                return Card(child: ListTile(
                  leading: CircleAvatar(child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?')),
                  title: Text(s.name), subtitle: Text(s.phone ?? s.email ?? ''),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _navigateToForm(supplier: s)),
                    IconButton(icon: const Icon(Icons.delete_outlined, color: Colors.red), onPressed: () => _delete(s)),
                  ]),
                ));
              },
            ),
    );
  }

  Future<void> _navigateToForm({Supplier? supplier}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SupplierFormScreen(authService: widget.authService, supplier: supplier)));
    if (result == true) _load();
  }

  Future<void> _delete(Supplier s) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('تأكيد الحذف'), content: Text('هل أنت متأكد من حذف "${s.name}"؟'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف'))],
    ));
    if (confirm != true) return;
    try { await _service.delete(s.id!); _load(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
  }
}
