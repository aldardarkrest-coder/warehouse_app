import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/warehouse_service.dart';
import '../../models/warehouse.dart';
import '../../models/branch.dart';
import '../../widgets/searchable_dropdown.dart';

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
  final _codeController = TextEditingController();
  final _locationController = TextEditingController();
  String? _branchId;
  bool _isActive = true;
  bool _isLoading = false;
  bool _branchLoading = true;
  String? _branchError;
  List<Branch> _branches = [];

  @override
  void initState() {
    super.initState();
    if (widget.warehouse != null) {
      _nameController.text = widget.warehouse!.name;
      _codeController.text = widget.warehouse!.code;
      _locationController.text = widget.warehouse!.location ?? '';
      _branchId = widget.warehouse!.branchId;
      _isActive = widget.warehouse!.isActive;
    }
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() { _branchLoading = true; _branchError = null; });
    try {
      final data = await Supabase.instance.client.from('branches').select().order('name');
      if (mounted) setState(() { _branches = data.map((e) => Branch.fromJson(e)).toList(); _branchLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _branchError = 'فشل تحميل الفروع'; _branchLoading = false; });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_branchId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار الفرع')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final service = WarehouseService();
      final w = Warehouse(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        branchId: _branchId!,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        isActive: _isActive,
      );
      if (widget.warehouse != null) {
        await service.update(widget.warehouse!.id!, w);
      } else {
        await service.create(w);
      }
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
              TextFormField(controller: _codeController, decoration: const InputDecoration(labelText: 'رمز المستودع'),
                validator: (v) => v == null || v.trim().isEmpty ? 'رمز المستودع مطلوب' : null),
              const SizedBox(height: 16),
              _branchLoading
                  ? const LinearProgressIndicator()
                  : SearchableDropdownFormField<String>(
                      labelText: 'الفرع',
                      value: _branchId,
                      options: _branches.map((b) => SearchableDropdownOption(value: b.id!, label: '${b.name} (${b.code})')).toList(),
                      onChanged: (v) => setState(() => _branchId = v),
                      errorMessage: _branchError,
                    ),
              const SizedBox(height: 16),
              TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'الموقع')),
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
