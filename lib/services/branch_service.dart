import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/branch.dart';
import 'local_storage_service.dart';

class BranchService {
  final SupabaseClient _client;

  BranchService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<Branch>> getAll({bool onlyActive = false}) async {
    try {
      final data = await _client.from('branches').select().order('name');
      await LocalStorageService.instance.cacheList('branches', data);
      var list = data.map((e) => Branch.fromJson(e)).toList();
      if (onlyActive) list = list.where((b) => b.isActive).toList();
      return list;
    } catch (_) {
      final cached = await LocalStorageService.instance.getCachedList('branches');
      var list = cached.map((e) => Branch.fromJson(e)).toList();
      if (onlyActive) list = list.where((b) => b.isActive).toList();
      return list;
    }
  }

  Future<Branch> getById(String id) async {
    try {
      final data = await _client.from('branches').select();
      return Branch.fromJson(data.firstWhere((r) => r['id'] == id));
    } catch (_) {
      final cached = await LocalStorageService.instance.getCachedList('branches');
      return Branch.fromJson(cached.firstWhere((r) => r['id'] == id));
    }
  }

  Future<Branch> create(Branch branch) async {
    try {
      final data = await _client
          .from('branches')
          .insert(branch.toJson())
          .select()
          .single();
      await LocalStorageService.instance.cacheItem('branches', data);
      return Branch.fromJson(data);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('branches', 'INSERT', null, branch.toJson());
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }

  Future<Branch> update(String id, Branch branch) async {
    try {
      final data = await _client
          .from('branches')
          .update(branch.toJson())
          .match({'id': id})
          .select()
          .single();
      await LocalStorageService.instance.cacheItem('branches', data);
      return Branch.fromJson(data);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('branches', 'UPDATE', id, branch.toJson());
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('branches').delete().match({'id': id});
      await LocalStorageService.instance.removeCachedItem('branches', id);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('branches', 'DELETE', id, null);
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }
}
