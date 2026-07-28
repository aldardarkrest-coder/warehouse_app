import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/inventory_service.dart';
import '../../services/report_service.dart';
import '../../models/inventory_transaction.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class ReportsScreen extends StatefulWidget {
  final AuthService authService;
  const ReportsScreen({super.key, required this.authService});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _inventoryService = InventoryService();
  final _reportService = ReportService();
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _movementSummary;
  Map<String, dynamic>? _stockByWarehouse;
  List<Map<String, dynamic>> _movements = [];
  bool _isLoading = true;
  String? _error;
  String _typeFilter = 'all';
  String _searchQuery = '';
  int _selectedTab = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _inventoryService.getDashboardStats(),
        _reportService.getMovementSummary(),
        _reportService.getStockByWarehouse(),
        _reportService.getFilteredMovements(limit: 200),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>?;
          _movementSummary = results[1] as Map<String, dynamic>?;
          _stockByWarehouse = results[2] as Map<String, dynamic>?;
          _movements = results[3] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _filteredMovements {
    var list = _movements;
    if (_typeFilter != 'all') list = list.where((m) => m['transaction_type'] == _typeFilter).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((m) =>
        (m['transaction_type'] as String?)?.toString().toLowerCase().contains(q) == true ||
        (m['branches'] as Map?)?['name']?.toString().toLowerCase().contains(q) == true ||
        (m['profiles'] as Map?)?['full_name']?.toString().toLowerCase().contains(q) == true
      ).toList();
    }
    return list;
  }

  void _exportCsv() {
    final rows = StringBuffer();
    rows.writeln('التاريخ,نوع الحركة,الفرع,الحالة,بواسطة');
    for (final m in _filteredMovements) {
      final date = m['created_at']?.toString().substring(0, 10) ?? '';
      final txType = m['transaction_type'] as String? ?? '';
      final branch = (m['branches'] as Map?)?['name'] as String? ?? '';
      final status = m['status'] as String? ?? '';
      final by = (m['profiles'] as Map?)?['full_name'] as String? ?? '';
      rows.writeln('$date,$txType,$branch,$status,$by');
    }

    Clipboard.setData(ClipboardData(text: rows.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تم نسخ التقرير إلى الحافظة - يمكنك لصقه في Excel', style: GoogleFonts.cairo()),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingWidget(message: 'جاري تحميل التقارير...');
    if (_error != null) return AppErrorWidget(message: _error!, onRetry: _load);

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF1A56DB),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary row
          _buildSummaryRow(),
          const SizedBox(height: 20),
          // Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(children: [
              _tabBtn(0, 'الحركات'),
              _tabBtn(1, 'المخزون بالمستودعات'),
              _tabBtn(2, 'ملخص'),
            ]),
          ),
          const SizedBox(height: 16),
          if (_selectedTab == 0) _buildMovementsTab(),
          if (_selectedTab == 1) _buildWarehouseTab(),
          if (_selectedTab == 2) _buildSummaryTab(),
        ],
      ),
    );
  }

  Widget _tabBtn(int index, String label) {
    final selected = _selectedTab == index;
    return Expanded(
      child: Material(
        color: selected ? const Color(0xFF1A56DB).withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _selectedTab = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(label, textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: selected ? const Color(0xFF1A56DB) : const Color(0xFF9CA3AF),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    final totalItems = _stats?['total_items'] as int? ?? 0;
    final totalWarehouses = _stats?['total_warehouses'] as int? ?? 0;
    final lowStock = _stats?['low_stock_count'] as int? ?? 0;
    final totalMovements = _movementSummary?['total_movements'] as int? ?? 0;

    return Row(children: [
      _miniCard(Icons.inventory_2_rounded, '$totalItems', 'الأصناف', const Color(0xFF1A56DB)),
      const SizedBox(width: 8),
      _miniCard(Icons.warehouse_rounded, '$totalWarehouses', 'المستودعات', const Color(0xFF10B981)),
      const SizedBox(width: 8),
      _miniCard(Icons.warning_amber_rounded, '$lowStock', 'منخفض', lowStock > 0 ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF)),
      const SizedBox(width: 8),
      _miniCard(Icons.swap_horiz_rounded, '$totalMovements', 'الحركات', const Color(0xFF8B5CF6)),
    ]);
  }

  Widget _miniCard(IconData icon, String value, String label, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.cairo(fontSize: 9, color: const Color(0xFF9CA3AF)), textAlign: TextAlign.center),
      ]),
    ));
  }

  Widget _buildMovementsTab() {
    return Column(children: [
      // Filters
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(children: [
          Row(children: [
            Expanded(child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'بحث في الحركات...',
                hintStyle: GoogleFonts.cairo(color: const Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                filled: true,
                fillColor: const Color(0xFFF0F2F8),
              ),
            )),
            const SizedBox(width: 8),
            Material(
              color: const Color(0xFF1A56DB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _exportCsv,
                child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.file_download_rounded, color: Color(0xFF1A56DB), size: 20)),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          // Type filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filterChip('all', 'الكل'),
              const SizedBox(width: 6),
              _filterChip('purchase_receipt', 'استلام'),
              const SizedBox(width: 6),
              _filterChip('sales_issue', 'صرف'),
              const SizedBox(width: 6),
              _filterChip('transfer', 'تحويل'),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      // Table
      if (_filteredMovements.isEmpty)
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Center(child: Text('لا توجد حركات مطابقة', style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF)))),
        )
      else
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 40,
              columnSpacing: 16,
              headingTextStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 11, color: const Color(0xFF6B7280)),
              dataTextStyle: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF1F2937)),
              columns: const [
                DataColumn(label: Text('التاريخ')),
                DataColumn(label: Text('نوع الحركة')),
                DataColumn(label: Text('الفرع')),
                DataColumn(label: Text('الحالة')),
                DataColumn(label: Text('بواسطة')),
              ],
              rows: _filteredMovements.map((m) {
                final txTypeVal = m['transaction_type'] as String? ?? '';
                final txType = TransactionType.fromString(txTypeVal);
                final status = m['status'] as String? ?? '';
                final isPosted = status == 'posted';
                return DataRow(cells: [
                  DataCell(Text(m['created_at']?.toString().substring(0, 10) ?? '', style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF9CA3AF)))),
                  DataCell(Text(txType.displayName, style: GoogleFonts.cairo(fontWeight: FontWeight.w600))),
                  DataCell(Text((m['branches'] as Map?)?['name'] as String? ?? '')),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isPosted ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(isPosted ? 'مرحل' : 'مسودة', style: GoogleFonts.cairo(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: isPosted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    )),
                  )),
                  DataCell(Text((m['profiles'] as Map?)?['full_name'] as String? ?? '', style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF6B7280)))),
                ]);
              }).toList(),
            ),
          ),
        ),
    ]);
  }

  Widget _filterChip(String value, String label) {
    final selected = _typeFilter == value;
    return Material(
      color: selected ? const Color(0xFF1A56DB).withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _typeFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? const Color(0xFF1A56DB) : const Color(0xFFE5E7EB)),
          ),
          child: Text(label, style: GoogleFonts.cairo(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? const Color(0xFF1A56DB) : const Color(0xFF9CA3AF))),
        ),
      ),
    );
  }

  Widget _buildWarehouseTab() {
    final warehouses = (_stockByWarehouse?['warehouses'] as List?) ?? [];
    if (warehouses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Center(child: Text('لا توجد بيانات', style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF)))),
      );
    }
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
      clipBehavior: Clip.antiAlias,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 40,
        columnSpacing: 16,
        headingTextStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 11, color: const Color(0xFF6B7280)),
        dataTextStyle: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF1F2937)),
        columns: const [
          DataColumn(label: Text('المستودع')),
          DataColumn(label: Text('عدد الأصناف'), numeric: true),
          DataColumn(label: Text('إجمالي الكمية'), numeric: true),
        ],
        rows: warehouses.map((w) => DataRow(cells: [
          DataCell(Row(children: [
            Container(width: 24, height: 24, decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.warehouse_rounded, color: Color(0xFF10B981), size: 14)),
            const SizedBox(width: 8),
            Text(w['name'] as String, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          ])),
          DataCell(Text('${w['items']}')),
          DataCell(Text((w['total_qty'] as double).toStringAsFixed(0), style: GoogleFonts.cairo(fontWeight: FontWeight.w700))),
        ])).toList(),
      ),
    );
  }

  Widget _buildSummaryTab() {
    final ms = _movementSummary;
    if (ms == null) return const SizedBox();
    final totalIn = ms['total_in'] as double;
    final totalOut = ms['total_out'] as double;
    final countIn = ms['count_in'] as int;
    final countOut = ms['count_out'] as int;
    final countTransfer = ms['count_transfer'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(children: [
        _summaryRow('إدخال', totalIn, countIn, const Color(0xFF10B981)),
        const Divider(height: 24),
        _summaryRow('إخراج', totalOut, countOut, const Color(0xFFEF4444)),
        const Divider(height: 24),
        _summaryRow('تحويل', '-', countTransfer, const Color(0xFFF59E0B)),
      ]),
    );
  }

  Widget _summaryRow(String label, dynamic qty, int count, Color color) {
    return Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(label.substring(0, 1), style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: color, fontSize: 16)))),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14))),
      Text(qty is double ? qty.toStringAsFixed(0) : qty, style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
      const SizedBox(width: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text('$count', style: GoogleFonts.cairo(fontSize: 11, color: color, fontWeight: FontWeight.w600))),
    ]);
  }
}
