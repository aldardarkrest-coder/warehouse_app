import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/warehouse_service.dart';
import '../../models/warehouse.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import 'warehouse_form_screen.dart';

class WarehousesListScreen extends StatefulWidget {
  final AuthService authService;

  const WarehousesListScreen({super.key, required this.authService});

  @override
  State<WarehousesListScreen> createState() => _WarehousesListScreenState();
}

class _WarehousesListScreenState extends State<WarehousesListScreen> {
  final _service = WarehouseService();
  List<Warehouse>? _warehouses;
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
      final data = await _service.getAll();
      if (mounted) setState(() { _warehouses = data; _isLoading = false; });
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
      child: _warehouses!.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warehouse_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  const Text('لا توجد مستودعات'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _navigateToForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة مستودع'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _warehouses!.length,
              itemBuilder: (_, i) {
                final w = _warehouses![i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(w.isActive ? Icons.warehouse : Icons.block, color: w.isActive ? null : Colors.red)),
                    title: Text(w.name),
                    subtitle: w.location ?? w.description,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _navigateToForm(warehouse: w)),
                        IconButton(icon: const Icon(Icons.delete_outlined, color: Colors.red), onPressed: () => _delete(w)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _navigateToForm({Warehouse? warehouse}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => WarehouseFormScreen(authService: widget.authService, warehouse: warehouse)),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Warehouse w) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${w.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm != true) return;
    try { await _service.delete(w.id!); _load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
  }
}
