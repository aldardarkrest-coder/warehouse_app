import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supplier.dart';

class SupplierService {
  final SupabaseClient _client;

  SupplierService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<Supplier>> getAll({bool onlyActive = false}) async {
    final data = await _client.from('suppliers').select().order('name');
    var list = data.map((e) => Supplier.fromJson(e)).toList();
    if (onlyActive) list = list.where((s) => s.isActive).toList();
    return list;
  }

  Future<Supplier> getById(String id) async {
    final data = await _client.from('suppliers').select();
    return Supplier.fromJson(data.firstWhere((r) => r['id'] == id));
  }

  Future<Supplier> create(Supplier supplier) async {
    final data = await _client
        .from('suppliers')
        .insert(supplier.toJson())
        .select()
        .single();
    return Supplier.fromJson(data);
  }

  Future<Supplier> update(String id, Supplier supplier) async {
    final data = await _client
        .from('suppliers')
        .update(supplier.toJson())
        .match({'id': id})
        .select()
        .single();
    return Supplier.fromJson(data);
  }

  Future<void> delete(String id) async {
    await _client.from('suppliers').delete().match({'id': id});
  }
}
