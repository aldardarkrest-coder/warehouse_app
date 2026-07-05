import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/item.dart';

class ItemService {
  final SupabaseClient _client;

  ItemService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<Item>> getAll({bool onlyActive = false}) async {
    final data = await _client
        .from('items')
        .select('*, categories(name)')
        .order('name');
    var list = data.map((e) => Item.fromJson(e)).toList();
    if (onlyActive) list = list.where((i) => i.isActive).toList();
    return list;
  }

  Future<Item> getById(String id) async {
    final data = await _client
        .from('items')
        .select('*, categories(name)');
    return Item.fromJson(data.firstWhere((r) => r['id'] == id));
  }

  Future<Item> create(Item item) async {
    final data = await _client
        .from('items')
        .insert(item.toJson())
        .select()
        .single();
    return Item.fromJson(data);
  }

  Future<Item> update(String id, Item item) async {
    final data = await _client
        .from('items')
        .update(item.toJson())
        .match({'id': id})
        .select()
        .single();
    return Item.fromJson(data);
  }

  Future<void> delete(String id) async {
    await _client.from('items').delete().match({'id': id});
  }
}
