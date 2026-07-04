import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/item.dart';

class ItemService {
  final SupabaseClient _client;

  ItemService(this._client);

  Future<List<Item>> getAll({bool onlyActive = false}) {
    var query = _client
        .from('items')
        .select('*, categories(name)')
        .order('name');
    if (onlyActive) query = query.eq('is_active', true);
    return query.then((data) => data.map((e) => Item.fromJson(e)).toList());
  }

  Future<Item> getById(String id) {
    return _client
        .from('items')
        .select('*, categories(name)')
        .eq('id', id)
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
        .eq('id', id)
        .select()
        .single()
        .then((data) => Item.fromJson(data));
  }

  Future<void> delete(String id) {
    return _client.from('items').delete().eq('id', id);
  }

  Future<Item> getBySku(String sku) {
    return _client
        .from('items')
        .select()
        .eq('sku', sku)
        .maybeSingle()
        .then((data) => data != null ? Item.fromJson(data) : throw Exception('Item not found'));
  }
}
