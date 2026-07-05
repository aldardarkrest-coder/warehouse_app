import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';

class CustomerService {
  final SupabaseClient _client;

  CustomerService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<Customer>> getAll({bool onlyActive = false}) {
    var query = _client.from('customers').select().order('name');
    if (onlyActive) query = query.match({'is_active': true});
    return query.then((data) => data.map((e) => Customer.fromJson(e)).toList());
  }

  Future<Customer> getById(String id) {
    return _client
        .from('customers')
        .select()
        .match({'id': id})
        .single()
        .then((data) => Customer.fromJson(data));
  }

  Future<Customer> create(Customer customer) {
    return _client
        .from('customers')
        .insert(customer.toJson())
        .select()
        .single()
        .then((data) => Customer.fromJson(data));
  }

  Future<Customer> update(String id, Customer customer) {
    return _client
        .from('customers')
        .update(customer.toJson())
        .match({'id': id})
        .select()
        .single()
        .then((data) => Customer.fromJson(data));
  }

  Future<void> delete(String id) {
    return _client.from('customers').delete().match({'id': id});
  }
}
