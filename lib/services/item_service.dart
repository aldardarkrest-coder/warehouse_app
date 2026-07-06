import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/item.dart';
import 'local_storage_service.dart';

class ItemService {
  final SupabaseClient _client;

  ItemService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<Item>> getAll({bool onlyActive = false}) async {
    try {
      final data = await _client
          .from('items')
          .select('*, categories(name)')
          .order('name');
      await LocalStorageService.instance.cacheList('items', data);
      var list = data.map((e) => Item.fromJson(e)).toList();
      if (onlyActive) list = list.where((i) => i.isActive).toList();
      return list;
    } catch (_) {
      final cached = await LocalStorageService.instance.getCachedList('items');
      var list = cached.map((e) => Item.fromJson(e)).toList();
      if (onlyActive) list = list.where((i) => i.isActive).toList();
      return list;
    }
  }

  Future<Item> getById(String id) async {
    try {
      final data = await _client
          .from('items')
          .select('*, categories(name)');
      return Item.fromJson(data.firstWhere((r) => r['id'] == id));
    } catch (_) {
      final cached = await LocalStorageService.instance.getCachedList('items');
      return Item.fromJson(cached.firstWhere((r) => r['id'] == id));
    }
  }

  Future<Item> create(Item item) async {
    try {
      final data = await _client
          .from('items')
          .insert(item.toJson())
          .select()
          .single();
      await LocalStorageService.instance.cacheItem('items', data);
      return Item.fromJson(data);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('items', 'INSERT', null, item.toJson());
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }

  Future<Item> update(String id, Item item) async {
    try {
      final data = await _client
          .from('items')
          .update(item.toJson())
          .match({'id': id})
          .select()
          .single();
      await LocalStorageService.instance.cacheItem('items', data);
      return Item.fromJson(data);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('items', 'UPDATE', id, item.toJson());
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('items').delete().match({'id': id});
      await LocalStorageService.instance.removeCachedItem('items', id);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('items', 'DELETE', id, null);
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }
}
