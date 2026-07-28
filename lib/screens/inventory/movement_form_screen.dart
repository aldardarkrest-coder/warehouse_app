import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/inventory_service.dart';
import '../../services/item_service.dart';
import '../../services/warehouse_service.dart';
import '../../services/supplier_service.dart';
import '../../services/customer_service.dart';
import '../../models/item.dart';
import '../../models/warehouse.dart';
import '../../models/supplier.dart';
import '../../models/customer.dart';
import '../../models/inventory_transaction.dart';
import '../../models/inventory_transaction_line.dart';
import '../../widgets/searchable_dropdown.dart';

class MovementFormScreen extends StatefulWidget {
  final AuthService authService;
  final TransactionType initialType;

  const MovementFormScreen({
    super.key,
    required this.authService,
    this.initialType = TransactionType.purchaseReceipt,
  });

  @override
  State<MovementFormScreen> createState() => _MovementFormScreenState();
}

class _TxMeta {
  final TransactionType type;
  final IconData icon;
  final Color color;
  final bool hasSource;
  final bool hasDest;
  final bool hasSupplier;
  final bool hasCustomer;

  const _TxMeta(this.type, this.icon, this.color, this.hasSource, this.hasDest, this.hasSupplier, this.hasCustomer);

  bool get hasSingleWh => hasSource != hasDest;
  String get whLabel => hasSource ? 'من مستودع' : 'المستودع';
}

const _allTypes = [
  _TxMeta(TransactionType.purchaseReceipt, Icons.shopping_cart_rounded, Color(0xFF10B981), false, true, true, false),
  _TxMeta(TransactionType.salesIssue, Icons.point_of_sale_rounded, Color(0xFFEF4444), true, false, false, true),
  _TxMeta(TransactionType.transfer, Icons.swap_horiz_rounded, Color(0xFFF59E0B), true, true, false, false),
  _TxMeta(TransactionType.adjustmentIn, Icons.add_circle_rounded, Color(0xFF22C55E), false, true, false, false),
  _TxMeta(TransactionType.adjustmentOut, Icons.remove_circle_rounded, Color(0xFFDC2626), true, false, false, false),
  _TxMeta(TransactionType.customerReturn, Icons.assignment_return_rounded, Color(0xFF3B82F6), false, true, false, true),
  _TxMeta(TransactionType.supplierReturn, Icons.assignment_return_rounded, Color(0xFFF97316), true, false, true, false),
  _TxMeta(TransactionType.stockCount, Icons.inventory_2_rounded, Color(0xFF8B5CF6), true, false, false, false),
  _TxMeta(TransactionType.openingBalance, Icons.balance_rounded, Color(0xFF6366F1), false, true, false, false),
];

