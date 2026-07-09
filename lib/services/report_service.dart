import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final SupabaseClient _client;

  ReportService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<Map<String, dynamic>> getMovementSummary() async {
    try {
      final data = await _client
          .from('inventory_movements')
          .select('type, quantity, created_at')
          .order('created_at', ascending: false);

      final movs = data as List;
      final totalIn = movs.where((m) => m['type'] == 'in').fold<num>(0, (s, m) => s + (m['quantity'] as num));
      final totalOut = movs.where((m) => m['type'] == 'out').fold<num>(0, (s, m) => s + (m['quantity'] as num));
      final countIn = movs.where((m) => m['type'] == 'in').length;
      final countOut = movs.where((m) => m['type'] == 'out').length;
      final countTransfer = movs.where((m) => m['type'] == 'transfer').length;

      return {
        'total_in': totalIn.toDouble(),
        'total_out': totalOut.toDouble(),
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
          .from('inventory_items')
          .select('*, items(name), warehouses(name)');
      final groups = <String, Map<String, dynamic>>{};
      for (final row in data) {
        final wName = (row['warehouses'] as Map?)?['name'] as String? ?? 'غير معروف';
        if (!groups.containsKey(wName)) {
          groups[wName] = {'name': wName, 'items': 0, 'total_qty': 0.0};
        }
        groups[wName]!['items'] = (groups[wName]!['items'] as int) + 1;
        groups[wName]!['total_qty'] = (groups[wName]!['total_qty'] as double) + ((row['quantity'] as num?)?.toDouble() ?? 0);
      }
      return {'warehouses': groups.values.toList()};
    } catch (_) {
      return {'warehouses': <Map<String, dynamic>>[]};
    }
  }
}
