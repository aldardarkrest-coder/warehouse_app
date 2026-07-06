import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_movement.dart';

class InventoryService {
  final SupabaseClient _client;

  InventoryService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<InventoryMovement>> getMovements({int limit = 50}) async {
    final data = await _client
        .from('inventory_movements')
        .select('*, items(name), warehouses(name)')
        .order('created_at', ascending: false)
        .limit(limit);
    final movements = data.map((e) => InventoryMovement.fromJson(e)).toList();
    await _enrichCreatorNames(movements);
    return movements;
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
    final recentMovementsData = await _client
        .from('inventory_movements')
        .select('*, items(name), warehouses(name)')
        .order('created_at', ascending: false)
        .limit(10);
    final recentMovements = recentMovementsData.map((e) => InventoryMovement.fromJson(e)).toList();
    await _enrichCreatorNames(recentMovements);

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

  Future<void> _enrichCreatorNames(List<InventoryMovement> movements) async {
    final userIds = movements.map((m) => m.createdBy).toSet().toList();
    if (userIds.isEmpty) return;
    try {
      final profiles = await _client
          .from('profiles')
          .select('id, full_name')
          .filter('id', 'in', userIds);
      final nameMap = {for (final p in profiles) p['id'] as String: p['full_name'] as String};
      for (var i = 0; i < movements.length; i++) {
        final name = nameMap[movements[i].createdBy];
        if (name != null) {
          movements[i] = InventoryMovement(
            id: movements[i].id,
            itemId: movements[i].itemId,
            itemName: movements[i].itemName,
            warehouseId: movements[i].warehouseId,
            warehouseName: movements[i].warehouseName,
            type: movements[i].type,
            quantity: movements[i].quantity,
            referenceType: movements[i].referenceType,
            referenceId: movements[i].referenceId,
            notes: movements[i].notes,
            createdBy: movements[i].createdBy,
            createdByName: name,
            createdAt: movements[i].createdAt,
          );
        }
      }
    } catch (_) {}
  }
}
