import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/item_service.dart';
import '../../services/category_service.dart';
import '../../models/item.dart';
import '../../models/category.dart';

class ItemFormScreen extends StatefulWidget {
  final AuthService authService;
  final Item? item;

  const ItemFormScreen({super.key, required this.authService, this.item});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _skuController = TextEditingController();
  final _unitController = TextEditingController(text: 'piece');
  final _minStockController = TextEditingController(text: '0');
  String? _categoryId;
  bool _isActive = true;
  bool _isLoading = false;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _descController.text = widget.item!.description ?? '';
      _skuController.text = widget.item!.sku;
      _categoryId = widget.item!.categoryId;
      _unitController.text = widget.item!.unit;
      _minStockController.text = widget.item!.minStockLevel.toString();
      _isActive = widget.item!.isActive;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CategoryService().getAll(onlyActive: true);
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _skuController.dispose();
    _unitController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final service = ItemService();
      final item = Item(
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        sku: _skuController.text.trim(),
        categoryId: _categoryId,
        unit: _unitController.text.trim(),
        minStockLevel: double.tryParse(_minStockController.text) ?? 0,
        isActive: _isActive,
      );
      if (widget.item != null) {
        await service.update(widget.item!.id!, item);
      } else {
        await service.create(item);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e', style: GoogleFonts.cairo())));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'تعديل صنف' : 'إضافة صنف')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'اسم الصنف'),
                validator: (v) => v == null || v.trim().isEmpty ? 'اسم الصنف مطلوب' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'الوصف'), maxLines: 3),
              const SizedBox(height: 16),
              TextFormField(controller: _skuController, decoration: const InputDecoration(labelText: 'رمز SKU'),
                validator: (v) => v == null || v.trim().isEmpty ? 'رمز SKU مطلوب' : null),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'التصنيف'),
                items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(controller: _unitController, decoration: const InputDecoration(labelText: 'الوحدة'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(controller: _minStockController, decoration: const InputDecoration(labelText: 'الحد الأدنى'),
                      keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(title: const Text('نشط'), value: _isActive, onChanged: (v) => setState(() => _isActive = v)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 48,
                child: FilledButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEditing ? 'حفظ التغييرات' : 'إضافة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
