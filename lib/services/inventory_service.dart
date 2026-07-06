import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_movement.dart';
import 'local_storage_service.dart';

class InventoryService {
  final SupabaseClient _client;

  InventoryService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<InventoryMovement>> getMovements({int limit = 50}) async {
    try {
      final data = await _client
          .from('inventory_movements')
          .select('*, items(name), warehouses(name)')
          .order('created_at', ascending: false)
          .limit(limit);
      await LocalStorageService.instance.cacheList('inventory_movements', data);
      final movements = data.map((e) => InventoryMovement.fromJson(e)).toList();
      await _enrichCreatorNames(movements);
      return movements;
    } catch (_) {
      final cached = await LocalStorageService.instance.getCachedList('inventory_movements');
      return cached.map((e) => InventoryMovement.fromJson(e)).toList();
    }
  }

  Future<List<InventoryItem>> getStockLevels({String? warehouseId}) async {
    try {
      var data = await _client
          .from('inventory_items')
          .select('*, items(name, sku, min_stock_level), warehouses(name)')
          .order('items(name)');
      await LocalStorageService.instance.cacheList('inventory_items', data);
      var list = data.map((e) => InventoryItem.fromJson(e)).toList();
      if (warehouseId != null) {
        list = list.where((item) => item.warehouseId == warehouseId).toList();
      }
      return list;
    } catch (_) {
      final cached = await LocalStorageService.instance.getCachedList('inventory_items');
      var list = cached.map((e) => InventoryItem.fromJson(e)).toList();
      if (warehouseId != null) {
        list = list.where((item) => item.warehouseId == warehouseId).toList();
      }
      return list;
    }
  }

  Future<List<InventoryItem>> getLowStock() async {
    final all = await getStockLevels();
    return all.where((item) => item.quantity <= 0).toList();
  }

  Future<InventoryMovement> createMovement(InventoryMovement movement) async {
    try {
      final data = await _client
          .from('inventory_movements')
          .insert(movement.toJson())
          .select()
          .single();
      await LocalStorageService.instance.cacheItem('inventory_movements', data);
      return InventoryMovement.fromJson(data);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('inventory_movements', 'INSERT', null, movement.toJson());
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    int totalItems = 0, totalWarehouses = 0, lowStockCount = 0;
    List<InventoryMovement> recentMovements = [];

    try {
      final itemsResp = await _client.from('items').select('id');
      final warehousesResp = await _client.from('warehouses').select('id');
      totalItems = (itemsResp as List).length;
      totalWarehouses = (warehousesResp as List).length;

      final recentData = await _client
          .from('inventory_movements')
          .select('*, items(name), warehouses(name)')
          .order('created_at', ascending: false)
          .limit(10);
      await LocalStorageService.instance.cacheList('inventory_movements', recentData);
      recentMovements = recentData.map((e) => InventoryMovement.fromJson(e)).toList();
      await _enrichCreatorNames(recentMovements);

      final allStock = await _client
          .from('inventory_items')
          .select('*, items!inner(name, sku, min_stock_level), warehouses(name)');
      await LocalStorageService.instance.cacheList('inventory_items', allStock);
      lowStockCount = allStock.where((s) => (s['quantity'] as num) <= 0).length;
    } catch (_) {
      final cachedMovements = await LocalStorageService.instance.getCachedList('inventory_movements');
      recentMovements = cachedMovements.map((e) => InventoryMovement.fromJson(e)).take(10).toList();

      final cachedStock = await LocalStorageService.instance.getCachedList('inventory_items');
      lowStockCount = cachedStock.where((s) => (s['quantity'] as num?) ?? 0 <= 0).length;
    }

    return {
      'total_items': totalItems,
      'total_warehouses': totalWarehouses,
      'recent_movements': recentMovements,
      'low_stock_count': lowStockCount,
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
