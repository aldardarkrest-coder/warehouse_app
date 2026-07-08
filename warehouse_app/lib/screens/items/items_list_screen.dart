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
  void initState() { super.initState(); _load(); }

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
      color: const Color(0xFF2D3142),
      child: _items!.isEmpty
          ? _emptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _items!.length,
              itemBuilder: (_, i) {
                final item = _items![i];
                return _ItemCard(
                  item: item,
                  onView: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ItemDetailScreen(authService: widget.authService, item: item),
                  )),
                  onEdit: () async {
                    final r = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => ItemFormScreen(authService: widget.authService, item: item)),
                    );
                    if (r == true) _load();
                  },
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
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('لا توجد أصناف', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final r = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => ItemFormScreen(authService: widget.authService)),
              );
              if (r == true) _load();
            },
            icon: const Icon(Icons.add),
            label: const Text('إضافة صنف'),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onView;
  final VoidCallback onEdit;

  const _ItemCard({required this.item, required this.onView, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.isActive ? const Color(0xFFE8ECF1) : const Color(0xFFE53E3E).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF4299E1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.sku.length > 2 ? item.sku.substring(0, 2).toUpperCase() : item.sku,
              style: const TextStyle(color: Color(0xFF4299E1), fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '${item.sku}${item.categoryName != null ? ' · ${item.categoryName}' : ''}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconBtn(Icons.visibility_outlined, const Color(0xFF4299E1), onView),
              const SizedBox(width: 4),
              _iconBtn(Icons.edit_outlined, const Color(0xFF718096), onEdit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
