import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supplier.dart';

class SupplierService {
  final SupabaseClient _client;

  SupplierService(this._client);

  Future<List<Supplier>> getAll({bool onlyActive = false}) {
    var query = _client.from('suppliers').select().order('name');
    if (onlyActive) query = query.eq('is_active', true);
    return query.then((data) => data.map((e) => Supplier.fromJson(e)).toList());
  }

  Future<Supplier> getById(String id) {
    return _client
        .from('suppliers')
        .select()
        .eq('id', id)
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
        .eq('id', id)
        .select()
        .single()
        .then((data) => Supplier.fromJson(data));
  }

  Future<void> delete(String id) {
    return _client.from('suppliers').delete().eq('id', id);
  }
}
