import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/warehouse.dart';

class WarehouseService {
  final SupabaseClient _client;

  WarehouseService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<Warehouse>> getAll({bool onlyActive = false}) {
    var query = _client.from('warehouses').select().order('name');
    if (onlyActive) query = query.match({'is_active': true});
    return query.then((data) => data.map((e) => Warehouse.fromJson(e)).toList());
  }

  Future<Warehouse> getById(String id) {
    return _client
        .from('warehouses')
        .select()
        .match({'id': id})
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
        .match({'id': id})
        .select()
        .single()
        .then((data) => Warehouse.fromJson(data));
  }

  Future<void> delete(String id) {
    return _client.from('warehouses').delete().match({'id': id});
  }
}
