import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/category_service.dart';
import '../../models/category.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import 'category_form_screen.dart';

class CategoriesListScreen extends StatefulWidget {
  final AuthService authService;

  const CategoriesListScreen({super.key, required this.authService});

  @override
  State<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends State<CategoriesListScreen> {
  final _service = CategoryService();
  List<Category>? _categories;
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
      if (mounted) setState(() { _categories = data; _isLoading = false; });
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
      child: _categories!.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('لا توجد تصنيفات', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _navigateToForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة تصنيف'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _categories!.length,
              itemBuilder: (_, i) {
                final cat = _categories![i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(cat.isActive ? Icons.category : Icons.block, color: cat.isActive ? null : Colors.red)),
                    title: Text(cat.name),
                    subtitle: cat.description != null ? Text(cat.description!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _navigateToForm(category: cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outlined, color: Colors.red),
                          onPressed: () => _delete(cat),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _navigateToForm({Category? category}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CategoryFormScreen(
          authService: widget.authService,
          category: category,
        ),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${category.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.delete(category.id!);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
