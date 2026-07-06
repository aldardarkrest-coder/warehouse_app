import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/warehouse.dart';
import 'local_storage_service.dart';

class WarehouseService {
  final SupabaseClient _client;

  WarehouseService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<Warehouse>> getAll({bool onlyActive = false}) async {
    try {
      final data = await _client.from('warehouses').select().order('name');
      await LocalStorageService.instance.cacheList('warehouses', data);
      var list = data.map((e) => Warehouse.fromJson(e)).toList();
      if (onlyActive) list = list.where((w) => w.isActive).toList();
      return list;
    } catch (_) {
      final cached = await LocalStorageService.instance.getCachedList('warehouses');
      var list = cached.map((e) => Warehouse.fromJson(e)).toList();
      if (onlyActive) list = list.where((w) => w.isActive).toList();
      return list;
    }
  }

  Future<Warehouse> getById(String id) async {
    try {
      final data = await _client.from('warehouses').select();
      return Warehouse.fromJson(data.firstWhere((r) => r['id'] == id));
    } catch (_) {
      final cached = await LocalStorageService.instance.getCachedList('warehouses');
      return Warehouse.fromJson(cached.firstWhere((r) => r['id'] == id));
    }
  }

  Future<Warehouse> create(Warehouse warehouse) async {
    try {
      final data = await _client
          .from('warehouses')
          .insert(warehouse.toJson())
          .select()
          .single();
      await LocalStorageService.instance.cacheItem('warehouses', data);
      return Warehouse.fromJson(data);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('warehouses', 'INSERT', null, warehouse.toJson());
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }

  Future<Warehouse> update(String id, Warehouse warehouse) async {
    try {
      final data = await _client
          .from('warehouses')
          .update(warehouse.toJson())
          .match({'id': id})
          .select()
          .single();
      await LocalStorageService.instance.cacheItem('warehouses', data);
      return Warehouse.fromJson(data);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('warehouses', 'UPDATE', id, warehouse.toJson());
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('warehouses').delete().match({'id': id});
      await LocalStorageService.instance.removeCachedItem('warehouses', id);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('warehouses', 'DELETE', id, null);
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }
}
