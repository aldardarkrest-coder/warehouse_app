import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supplier.dart';

class SupplierService {
  final SupabaseClient _client;

  SupplierService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<Supplier>> getAll({bool onlyActive = false}) {
    var query = _client.from('suppliers').select().order('name');
    if (onlyActive) query = query.match({'is_active': true});
    return query.then((data) => data.map((e) => Supplier.fromJson(e)).toList());
  }

  Future<Supplier> getById(String id) {
    return _client
        .from('suppliers')
        .select()
        .match({'id': id})
        .single()
        .then((data) => Supplier.fromJson(data));
  }

  Future<Supplier> create(Supplier supplier) {
    return _client
        .from('suppliers')
        .insert(supplier.toJson())
        .select()
        .single()
        .then((data) => Supplier.fromJson(data));
  }

  Future<Supplier> update(String id, Supplier supplier) {
    return _client
        .from('suppliers')
        .update(supplier.toJson())
        .match({'id': id})
        .select()
        .single()
        .then((data) => Supplier.fromJson(data));
  }

  Future<void> delete(String id) {
    return _client.from('suppliers').delete().match({'id': id});
  }
}
