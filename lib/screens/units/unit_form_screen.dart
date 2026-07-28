import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/unit_service.dart';
import '../../models/unit.dart';

class UnitFormScreen extends StatefulWidget {
  final AuthService authService;
  final Unit? unit;
  const UnitFormScreen({super.key, required this.authService, this.unit});
  @override
  State<UnitFormScreen> createState() => _UnitFormScreenState();
}

class _UnitFormScreenState extends State<UnitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _symbolController = TextEditingController();
  final _decimalsController = TextEditingController(text: '0');
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.unit != null) {
      _nameController.text = widget.unit!.name;
      _codeController.text = widget.unit!.code;
      _symbolController.text = widget.unit!.symbol ?? '';
      _decimalsController.text = widget.unit!.decimalPlaces.toString();
      _isActive = widget.unit!.isActive;
    }
  }

  @override void dispose() {
    _nameController.dispose(); _codeController.dispose();
    _symbolController.dispose(); _decimalsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final service = UnitService();
      final u = Unit(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        symbol: _symbolController.text.trim().isEmpty ? null : _symbolController.text.trim(),
        decimalPlaces: int.tryParse(_decimalsController.text) ?? 0,
        isActive: _isActive,
      );
      if (widget.unit != null) {
        await service.update(widget.unit!.id!, u);
      } else {
        await service.create(u);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.unit != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'تعديل وحدة' : 'إضافة وحدة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(key: _formKey, child: Column(children: [
          TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'اسم الوحدة'),
            validator: (v) => v == null || v.trim().isEmpty ? 'اسم الوحدة مطلوب' : null),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextFormField(controller: _codeController, decoration: const InputDecoration(labelText: 'الرمز'),
              validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null)),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: _symbolController, decoration: const InputDecoration(labelText: 'الاختصار'))),
          ]),
          const SizedBox(height: 16),
          TextFormField(controller: _decimalsController, decoration: const InputDecoration(labelText: 'عدد الخانات العشرية'),
            keyboardType: TextInputType.number),
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
