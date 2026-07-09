import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supplier.dart';
import 'local_storage_service.dart';

class SupplierService {
  final SupabaseClient _client;

  SupplierService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<Supplier>> getAll({bool onlyActive = false}) async {
    try {
      final data = await _client.from('suppliers').select().order('name');
      await LocalStorageService.instance.cacheList('suppliers', data);
      var list = data.map((e) => Supplier.fromJson(e)).toList();
      if (onlyActive) list = list.where((s) => s.isActive).toList();
      return list;
    } catch (_) {
      final cached = await LocalStorageService.instance.getCachedList('suppliers');
      var list = cached.map((e) => Supplier.fromJson(e)).toList();
      if (onlyActive) list = list.where((s) => s.isActive).toList();
      return list;
    }
  }

  Future<Supplier> getById(String id) async {
    try {
      final data = await _client.from('suppliers').select();
      return Supplier.fromJson(data.firstWhere((r) => r['id'] == id));
    } catch (_) {
      final cached = await LocalStorageService.instance.getCachedList('suppliers');
      return Supplier.fromJson(cached.firstWhere((r) => r['id'] == id));
    }
  }

  Future<Supplier> create(Supplier supplier) async {
    try {
      final data = await _client
          .from('suppliers')
          .insert(supplier.toJson())
          .select()
          .single();
      await LocalStorageService.instance.cacheItem('suppliers', data);
      return Supplier.fromJson(data);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('suppliers', 'INSERT', null, supplier.toJson());
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }

  Future<Supplier> update(String id, Supplier supplier) async {
    try {
      final data = await _client
          .from('suppliers')
          .update(supplier.toJson())
          .match({'id': id})
          .select()
          .single();
      await LocalStorageService.instance.cacheItem('suppliers', data);
      return Supplier.fromJson(data);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('suppliers', 'UPDATE', id, supplier.toJson());
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('suppliers').delete().match({'id': id});
      await LocalStorageService.instance.removeCachedItem('suppliers', id);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('suppliers', 'DELETE', id, null);
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }
}