class _MovementFormScreenState extends State<MovementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  late TransactionType _type;
  String? _itemId;
  String? _warehouseId;
  String? _destinationWarehouseId;
  String? _supplierId;
  String? _customerId;
  bool _isLoading = false;
  bool _dataLoading = true;
  String? _dataError;
  List<Item> _items = [];
  List<Warehouse> _warehouses = [];
  List<Supplier> _suppliers = [];
  List<Customer> _customers = [];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _loadData();
  }

  _TxMeta get _meta => _allTypes.firstWhere((t) => t.type == _type);

  Future<void> _loadData() async {
    setState(() { _dataLoading = true; _dataError = null; });
    try {
      final results = await Future.wait([
        ItemService().getAll(onlyActive: true),
        WarehouseService().getAll(onlyActive: true),
        SupplierService().getAll(onlyActive: true),
        CustomerService().getAll(onlyActive: true),
      ]);
      if (mounted) { setState(() {
        _items = results[0] as List<Item>;
        _warehouses = results[1] as List<Warehouse>;
        _suppliers = results[2] as List<Supplier>;
        _customers = results[3] as List<Customer>;
        _dataLoading = false;
      }); }
    } catch (_) {
      if (mounted) setState(() { _dataError = 'فشل تحميل البيانات'; _dataLoading = false; });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_itemId == null) { _showError('يرجى اختيار الصنف'); return; }
    if (_meta.hasSingleWh && _warehouseId == null) { _showError('يرجى اختيار المستودع'); return; }
    if (_meta.hasSource && _meta.hasDest && (_warehouseId == null || _destinationWarehouseId == null)) { _showError('يرجى اختيار مستودع المصدر والوجهة'); return; }
    if (_meta.hasSource && !_meta.hasDest && _warehouseId == null) { _showError('يرجى اختيار المستودع المصدر'); return; }
    if (!_meta.hasSource && _meta.hasDest && _warehouseId == null) { _showError('يرجى اختيار المستودع الوجهة'); return; }

    setState(() => _isLoading = true);
    try {
      final user = widget.authService.currentUser;
      if (user == null) throw Exception('غير مصرح به');
      final service = InventoryService();

      final branches = await Supabase.instance.client.from('branches').select('id').limit(1);
      final branchId = (branches as List).first['id'] as String;

      final qty = double.parse(_quantityController.text);
      final item = _items.firstWhere((i) => i.id == _itemId);

      final itemUnits = await Supabase.instance.client
          .from('item_units')
          .select('id, is_base')
          .eq('item_id', _itemId);
      final baseItemUnit = (itemUnits as List).firstWhere((u) => u['is_base'] == true, orElse: () => itemUnits.first);
      final itemUnitId = baseItemUnit['id'] as String;

      final tx = await service.createTransaction(InventoryTransaction(
        branchId: branchId,
        type: _type,
        transactionDate: DateTime.now(),
        sourceWarehouseId: _meta.hasSource ? _warehouseId : null,
        destinationWarehouseId: _meta.hasDest ? (_meta.hasSource ? _destinationWarehouseId ?? _warehouseId : _warehouseId) : null,
        supplierId: _meta.hasSupplier ? _supplierId : null,
        customerId: _meta.hasCustomer ? _customerId : null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdBy: user.id,
      ));

      if (tx.id == null) throw Exception('فشل إنشاء الحركة');
      await service.createTransactionLine(InventoryTransactionLine(
        transactionId: tx.id!,
        lineNo: 1,
        itemId: item.id!,
        itemUnitId: itemUnitId,
        quantity: qty,
        factorToBase: 1,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      ));

      await service.postTransaction(tx.id!);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _showError('$e');
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.cairo()), backgroundColor: Colors.red.shade700));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(title: Text(_meta.type.displayName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 20),
              _buildFormCard(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _save,
                  style: FilledButton.styleFrom(backgroundColor: _meta.color),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('تسجيل ${_meta.type.displayName}', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: _allTypes.map((t) {
          final selected = _type == t.type;
          return Material(
            color: selected ? t.color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() {
                _type = t.type;
                _warehouseId = null;
                _destinationWarehouseId = null;
                _supplierId = null;
                _customerId = null;
              }),
              child: Container(
                constraints: const BoxConstraints(minWidth: 90),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: selected ? BoxDecoration(
                  border: Border.all(color: t.color.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ) : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.icon, color: selected ? t.color : Colors.grey, size: 20),
                    const SizedBox(height: 2),
                    Text(t.type.displayName, textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        color: selected ? t.color : Colors.grey,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('بيانات الحركة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 18, color: const Color(0xFF1F2937))),
          if (_dataError != null) _errorBox(),
          const SizedBox(height: 16),
          SearchableDropdownFormField<String>(
            labelText: 'الصنف',
            value: _itemId,
            options: _items.map((i) => SearchableDropdownOption(value: i.id!, label: i.name, subtitle: i.sku)).toList(),
            onChanged: (v) => setState(() => _itemId = v),
            isLoading: _dataLoading,
          ),
          const SizedBox(height: 16),
          if (_meta.hasSource) ...[
            SearchableDropdownFormField<String>(
              labelText: 'من مستودع',
              value: _warehouseId,
              options: _warehouses.map((w) => SearchableDropdownOption(value: w.id!, label: w.name, subtitle: w.location)).toList(),
              onChanged: (v) => setState(() => _warehouseId = v),
              isLoading: _dataLoading,
            ),
            const SizedBox(height: 16),
          ],
          if (_meta.hasDest && _meta.hasSource) ...[
            SearchableDropdownFormField<String>(
              labelText: 'إلى مستودع',
              value: _destinationWarehouseId,
              options: _warehouses.where((w) => w.id != _warehouseId).map((w) => SearchableDropdownOption(value: w.id!, label: w.name, subtitle: w.location)).toList(),
              onChanged: (v) => setState(() => _destinationWarehouseId = v),
              isLoading: _dataLoading,
            ),
            const SizedBox(height: 16),
          ],
          if (_meta.hasDest && !_meta.hasSource) ...[
            SearchableDropdownFormField<String>(
              labelText: 'المستودع',
              value: _warehouseId,
              options: _warehouses.map((w) => SearchableDropdownOption(value: w.id!, label: w.name, subtitle: w.location)).toList(),
              onChanged: (v) => setState(() => _warehouseId = v),
              isLoading: _dataLoading,
            ),
            const SizedBox(height: 16),
          ],
          if (_meta.hasSupplier) ...[
            SearchableDropdownFormField<String>(
              labelText: 'المورد',
              value: _supplierId,
              options: _suppliers.map((s) => SearchableDropdownOption(value: s.id!, label: s.name)).toList(),
              onChanged: (v) => setState(() => _supplierId = v),
              isLoading: _dataLoading,
            ),
            const SizedBox(height: 16),
          ],
          if (_meta.hasCustomer) ...[
            SearchableDropdownFormField<String>(
              labelText: 'العميل',
              value: _customerId,
              options: _customers.map((c) => SearchableDropdownOption(value: c.id!, label: c.name)).toList(),
              onChanged: (v) => setState(() => _customerId = v),
              isLoading: _dataLoading,
            ),
            const SizedBox(height: 16),
          ],
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
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _errorBox() {
    return Padding(
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
    );
  }
}
