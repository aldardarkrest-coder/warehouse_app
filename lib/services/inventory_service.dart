import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_transaction.dart';
import '../models/inventory_transaction_line.dart';
import 'local_storage_service.dart';

class InventoryService {
  final SupabaseClient _client;

  InventoryService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<InventoryTransaction>> getTransactions({int limit = 50}) async {
    try {
      final data = await _client
          .from('inventory_transactions')
          .select('*, branches(name), source_warehouses:warehouses!source_warehouse_id(name), destination_warehouses:warehouses!destination_warehouse_id(name), suppliers(name), customers(name), profiles!created_by(full_name)')
          .order('created_at', ascending: false)
          .limit(limit);
      await LocalStorageService.instance.cacheList('inventory_transactions', data);
      return data.map((e) => InventoryTransaction.fromJson(e)).toList();
    } catch (_) {
      final cached = await LocalStorageService.instance.getCachedList('inventory_transactions');
      return cached.map((e) => InventoryTransaction.fromJson(e)).toList();
    }
  }

  Future<InventoryTransaction> createTransaction(InventoryTransaction tx) async {
    try {
      final data = await _client
          .from('inventory_transactions')
          .insert(tx.toJson())
          .select()
          .single();
      await LocalStorageService.instance.cacheItem('inventory_transactions', data);
      return InventoryTransaction.fromJson(data);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('inventory_transactions', 'INSERT', null, tx.toJson());
      rethrow;
    }
  }

  Future<void> createTransactionLine(InventoryTransactionLine line) async {
    try {
      await _client.from('inventory_transaction_lines').insert(line.toJson());
    } catch (_) {
      await LocalStorageService.instance.queueOperation('inventory_transaction_lines', 'INSERT', null, line.toJson());
      rethrow;
    }
  }

  Future<void> postTransaction(String transactionId) async {
    try {
      await _client.rpc('post_inventory_transaction', params: {'p_transaction_id': transactionId});
    } catch (_) {
      rethrow;
    }
  }

  Future<void> cancelTransaction(String transactionId, String reason) async {
    try {
      await _client.rpc('cancel_inventory_transaction', params: {
        'p_transaction_id': transactionId,
        'p_reason': reason,
      });
    } catch (_) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBalances({String? warehouseId}) async {
    try {
      var data = await _client
          .from('inventory_balances')
          .select('*, items!inner(name, sku, min_stock_level), warehouses!inner(name)')
          .order('items(name)');
      var list = (data as List).cast<Map<String, dynamic>>();
      if (warehouseId != null) {
        list = list.where((r) => r['warehouse_id'] == warehouseId).toList();
      }
      await LocalStorageService.instance.cacheList('inventory_balances', data);
      return list;
    } catch (_) {
      final cached = await LocalStorageService.instance.getCachedList('inventory_balances');
      var list = cached.cast<Map<String, dynamic>>();
      if (warehouseId != null) {
        list = list.where((r) => r['warehouse_id'] == warehouseId).toList();
      }
      return list;
    }
  }

  Future<List<Map<String, dynamic>>> getLowStock() async {
    final all = await getBalances();
    return all.where((r) => (r['quantity_base'] as num?)?.toDouble() ?? 0 <= 0).toList();
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    int totalItems = 0, totalWarehouses = 0, lowStockCount = 0;
    List<InventoryTransaction> recentTransactions = [];

    try {
      final itemsResp = await _client.from('items').select('id');
      totalItems = (itemsResp as List).length;

      final wResp = await _client.from('warehouses').select('id');
      totalWarehouses = (wResp as List).length;

      final recentData = await _client
          .from('inventory_transactions')
          .select('*, branches(name), source_warehouses:warehouses!source_warehouse_id(name), destination_warehouses:warehouses!destination_warehouse_id(name), suppliers(name), customers(name), profiles!created_by(full_name)')
          .order('created_at', ascending: false)
          .limit(10);
      await LocalStorageService.instance.cacheList('inventory_transactions', recentData);
      recentTransactions = recentData.map((e) => InventoryTransaction.fromJson(e)).toList();

      final allStock = await _client
          .from('inventory_balances')
          .select('quantity_base');
      lowStockCount = allStock.where((s) => (s['quantity_base'] as num?)?.toDouble() ?? 0 <= 0).length;
    } catch (_) {
      final cachedTx = await LocalStorageService.instance.getCachedList('inventory_transactions');
      recentTransactions = cachedTx.map((e) => InventoryTransaction.fromJson(e)).take(10).toList();

      final cachedBal = await LocalStorageService.instance.getCachedList('inventory_balances');
      lowStockCount = cachedBal.where((s) => ((s['quantity_base'] as num?)?.toDouble() ?? 0) <= 0).length;
    }

    return {
      'total_items': totalItems,
      'total_warehouses': totalWarehouses,
      'recent_transactions': recentTransactions,
      'low_stock_count': lowStockCount,
    };
  }
}
