import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/item_service.dart';
import '../../services/category_service.dart';
import '../../services/warehouse_service.dart';
import '../../services/supplier_service.dart';
import '../../services/customer_service.dart';
import '../../services/branch_service.dart';
import '../../services/unit_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class ReportsScreen extends StatefulWidget {
  final AuthService authService;
  const ReportsScreen({super.key, required this.authService});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _current = 0;
  List<dynamic> _allData = [];
  List<int> _filtered = [];
  final Set<String> _selectedIds = {};
  String _query = '';
  bool _loading = true;
  String? _error;

  static final _entities = [
    _EntityConfig('الأصناف', Icons.inventory_2_rounded, () => ItemService().getAll(), [
      _Col('الاسم', (i) => i.name),
      _Col('الكود', (i) => i.sku),
      _Col('التصنيف', (i) => i.categoryName ?? ''),
      _Col('الوحدة', (i) => i.baseUnitName ?? ''),
      _Col('الحد الأدنى', (i) => '${(i.minStockLevel as num?)?.toDouble() ?? 0}'),
      _Col('نشط', (i) => i.isActive == true ? 'نعم' : 'لا'),
    ]),
    _EntityConfig('التصنيفات', Icons.category_rounded, () => CategoryService().getAll(), [
      _Col('الاسم', (i) => i.name),
      _Col('الوصف', (i) => i.description ?? ''),
      _Col('نشط', (i) => i.isActive == true ? 'نعم' : 'لا'),
    ]),
    _EntityConfig('المستودعات', Icons.warehouse_rounded, () => WarehouseService().getAll(), [
      _Col('الكود', (i) => i.code),
      _Col('الاسم', (i) => i.name),
      _Col('الفرع', (i) => i.branchName ?? ''),
      _Col('الموقع', (i) => i.location ?? ''),
      _Col('نشط', (i) => i.isActive == true ? 'نعم' : 'لا'),
    ]),
    _EntityConfig('الموردين', Icons.local_shipping_rounded, () => SupplierService().getAll(), [
      _Col('الكود', (i) => i.code ?? ''),
      _Col('الاسم', (i) => i.name),
      _Col('جهة الاتصال', (i) => i.contactPerson ?? ''),
      _Col('الهاتف', (i) => i.phone ?? ''),
      _Col('البريد', (i) => i.email ?? ''),
      _Col('نشط', (i) => i.isActive == true ? 'نعم' : 'لا'),
    ]),
    _EntityConfig('العملاء', Icons.people_rounded, () => CustomerService().getAll(), [
      _Col('الكود', (i) => i.code ?? ''),
      _Col('الاسم', (i) => i.name),
      _Col('جهة الاتصال', (i) => i.contactPerson ?? ''),
      _Col('الهاتف', (i) => i.phone ?? ''),
      _Col('البريد', (i) => i.email ?? ''),
      _Col('نشط', (i) => i.isActive == true ? 'نعم' : 'لا'),
    ]),
    _EntityConfig('الفروع', Icons.business_rounded, () => BranchService().getAll(), [
      _Col('الكود', (i) => i.code),
      _Col('الاسم', (i) => i.name),
      _Col('العنوان', (i) => i.address ?? ''),
      _Col('الهاتف', (i) => i.phone ?? ''),
      _Col('نشط', (i) => i.isActive == true ? 'نعم' : 'لا'),
    ]),
    _EntityConfig('الوحدات', Icons.straighten_rounded, () => UnitService().getAll(), [
      _Col('الكود', (i) => i.code),
      _Col('الاسم', (i) => i.name),
      _Col('الرمز', (i) => i.symbol ?? ''),
      _Col('الخانات العشرية', (i) => '${i.decimalPlaces}'),
      _Col('نشط', (i) => i.isActive == true ? 'نعم' : 'لا'),
    ]),
  ];

  _EntityConfig get _cfg => _entities[_current];
  List<_Col> get _cols => _cfg.columns;
  List<String> get _headers => _cols.map((c) => c.label).toList();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _cfg.loader();
      if (mounted) setState(() {
        _allData = data;
        _selectedIds.clear();
        _filter();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _filter() {
    final q = _query.trim().toLowerCase();
    _filtered = List.generate(_allData.length, (i) => i)
        .where((i) => q.isEmpty || _cols.any((c) => c.get(_allData[i]).toLowerCase().contains(q)))
        .toList();
  }

  bool get _allSelected => _filtered.every((i) => _selectedIds.contains(_idOf(_allData[i])));
  bool get _someSelected => _filtered.any((i) => _selectedIds.contains(_idOf(_allData[i])));
  String _idOf(dynamic item) => item.id as String? ?? '';

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingWidget(message: 'جاري تحميل البيانات...');
    if (_error != null) return AppErrorWidget(message: _error!, onRetry: _load);
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF1A56DB),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          _buildDropdown(),
          const SizedBox(height: 14),
          _buildSearch(),
          const SizedBox(height: 14),
          _buildTable(),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _current,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF1A56DB)),
          style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937)),
          items: List.generate(_entities.length, (i) => DropdownMenuItem(
            value: i,
            child: Row(children: [
              Icon(_entities[i].icon, size: 20, color: const Color(0xFF1A56DB)),
              const SizedBox(width: 10),
              Text(_entities[i].label),
            ]),
          )),
          onChanged: (v) { if (v == null) return; setState(() { _current = v; }); _load(); },
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      onChanged: (v) => setState(() { _query = v; _filter(); _selectedIds.clear(); }),
      decoration: InputDecoration(
        hintText: 'بحث ...',
        hintStyle: GoogleFonts.cairo(color: const Color(0xFF9CA3AF)),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF9CA3AF)),
        suffixIcon: _query.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: () => setState(() { _query = ''; _filter(); _selectedIds.clear(); }))
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildTable() {
    if (_allData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(children: [
          Icon(_cfg.icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('لا توجد بيانات', style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF), fontSize: 14)),
        ]),
      );
    }
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 42,
          dataRowMinHeight: 38,
          dataRowMaxHeight: 44,
          columnSpacing: 20,
          headingTextStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 11, color: const Color(0xFF6B7280)),
          dataTextStyle: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF1F2937)),
          columns: [
            DataColumn(label: Checkbox(
              value: _allSelected,
              tristate: _someSelected,
              onChanged: (_) => setState(() {
                if (_allSelected) for (final i in _filtered) _selectedIds.remove(_idOf(_allData[i]));
                else for (final i in _filtered) _selectedIds.add(_idOf(_allData[i]));
              }),
            )),
            ..._headers.map((h) => DataColumn(label: Text(h, textAlign: TextAlign.center))),
          ],
          rows: _filtered.map((i) {
            final item = _allData[i];
            final id = _idOf(item);
            final checked = _selectedIds.contains(id);
            final q = _query.toLowerCase();
            return DataRow(
              selected: checked,
              onSelectChanged: (_) => setState(() => checked ? _selectedIds.remove(id) : _selectedIds.add(id)),
              cells: [
                DataCell(Checkbox(value: checked, onChanged: (_) => setState(() => checked ? _selectedIds.remove(id) : _selectedIds.add(id)))),
                ..._cols.map((c) {
                  final v = c.get(item);
                  final rich = q.isNotEmpty && v.toLowerCase().contains(q);
                  return DataCell(rich ? RichText(text: _highlight(v, q)) : Text(v));
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  TextSpan _highlight(String text, String query) {
    final idx = text.toLowerCase().indexOf(query);
    if (idx < 0) return TextSpan(text: text);
    return TextSpan(children: [
      TextSpan(text: text.substring(0, idx)),
      TextSpan(text: text.substring(idx, idx + query.length), style: const TextStyle(backgroundColor: Color(0xFFFFF3C4), fontWeight: FontWeight.w700)),
      TextSpan(text: text.substring(idx + query.length)),
    ]);
  }
}

class _Col {
  final String label;
  final String Function(dynamic) get;
  const _Col(this.label, this.get);
}

class _EntityConfig {
  final String label;
  final IconData icon;
  final Future<List<dynamic>> Function() loader;
  final List<_Col> columns;
  const _EntityConfig(this.label, this.icon, this.loader, this.columns);
}
