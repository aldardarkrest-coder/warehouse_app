import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/inventory_service.dart';
import '../../models/inventory_movement.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class MovementsListScreen extends StatefulWidget {
  final AuthService authService;

  const MovementsListScreen({super.key, required this.authService});

  @override
  State<MovementsListScreen> createState() => _MovementsListScreenState();
}

class _MovementsListScreenState extends State<MovementsListScreen> {
  final _service = InventoryService();
  List<InventoryMovement>? _movements;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try { final data = await _service.getMovements(); if (mounted) setState(() { _movements = data; _isLoading = false; }); }
    catch (e) { if (mounted) setState(() { _error = e.toString(); _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingWidget();
    if (_error != null) return AppErrorWidget(message: _error!, onRetry: _load);
    return RefreshIndicator(
      onRefresh: _load,
      child: _movements!.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.swap_horiz, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16), const Text('لا توجد حركات مخزون'),
          ]))
          : ListView.builder(padding: const EdgeInsets.all(8), itemCount: _movements!.length, itemBuilder: (_, i) {
              final m = _movements![i];
              return Card(child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (m.type == MovementType.in_
                      ? Colors.green
                      : m.type == MovementType.out ? Colors.red : Colors.orange).withValues(alpha: 0.2),
                  child: Icon(
                    m.type == MovementType.in_ ? Icons.add_circle
                        : m.type == MovementType.out ? Icons.remove_circle : Icons.swap_horiz,
                    color: m.type == MovementType.in_ ? Colors.green
                        : m.type == MovementType.out ? Colors.red : Colors.orange,
                  ),
                ),
                title: Text(m.itemName ?? 'غير معروف'),
                subtitle: Text('${m.type.displayName} | ${m.warehouseName ?? ""} | ${m.createdByName ?? ""}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${m.quantity}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    if (m.createdAt != null)
                      Text('${m.createdAt!.day}/${m.createdAt!.month}/${m.createdAt!.year}',
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ));
          }),
    );
  }
}
