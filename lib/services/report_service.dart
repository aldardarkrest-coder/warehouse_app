import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final SupabaseClient _client;

  ReportService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<Map<String, dynamic>> getMovementSummary() async {
    try {
      final data = await _client
          .from('inventory_transactions')
          .select('transaction_type, status, created_at')
          .order('created_at', ascending: false);

      final movs = data as List;
      final posted = movs.where((m) => m['status'] == 'posted');
      final countIn = posted.where((m) => m['transaction_type'] == 'purchase_receipt' || m['transaction_type'] == 'opening_balance' || m['transaction_type'] == 'adjustment_in' || m['transaction_type'] == 'customer_return').length;
      final countOut = posted.where((m) => m['transaction_type'] == 'sales_issue' || m['transaction_type'] == 'adjustment_out' || m['transaction_type'] == 'supplier_return').length;
      final countTransfer = posted.where((m) => m['transaction_type'] == 'transfer').length;

      return {
        'total_in': 0.0,
        'total_out': 0.0,
        'count_in': countIn,
        'count_out': countOut,
        'count_transfer': countTransfer,
        'total_movements': movs.length,
      };
    } catch (_) {
      return {
        'total_in': 0.0, 'total_out': 0.0,
        'count_in': 0, 'count_out': 0, 'count_transfer': 0,
        'total_movements': 0,
      };
    }
  }

  Future<Map<String, dynamic>> getStockByWarehouse() async {
    try {
      final data = await _client
          .from('inventory_balances')
          .select('*, items(name), warehouses(name)');
      final groups = <String, Map<String, dynamic>>{};
      for (final row in data) {
        final wName = (row['warehouses'] as Map?)?['name'] as String? ?? 'غير معروف';
        if (!groups.containsKey(wName)) {
          groups[wName] = {'name': wName, 'items': 0, 'total_qty': 0.0};
        }
        groups[wName]!['items'] = (groups[wName]!['items'] as int) + 1;
        groups[wName]!['total_qty'] = (groups[wName]!['total_qty'] as double) + ((row['quantity_base'] as num?)?.toDouble() ?? 0);
      }
      return {'warehouses': groups.values.toList()};
    } catch (_) {
      return {'warehouses': <Map<String, dynamic>>[]};
    }
  }

  Future<List<Map<String, dynamic>>> getFilteredMovements({
    String? type,
    DateTime? from,
    DateTime? to,
    int limit = 200,
    int offset = 0,
  }) async {
    try {
      final data = await _client
          .from('inventory_transactions')
          .select('*, branches(name), source_warehouses:warehouses!source_warehouse_id(name), destination_warehouses:warehouses!destination_warehouse_id(name), suppliers(name), customers(name), profiles!created_by(full_name)')
          .order('created_at', ascending: false);

      var list = (data as List).cast<Map<String, dynamic>>();
      if (type != null) { list = list.where((m) => m['transaction_type'] == type).toList(); }
      if (from != null) { list = list.where((m) {
        final d = DateTime.tryParse(m['created_at']?.toString() ?? '');
        return d != null && d.isAfter(from);
      }).toList(); }
      if (to != null) { list = list.where((m) {
        final d = DateTime.tryParse(m['created_at']?.toString() ?? '');
        return d != null && !d.isAfter(to);
      }).toList(); }

      return list.skip(offset).take(limit).toList();
    } catch (_) {
      return [];
    }
  }
}
