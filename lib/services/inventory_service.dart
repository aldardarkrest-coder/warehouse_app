import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_movement.dart';

class InventoryService {
  final SupabaseClient _client;

  InventoryService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<InventoryMovement>> getMovements({int limit = 50}) async {
    final data = await _client
        .from('inventory_movements')
        .select(
            '*, items(name), warehouses(name), profiles!inventory_movements_created_by_fkey(full_name)')
        .order('created_at', ascending: false)
        .limit(limit);
    return data.map((e) => InventoryMovement.fromJson(e)).toList();
  }

  Future<List<InventoryItem>> getStockLevels({String? warehouseId}) async {
    var data = await _client
        .from('inventory_items')
        .select('*, items(name, sku, min_stock_level), warehouses(name)')
        .order('items(name)');
    var list = data.map((e) => InventoryItem.fromJson(e)).toList();
    if (warehouseId != null) {
      list = list.where((item) => item.warehouseId == warehouseId).toList();
    }
    return list;
  }

  Future<List<InventoryItem>> getLowStock() async {
    final all = await _client
        .from('inventory_items')
        .select('*, items!inner(name, sku, min_stock_level), warehouses(name)')
        .order('items(name)')
        .then((data) => data.map((e) => InventoryItem.fromJson(e)).toList());
    return all.where((item) => item.quantity <= 0).toList();
  }

  Future<InventoryMovement> createMovement(InventoryMovement movement) async {
    final data = await _client
        .from('inventory_movements')
        .insert(movement.toJson())
        .select()
        .single();
    return InventoryMovement.fromJson(data);
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final totalItems = await _client.from('items').select('id');
    final totalWarehouses = await _client.from('warehouses').select('id');
    final recentMovements = await _client
        .from('inventory_movements')
        .select(
            '*, items(name), warehouses(name), profiles!inventory_movements_created_by_fkey(full_name)')
        .order('created_at', ascending: false)
        .limit(10)
        .then((data) => data.map((e) => InventoryMovement.fromJson(e)).toList());

    final allStock = await _client
        .from('inventory_items')
        .select('*, items!inner(name, sku, min_stock_level), warehouses(name)')
        .then((data) => data.map((e) => InventoryItem.fromJson(e)).toList());

    return {
      'total_items': (totalItems as List).length,
      'total_warehouses': (totalWarehouses as List).length,
      'recent_movements': recentMovements,
      'low_stock_count': allStock.where((s) => s.quantity <= 0).length,
    };
  }
}
