import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/warehouse_service.dart';
import '../../models/warehouse.dart';

class WarehouseFormScreen extends StatefulWidget {
  final AuthService authService;
  final Warehouse? warehouse;

  const WarehouseFormScreen({super.key, required this.authService, this.warehouse});

  @override
  State<WarehouseFormScreen> createState() => _WarehouseFormScreenState();
}

class _WarehouseFormScreenState extends State<WarehouseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.warehouse != null) {
      _nameController.text = widget.warehouse!.name;
      _locationController.text = widget.warehouse!.location ?? '';
      _descController.text = widget.warehouse!.description ?? '';
      _isActive = widget.warehouse!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final service = WarehouseService();
      final w = Warehouse(
        name: _nameController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        isActive: _isActive,
      );
      if (widget.warehouse != null) await service.update(widget.warehouse!.id!, w);
      else await service.create(w);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.warehouse != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'تعديل مستودع' : 'إضافة مستودع')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'اسم المستودع'),
                validator: (v) => v == null || v.trim().isEmpty ? 'اسم المستودع مطلوب' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'الموقع')),
              const SizedBox(height: 16),
              TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'الوصف'), maxLines: 3),
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
