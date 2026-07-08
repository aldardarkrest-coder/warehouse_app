import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/supplier_service.dart';
import '../../models/supplier.dart';

class SupplierFormScreen extends StatefulWidget {
  final AuthService authService;
  final Supplier? supplier;

  const SupplierFormScreen({super.key, required this.authService, this.supplier});

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _nameController.text = widget.supplier!.name;
      _contactController.text = widget.supplier!.contactPerson ?? '';
      _emailController.text = widget.supplier!.email ?? '';
      _phoneController.text = widget.supplier!.phone ?? '';
      _addressController.text = widget.supplier!.address ?? '';
      _isActive = widget.supplier!.isActive;
    }
  }

  @override void dispose() {
    _nameController.dispose(); _contactController.dispose();
    _emailController.dispose(); _phoneController.dispose(); _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final service = SupplierService();
      final s = Supplier(
        name: _nameController.text.trim(), isActive: _isActive,
        contactPerson: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      );
      if (widget.supplier != null) {
        await service.update(widget.supplier!.id!, s);
      } else {
        await service.create(s);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.supplier != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'تعديل مورد' : 'إضافة مورد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(key: _formKey, child: Column(children: [
          TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'اسم المورد'),
            validator: (v) => v == null || v.trim().isEmpty ? 'اسم المورد مطلوب' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _contactController, decoration: const InputDecoration(labelText: 'جهة الاتصال')),
          const SizedBox(height: 16),
          TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
            keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف'),
            keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'العنوان'), maxLines: 2),
          const SizedBox(height: 16),
          SwitchListTile(title: const Text('نشط'), value: _isActive, onChanged: (v) => setState(() => _isActive = v)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 48,
            child: FilledButton(onPressed: _isLoading ? null : _save,
              child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEditing ? 'حفظ التغييرات' : 'إضافة'))),
        ])),
      ),
    );
  }
}
