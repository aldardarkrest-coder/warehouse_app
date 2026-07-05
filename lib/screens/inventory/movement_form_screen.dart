import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/inventory_service.dart';
import '../../services/item_service.dart';
import '../../services/warehouse_service.dart';
import '../../models/item.dart';
import '../../models/warehouse.dart';
import '../../models/inventory_movement.dart';

class MovementFormScreen extends StatefulWidget {
  final AuthService authService;
  final String initialType;

  const MovementFormScreen({
    super.key,
    required this.authService,
    this.initialType = 'in',
  });

  @override
  State<MovementFormScreen> createState() => _MovementFormScreenState();
}

class _MovementFormScreenState extends State<MovementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _refTypeController = TextEditingController();
  final _refIdController = TextEditingController();
  String _type = 'in';
  String? _itemId;
  String? _warehouseId;
  String? _destinationWarehouseId;
  bool _isLoading = false;
  List<Item> _items = [];
  List<Warehouse> _warehouses = [];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final items = await ItemService().getAll(onlyActive: true);
      final warehouses = await WarehouseService().getAll(onlyActive: true);
      if (mounted) setState(() { _items = items; _warehouses = warehouses; });
    } catch (_) {}
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    _refTypeController.dispose();
    _refIdController.dispose();
    super.dispose();
  }

  bool get _isTransfer => _type == 'transfer';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_itemId == null || _warehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار الصنف والمستودع')));
      return;
    }
    if (_isTransfer && _destinationWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار مستودع الوجهة')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = widget.authService.currentUser;
      if (user == null) throw Exception('غير مصرح به');
      final service = InventoryService();

      if (_isTransfer) {
        await service.createMovement(InventoryMovement(
          itemId: _itemId!, warehouseId: _warehouseId!,
          type: MovementType.out, quantity: double.parse(_quantityController.text),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdBy: user.id,
        ));
        await service.createMovement(InventoryMovement(
          itemId: _itemId!, warehouseId: _destinationWarehouseId!,
          type: MovementType.in_, quantity: double.parse(_quantityController.text),
          notes: 'تحويل من ${_warehouses.firstWhere((w) => w.id == _warehouseId).name}',
          createdBy: user.id,
        ));
      } else {
        await service.createMovement(InventoryMovement(
          itemId: _itemId!, warehouseId: _warehouseId!,
          type: _type == 'in' ? MovementType.in_ : MovementType.out,
          quantity: double.parse(_quantityController.text),
          referenceType: _refTypeController.text.trim().isEmpty ? null : _refTypeController.text.trim(),
          referenceId: _refIdController.text.trim().isEmpty ? null : _refIdController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdBy: user.id,
        ));
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_type == 'in' ? 'حركة إدخال' : _type == 'out' ? 'حركة إخراج' : 'حركة تحويل')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(key: _formKey, child: Column(children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'in', label: Text('إدخال'), icon: Icon(Icons.add_circle)),
              ButtonSegment(value: 'out', label: Text('إخراج'), icon: Icon(Icons.remove_circle)),
              ButtonSegment(value: 'transfer', label: Text('تحويل'), icon: Icon(Icons.swap_horiz)),
            ],
            selected: {_type},
            onSelectionChanged: (v) => setState(() => _type = v.first),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _itemId, decoration: InputDecoration(labelText: 'الصنف'),
            items: _items.map((i) => DropdownMenuItem(value: i.id, child: Text('${i.name} (${i.sku})'))).toList(),
            onChanged: (v) => setState(() => _itemId = v),
            validator: (v) => v == null ? 'يرجى اختيار صنف' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _warehouseId, decoration: InputDecoration(labelText: _isTransfer ? 'من مستودع' : 'المستودع'),
            items: _warehouses.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
            onChanged: (v) => setState(() => _warehouseId = v),
            validator: (v) => v == null ? 'يرجى اختيار مستودع' : null,
          ),
          if (_isTransfer) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _destinationWarehouseId, decoration: InputDecoration(labelText: 'إلى مستودع'),
              items: _warehouses.where((w) => w.id != _warehouseId).map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
              onChanged: (v) => setState(() => _destinationWarehouseId = v),
              validator: (v) => v == null ? 'يرجى اختيار مستودع الوجهة' : null,
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(controller: _quantityController, decoration: const InputDecoration(labelText: 'الكمية'),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return 'الكمية مطلوبة';
              if (double.tryParse(v) == null || double.parse(v) <= 0) return 'الكمية يجب أن تكون أكبر من 0';
              return null;
            }),
          const SizedBox(height: 16),
          TextFormField(controller: _refTypeController, decoration: const InputDecoration(
            labelText: 'نوع المرجع (اختياري)',
            hintText: 'مثل: أمر شراء، أمر بيع',
          )),
          const SizedBox(height: 16),
          TextFormField(controller: _refIdController, decoration: const InputDecoration(labelText: 'رقم المرجع (اختياري)')),
          const SizedBox(height: 16),
          TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'), maxLines: 2),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 48,
            child: FilledButton(onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('تسجيل الحركة'))),
        ])),
      ),
    );
  }
}
