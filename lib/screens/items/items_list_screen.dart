import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/item_service.dart';
import '../../models/item.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import 'item_form_screen.dart';
import 'item_detail_screen.dart';

class ItemsListScreen extends StatefulWidget {
  final AuthService authService;

  const ItemsListScreen({super.key, required this.authService});

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {
  final _service = ItemService();
  List<Item>? _items;
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
      if (mounted) setState(() { _items = data; _isLoading = false; });
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
      child: _items!.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  const Text('لا توجد أصناف'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _navigateToForm(),
                    icon: const Icon(Icons.add), label: const Text('إضافة صنف'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _items!.length,
              itemBuilder: (_, i) {
                final item = _items![i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item.isActive
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.errorContainer,
                      child: Text(item.sku.length > 3 ? item.sku.substring(0, 3).toUpperCase() : item.sku),
                    ),
                    title: Text(item.name),
                    subtitle: Text('${item.sku}${item.categoryName != null ? ' - ${item.categoryName}' : ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.visibility_outlined), onPressed: () => _navigateToDetail(item)),
                        IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _navigateToForm(item: item)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _navigateToDetail(Item item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ItemDetailScreen(authService: widget.authService, item: item)),
    );
  }

  Future<void> _navigateToForm({Item? item}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ItemFormScreen(authService: widget.authService, item: item)),
    );
    if (result == true) _load();
  }
}
