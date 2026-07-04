import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/inventory_service.dart';
import '../../models/item.dart';
import '../../models/inventory_movement.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class ItemDetailScreen extends StatefulWidget {
  final AuthService authService;
  final Item item;

  const ItemDetailScreen({super.key, required this.authService, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _inventoryService = InventoryService();
  List<InventoryItem>? _stockLevels;
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
      final allStock = await _inventoryService.getStockLevels();
      final filtered = allStock.where((s) => s.itemId == widget.item.id).toList();
      if (mounted) setState(() { _stockLevels = filtered; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.item.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  _infoRow(context, 'رمز SKU', widget.item.sku),
                  if (widget.item.categoryName != null) _infoRow(context, 'التصنيف', widget.item.categoryName!),
                  _infoRow(context, 'الوحدة', widget.item.unit),
                  _infoRow(context, 'الحد الأدنى', widget.item.minStockLevel.toString()),
                  if (widget.item.description != null) _infoRow(context, 'الوصف', widget.item.description!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('المخزون في المستودعات', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_isLoading) const LoadingWidget()
          else if (_error != null) AppErrorWidget(message: _error!, onRetry: _load)
          else if (_stockLevels!.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا يوجد مخزون'))))
          else
            ..._stockLevels!.map((s) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: s.isLowStock ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                  child: Icon(s.isLowStock ? Icons.warning : Icons.check_circle,
                      color: s.isLowStock ? Colors.red : Colors.green),
                ),
                title: Text(s.warehouseName ?? 'غير معروف'),
                trailing: Text(s.quantity.toString(), style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: s.isLowStock ? Colors.red : null,
                )),
              ),
            )),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
