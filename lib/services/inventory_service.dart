import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_movement.dart';

class InventoryService {
  final SupabaseClient _client;

  InventoryService(this._client);

  Future<List<InventoryMovement>> getMovements({int limit = 50}) {
    return _client
        .from('inventory_movements')
        .select('*, items(name), warehouses(name), profiles!inventory_movements_created_by_fkey(full_name)')
        .order('created_at', ascending: false)
        .limit(limit)
        .then((data) => data.map((e) => InventoryMovement.fromJson(e)).toList());
  }

  Future<List<InventoryItem>> getStockLevels({String? warehouseId}) {
    var query = _client
        .from('inventory_items')
        .select('*, items(name, sku, min_stock_level), warehouses(name)')
        .order('items(name)');
    if (warehouseId != null) query = query.eq('warehouse_id', warehouseId);
    return query.then((data) => data.map((e) => InventoryItem.fromJson(e)).toList());
  }

  Future<List<InventoryItem>> getLowStock() {
    return _client
        .from('inventory_items')
        .select('*, items!inner(name, sku, min_stock_level), warehouses(name)')
        .lte('quantity', 0)
        .order('items(name)')
        .then((data) => data.map((e) => InventoryItem.fromJson(e)).toList());
  }

  Future<InventoryMovement> createMovement(InventoryMovement movement) {
    return _client
        .from('inventory_movements')
        .insert(movement.toJson())
        .select()
        .single()
        .then((data) => InventoryMovement.fromJson(data));
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final totalItems = await _client.from('items').count('exact', filter: null);
    final totalWarehouses = await _client.from('warehouses').count('exact', filter: null);
    final recentMovements = await _client
        .from('inventory_movements')
        .select('*, items(name), warehouses(name), profiles!inventory_movements_created_by_fkey(full_name)')
        .order('created_at', ascending: false)
        .limit(10)
        .then((data) => data.map((e) => InventoryMovement.fromJson(e)).toList());

    final lowStockItems = await _client
        .from('inventory_items')
        .select('*, items!inner(name, sku, min_stock_level), warehouses(name)')
        .lte('quantity', 0)
        .then((data) => data.map((e) => InventoryItem.fromJson(e)).toList());

    return {
      'total_items': totalItems,
      'total_warehouses': totalWarehouses,
      'recent_movements': recentMovements,
      'low_stock_count': lowStockItems.length,
    };
  }
}
