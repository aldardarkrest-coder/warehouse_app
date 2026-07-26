import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/inventory_service.dart';
import '../../services/item_service.dart';
import '../../services/warehouse_service.dart';
import '../../models/item.dart';
import '../../models/warehouse.dart';
import '../../models/inventory_movement.dart';
import '../../widgets/searchable_dropdown.dart';

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
  bool _dataLoading = true;
  String? _dataError;
  List<Item> _items = [];
  List<Warehouse> _warehouses = [];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _dataLoading = true; _dataError = null; });
    try {
      final results = await Future.wait([
        ItemService().getAll(onlyActive: true),
        WarehouseService().getAll(onlyActive: true),
      ]);
      if (mounted) setState(() {
        _items = results[0] as List<Item>;
        _warehouses = results[1] as List<Warehouse>;
        _dataLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _dataError = 'فشل تحميل البيانات'; _dataLoading = false; });
    }
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('يرجى اختيار الصنف والمستودع', style: GoogleFonts.cairo())));
      return;
    }
    if (_isTransfer && _destinationWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('يرجى اختيار مستودع الوجهة', style: GoogleFonts.cairo())));
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
      if (mounted)       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e', style: GoogleFonts.cairo())));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: Text(_type == 'in' ? 'حركة إدخال' : _type == 'out' ? 'حركة إخراج' : 'حركة تحويل'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    _typeBtn('in', 'إدخال', Icons.add_rounded, const Color(0xFF10B981)),
                    _typeBtn('out', 'إخراج', Icons.remove_rounded, const Color(0xFFEF4444)),
                    _typeBtn('transfer', 'تحويل', Icons.swap_horiz_rounded, const Color(0xFFF59E0B)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Form Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('بيانات الحركة', style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700, fontSize: 18, color: const Color(0xFF1F2937),
                    )),
                    if (_dataError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Row(children: [
                            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_dataError!, style: GoogleFonts.cairo(color: const Color(0xFFEF4444)))),
                          ]),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SearchableDropdownFormField<String>(
                      labelText: 'الصنف',
                      value: _itemId,
                      options: _items.map((i) => SearchableDropdownOption(value: i.id!, label: i.name, subtitle: i.sku)).toList(),
                      onChanged: (v) => setState(() => _itemId = v),
                      isLoading: _dataLoading,
                    ),
                    const SizedBox(height: 16),
                    SearchableDropdownFormField<String>(
                      labelText: _isTransfer ? 'من مستودع' : 'المستودع',
                      value: _warehouseId,
                      options: _warehouses.map((w) => SearchableDropdownOption(value: w.id!, label: w.name, subtitle: w.location)).toList(),
                      onChanged: (v) => setState(() => _warehouseId = v),
                      isLoading: _dataLoading,
                    ),
                    if (_isTransfer) ...[
                      const SizedBox(height: 16),
                      SearchableDropdownFormField<String>(
                        labelText: 'إلى مستودع',
                        value: _destinationWarehouseId,
                        options: _warehouses.where((w) => w.id != _warehouseId).map((w) => SearchableDropdownOption(value: w.id!, label: w.name, subtitle: w.location)).toList(),
                        onChanged: (v) => setState(() => _destinationWarehouseId = v),
                        isLoading: _dataLoading,
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'الكمية'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'الكمية مطلوبة';
                        if (double.tryParse(v) == null || double.parse(v) <= 0) return 'الكمية يجب أن تكون أكبر من 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _refTypeController,
                      decoration: const InputDecoration(
                        labelText: 'نوع المرجع (اختياري)',
                        hintText: 'مثل: أمر شراء، أمر بيع',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _refIdController,
                      decoration: const InputDecoration(labelText: 'رقم المرجع (اختياري)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('تسجيل الحركة', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeBtn(String value, String label, IconData icon, Color color) {
    final selected = _type == value;
    return Expanded(
      child: Material(
        color: selected ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _type = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: selected ? BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(10),
            ) : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: selected ? color : Colors.grey, size: 18),
                const SizedBox(width: 6),
                Text(label, style: GoogleFonts.cairo(
                  color: selected ? color : Colors.grey,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
