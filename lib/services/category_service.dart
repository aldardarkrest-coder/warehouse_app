import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import 'local_storage_service.dart';

class CategoryService {
  final SupabaseClient _client;

  CategoryService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<Category>> getAll({bool onlyActive = false}) async {
    try {
      final data = await _client.from('categories').select().order('name');
      await LocalStorageService.instance.cacheList('categories', data);
      var list = data.map((e) => Category.fromJson(e)).toList();
      if (onlyActive) list = list.where((c) => c.isActive).toList();
      return list;
    } catch (_) {
      final cached = await LocalStorageService.instance.getCachedList('categories');
      var list = cached.map((e) => Category.fromJson(e)).toList();
      if (onlyActive) list = list.where((c) => c.isActive).toList();
      return list;
    }
  }

  Future<Category> getById(String id) async {
    try {
      final data = await _client.from('categories').select();
      return Category.fromJson(data.firstWhere((r) => r['id'] == id));
    } catch (_) {
      final cached = await LocalStorageService.instance.getCachedList('categories');
      return Category.fromJson(cached.firstWhere((r) => r['id'] == id));
    }
  }

  Future<Category> create(Category category) async {
    try {
      final data = await _client
          .from('categories')
          .insert(category.toJson())
          .select()
          .single();
      await LocalStorageService.instance.cacheItem('categories', data);
      return Category.fromJson(data);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('categories', 'INSERT', null, category.toJson());
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }

  Future<Category> update(String id, Category category) async {
    try {
      final data = await _client
          .from('categories')
          .update(category.toJson())
          .match({'id': id})
          .select()
          .single();
      await LocalStorageService.instance.cacheItem('categories', data);
      return Category.fromJson(data);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('categories', 'UPDATE', id, category.toJson());
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('categories').delete().match({'id': id});
      await LocalStorageService.instance.removeCachedItem('categories', id);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('categories', 'DELETE', id, null);
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }
}
