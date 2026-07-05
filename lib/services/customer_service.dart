import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';

class CustomerService {
  final SupabaseClient _client;

  CustomerService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<Customer>> getAll({bool onlyActive = false}) async {
    final data = await _client.from('customers').select().order('name');
    var list = data.map((e) => Customer.fromJson(e)).toList();
    if (onlyActive) list = list.where((c) => c.isActive).toList();
    return list;
  }

  Future<Customer> getById(String id) async {
    final data = await _client.from('customers').select();
    return Customer.fromJson(data.firstWhere((r) => r['id'] == id));
  }

  Future<Customer> create(Customer customer) async {
    final data = await _client
        .from('customers')
        .insert(customer.toJson())
        .select()
        .single();
    return Customer.fromJson(data);
  }

  Future<Customer> update(String id, Customer customer) async {
    final data = await _client
        .from('customers')
        .update(customer.toJson())
        .match({'id': id})
        .select()
        .single();
    return Customer.fromJson(data);
  }

  Future<void> delete(String id) async {
    await _client.from('customers').delete().match({'id': id});
  }
}
