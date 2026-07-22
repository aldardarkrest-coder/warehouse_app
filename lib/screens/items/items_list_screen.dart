import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String _searchQuery = '';

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

  List<Item> get _filteredItems {
    if (_searchQuery.isEmpty) return _items ?? [];
    return _items!.where((item) =>
      item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      item.sku.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingWidget();
    if (_error != null) return AppErrorWidget(message: _error!, onRetry: _load);

    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'بحث عن صنف...',
              hintStyle: GoogleFonts.cairo(color: const Color(0xFF9CA3AF)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        // List
        Expanded(
          child: _filteredItems.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF1A56DB),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredItems.length,
                    itemBuilder: (_, i) {
                      final item = _filteredItems[i];
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
                ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('لا توجد أصناف', style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF), fontSize: 16)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final r = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => ItemFormScreen(authService: widget.authService)),
              );
              if (r == true) _load();
            },
            icon: const Icon(Icons.add),
            label: Text('إضافة صنف', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
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
        border: Border.all(color: item.isActive ? const Color(0xFFE5E7EB) : const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1A56DB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item.sku.length > 2 ? item.sku.substring(0, 2).toUpperCase() : item.sku,
                style: GoogleFonts.cairo(color: const Color(0xFF1A56DB), fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '${item.sku}${item.categoryName != null ? ' · ${item.categoryName}' : ''}',
                  style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF), fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconBtn(Icons.visibility_outlined, const Color(0xFF1A56DB), onView),
              const SizedBox(width: 4),
              _iconBtn(Icons.edit_outlined, const Color(0xFF6B7280), onEdit),
            ],
          ),
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
}
