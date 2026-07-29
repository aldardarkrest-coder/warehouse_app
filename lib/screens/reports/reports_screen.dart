import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as xl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
  final void Function(String)? onNavigate;
  const ReportsScreen({super.key, this.onNavigate});
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
  List<List<String>> get _rows => _filtered.map((i) => _cols.map((c) => c.get(_allData[i])).toList()).toList();

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
  String _val(dynamic item, _Col col) => col.get(item);

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingWidget(message: 'جاري تحميل البيانات...');
    if (_error != null) return AppErrorWidget(message: _error!, onRetry: _load);

    return Stack(
      children: [
        RefreshIndicator(
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
        ),
        _buildFab(),
      ],
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
          onChanged: (v) {
            if (v == null) return;
            setState(() { _current = v; });
            _load();
          },
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

  Widget _buildFab() {
    return Positioned(
      left: 16,
      bottom: 16,
      child: FloatingActionButton.extended(
        heroTag: 'export',
        backgroundColor: const Color(0xFF1A56DB),
        onPressed: _showExportMenu,
        icon: const Icon(Icons.file_download_rounded, color: Colors.white),
        label: Text('تصدير', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showExportMenu() {
    final count = _selectedIds.isNotEmpty ? _selectedIds.length : _allData.length;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              Text('تصدير ${_cfg.label} ($count)', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937))),
              const SizedBox(height: 16),
              _exportTile(Icons.table_chart_rounded, 'Excel (.xlsx)', const Color(0xFF10B981), _exportExcel),
              _exportTile(Icons.description_rounded, 'CSV (.csv)', const Color(0xFF3B82F6), _exportCsv),
              _exportTile(Icons.picture_as_pdf_rounded, 'PDF (.pdf)', const Color(0xFFEF4444), _exportPdf),
              _exportTile(Icons.print_rounded, 'طباعة', const Color(0xFF8B5CF6), _print),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exportTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.chevron_left_rounded, color: Color(0xFFD1D5DB)),
      onTap: () { Navigator.pop(context); onTap(); },
    );
  }

  List<dynamic> get _exportItems {
    if (_selectedIds.isNotEmpty) return _allData.where((i) => _selectedIds.contains(_idOf(i))).toList();
    return _allData;
  }

  List<List<String>> _exportRows(List<dynamic> items) {
    return items.map((item) => _cols.map((c) => c.get(item)).toList()).toList();
  }

  String _escapeCsv(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) return '"${v.replaceAll('"', '""')}"';
    return v;
  }

  Future<void> _exportCsv() async {
    final items = _exportItems;
    if (items.isEmpty) return;
    final rows = _exportRows(items);
    final buf = StringBuffer('\uFEFF');
    buf.writeln(_headers.map(_escapeCsv).join(','));
    for (final row in rows) {
      buf.writeln(row.map(_escapeCsv).join(','));
    }
    final file = File('${Directory.systemTemp.path}/${_cfg.label}.csv');
    await file.writeAsString(buf.toString(), encoding: utf8);
    await Printing.shareFile(bytes: await file.readAsBytes(), filename: '${_cfg.label}.csv');
  }

  Future<void> _exportExcel() async {
    final items = _exportItems;
    if (items.isEmpty) return;
    final rows = _exportRows(items);
    final excel = xl.Excel.createExcel();
    final sheet = excel[_cfg.label];
    sheet.appendRow(_headers.map((h) => xl.TextCellValue(h)).toList());
    for (final row in rows) {
      sheet.appendRow(row.map((c) => xl.TextCellValue(c)).toList());
    }
    final raw = excel.save();
    if (raw == null) return;
    await Printing.shareFile(bytes: Uint8List.fromList(raw), filename: '${_cfg.label}.xlsx');
  }

  Future<void> _exportPdf() async {
    final items = _exportItems;
    if (items.isEmpty) return;
    final rows = _exportRows(items);
    final font = await PdfGoogleFonts.cairo();
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Header(level: 0, child: pw.Text('تقرير ${_cfg.label}', style: pw.TextStyle(font: font, fontSize: 18))),
        pw.SizedBox(height: 4),
        pw.Text('تاريخ التقرير: ${DateFormat('yyyy/MM/dd').format(DateTime.now())} - إجمالي السجلات: ${items.length}',
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: _headers,
          data: rows,
          headerStyle: pw.TextStyle(font: font, fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          cellStyle: pw.TextStyle(font: font, fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue, borderRadius: pw.BorderRadius.all(pw.Radius.circular(2))),
          cellAlignments: Map.fromIterables(_headers, List.filled(_headers.length, pw.Align.center)),
          border: const pw.TableBorder(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
          headerHeight: 28,
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        ),
      ],
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: '${_cfg.label}.pdf');
  }

  Future<void> _print() async {
    final items = _exportItems;
    if (items.isEmpty) return;
    final rows = _exportRows(items);
    final font = await PdfGoogleFonts.cairo();
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Header(level: 0, child: pw.Text('تقرير ${_cfg.label}', style: pw.TextStyle(font: font, fontSize: 18))),
        pw.SizedBox(height: 4),
        pw.Text('تاريخ التقرير: ${DateFormat('yyyy/MM/dd').format(DateTime.now())}',
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: _headers,
          data: rows,
          headerStyle: pw.TextStyle(font: font, fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          cellStyle: pw.TextStyle(font: font, fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue, borderRadius: pw.BorderRadius.all(pw.Radius.circular(2))),
          cellAlignments: Map.fromIterables(_headers, List.filled(_headers.length, pw.Align.center)),
          border: const pw.TableBorder(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
          headerHeight: 28,
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        ),
      ],
    ));
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
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
