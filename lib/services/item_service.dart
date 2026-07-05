import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/item.dart';

class ItemService {
  final SupabaseClient _client;

  ItemService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<Item>> getAll({bool onlyActive = false}) {
    var query = _client
        .from('items')
        .select('*, categories(name)')
        .order('name');
    if (onlyActive) query = query.filter('is_active', 'eq', true);
    return query.then((data) => data.map((e) => Item.fromJson(e)).toList());
  }

  Future<Item> getById(String id) {
    return _client
        .from('items')
        .select('*, categories(name)')
        .filter('id', 'eq', id)
        .single()
        .then((data) => Item.fromJson(data));
  }

  Future<Item> create(Item item) {
    return _client
        .from('items')
        .insert(item.toJson())
        .select()
        .single()
        .then((data) => Item.fromJson(data));
  }

  Future<Item> update(String id, Item item) {
    return _client
        .from('items')
        .update(item.toJson())
        .filter('id', 'eq', id)
        .select()
        .single()
        .then((data) => Item.fromJson(data));
  }

  Future<void> delete(String id) {
    return _client.from('items').delete().filter('id', 'eq', id);
  }
}
