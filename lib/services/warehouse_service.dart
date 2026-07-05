import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/warehouse.dart';

class WarehouseService {
  final SupabaseClient _client;

  WarehouseService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<Warehouse>> getAll({bool onlyActive = false}) async {
    final data = await _client.from('warehouses').select().order('name');
    var list = data.map((e) => Warehouse.fromJson(e)).toList();
    if (onlyActive) list = list.where((w) => w.isActive).toList();
    return list;
  }

  Future<Warehouse> getById(String id) async {
    final data = await _client.from('warehouses').select();
    return Warehouse.fromJson(data.firstWhere((r) => r['id'] == id));
  }

  Future<Warehouse> create(Warehouse warehouse) async {
    final data = await _client
        .from('warehouses')
        .insert(warehouse.toJson())
        .select()
        .single();
    return Warehouse.fromJson(data);
  }

  Future<Warehouse> update(String id, Warehouse warehouse) async {
    final data = await _client
        .from('warehouses')
        .update(warehouse.toJson())
        .match({'id': id})
        .select()
        .single();
    return Warehouse.fromJson(data);
  }

  Future<void> delete(String id) async {
    await _client.from('warehouses').delete().match({'id': id});
  }
}
