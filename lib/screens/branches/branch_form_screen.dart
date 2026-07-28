import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/branch_service.dart';
import '../../models/branch.dart';

class BranchFormScreen extends StatefulWidget {
  final AuthService authService;
  final Branch? branch;
  const BranchFormScreen({super.key, required this.authService, this.branch});
  @override
  State<BranchFormScreen> createState() => _BranchFormScreenState();
}

class _BranchFormScreenState extends State<BranchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.branch != null) {
      _nameController.text = widget.branch!.name;
      _codeController.text = widget.branch!.code;
      _phoneController.text = widget.branch!.phone ?? '';
      _addressController.text = widget.branch!.address ?? '';
      _isActive = widget.branch!.isActive;
    }
  }

  @override void dispose() {
    _nameController.dispose(); _codeController.dispose();
    _phoneController.dispose(); _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final service = BranchService();
      final b = Branch(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        isActive: _isActive,
      );
      if (widget.branch != null) {
        await service.update(widget.branch!.id!, b);
      } else {
        await service.create(b);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.branch != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'تعديل فرع' : 'إضافة فرع')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(key: _formKey, child: Column(children: [
          TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'اسم الفرع'),
            validator: (v) => v == null || v.trim().isEmpty ? 'اسم الفرع مطلوب' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _codeController, decoration: const InputDecoration(labelText: 'رمز الفرع'),
            validator: (v) => v == null || v.trim().isEmpty ? 'رمز الفرع مطلوب' : null),
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
