import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';
import 'local_storage_service.dart';

class CustomerService {
  final SupabaseClient _client;

  CustomerService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<Customer>> getAll({bool onlyActive = false}) async {
    try {
      final data = await _client.from('customers').select().order('name');
      await LocalStorageService.instance.cacheList('customers', data);
      var list = data.map((e) => Customer.fromJson(e)).toList();
      if (onlyActive) list = list.where((c) => c.isActive).toList();
      return list;
    } catch (_) {
      final cached = await LocalStorageService.instance.getCachedList('customers');
      var list = cached.map((e) => Customer.fromJson(e)).toList();
      if (onlyActive) list = list.where((c) => c.isActive).toList();
      return list;
    }
  }

  Future<Customer> getById(String id) async {
    try {
      final data = await _client.from('customers').select();
      return Customer.fromJson(data.firstWhere((r) => r['id'] == id));
    } catch (_) {
      final cached = await LocalStorageService.instance.getCachedList('customers');
      return Customer.fromJson(cached.firstWhere((r) => r['id'] == id));
    }
  }

  Future<Customer> create(Customer customer) async {
    try {
      final data = await _client
          .from('customers')
          .insert(customer.toJson())
          .select()
          .single();
      await LocalStorageService.instance.cacheItem('customers', data);
      return Customer.fromJson(data);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('customers', 'INSERT', null, customer.toJson());
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }

  Future<Customer> update(String id, Customer customer) async {
    try {
      final data = await _client
          .from('customers')
          .update(customer.toJson())
          .match({'id': id})
          .select()
          .single();
      await LocalStorageService.instance.cacheItem('customers', data);
      return Customer.fromJson(data);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('customers', 'UPDATE', id, customer.toJson());
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('customers').delete().match({'id': id});
      await LocalStorageService.instance.removeCachedItem('customers', id);
    } catch (_) {
      await LocalStorageService.instance.queueOperation('customers', 'DELETE', id, null);
      throw Exception(LocalStorageService.instance.errorOffline);
    }
  }
}
