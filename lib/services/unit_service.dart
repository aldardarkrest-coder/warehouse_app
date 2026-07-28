import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/unit.dart';
import 'local_storage_service.dart';

class UnitService {
  final SupabaseClient _client;

  UnitService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<Unit>> getAll({bool onlyActive = false}) async {
    try {
      final data = await _client.from('units').select().order('name');
      await LocalStorageService.instance.cacheList('units', data);
      var list = data.map((e) => Unit.fromJson(e)).toList();
      if (onlyActive) list = list.where((u) => u.isActive).toList();
      return list;
    } catch (_) {
      final cached = await LocalStorageService.instance.getCachedList('units');
      var list = cached.map((e) => Unit.fromJson(e)).toList();
      if (onlyActive) list = list.where((u) => u.isActive).toList();
      return list;
    }
  }

  Future<Unit> getById(String id) async {
    try {
      final data = await _client.from('units').select();
      return Unit.fromJson(data.firstWhere((r) => r['id'] == id));
    } catch (_) {
      final cached = await LocalStorageService.instance.getCachedList('units');
      return Unit.fromJson(cached.firstWhere((r) => r['id'] == id));
    }
  }

  Future<Unit> create(Unit unit) async {
    try {
      final data = await _client
          .from('units')
          .insert(unit.toJson())
          .select()
          .single();
      await LocalStorageService.instance.cacheItem('units', data);
      return Unit.fromJson(data);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('units', 'INSERT', null, unit.toJson());
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }

  Future<Unit> update(String id, Unit unit) async {
    try {
      final data = await _client
          .from('units')
          .update(unit.toJson())
          .match({'id': id})
          .select()
          .single();
      await LocalStorageService.instance.cacheItem('units', data);
      return Unit.fromJson(data);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('units', 'UPDATE', id, unit.toJson());
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('units').delete().match({'id': id});
      await LocalStorageService.instance.removeCachedItem('units', id);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('units', 'DELETE', id, null);
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }
}
