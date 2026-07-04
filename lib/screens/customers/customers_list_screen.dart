import 'package:flutter/material.dart';
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

  @override void initState() { super.initState(); _load(); }

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
      child: _customers!.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.people_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16), const Text('لا توجد عملاء'),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: () => _navigateToForm(), icon: const Icon(Icons.add), label: const Text('إضافة عميل')),
          ]))
          : ListView.builder(padding: const EdgeInsets.all(8), itemCount: _customers!.length, itemBuilder: (_, i) {
              final c = _customers![i];
              return Card(child: ListTile(
                leading: CircleAvatar(child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?')),
                title: Text(c.name), subtitle: c.phone ?? c.email,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _navigateToForm(customer: c)),
                  IconButton(icon: const Icon(Icons.delete_outlined, color: Colors.red), onPressed: () => _delete(c)),
                ]),
              ));
          }),
    );
  }

  Future<void> _navigateToForm({Customer? customer}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CustomerFormScreen(authService: widget.authService, customer: customer)));
    if (result == true) _load();
  }

  Future<void> _delete(Customer c) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('تأكيد الحذف'), content: Text('هل أنت متأكد من حذف "${c.name}"؟'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف'))],
    ));
    if (confirm != true) return;
    try { await _service.delete(c.id!); _load(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
  }
}
