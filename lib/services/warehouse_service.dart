import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/warehouse.dart';

class WarehouseService {
  final SupabaseClient _client;

  WarehouseService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<Warehouse>> getAll({bool onlyActive = false}) {
    var query = _client.from('warehouses').select().order('name');
    if (onlyActive) query = query.filter('is_active', 'eq', true);
    return query.then((data) => data.map((e) => Warehouse.fromJson(e)).toList());
  }

  Future<Warehouse> getById(String id) {
    return _client
        .from('warehouses')
        .select()
        .filter('id', 'eq', id)
        .single()
        .then((data) => Warehouse.fromJson(data));
  }

  Future<Warehouse> create(Warehouse warehouse) {
    return _client
        .from('warehouses')
        .insert(warehouse.toJson())
        .select()
        .single()
        .then((data) => Warehouse.fromJson(data));
  }

  Future<Warehouse> update(String id, Warehouse warehouse) {
    return _client
        .from('warehouses')
        .update(warehouse.toJson())
        .filter('id', 'eq', id)
        .select()
        .single()
        .then((data) => Warehouse.fromJson(data));
  }

  Future<void> delete(String id) {
    return _client.from('warehouses').delete().filter('id', 'eq', id);
  }
}
