import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

class CategoryService {
  final SupabaseClient _client;

  CategoryService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  Future<List<Category>> getAll({bool onlyActive = false}) async {
    final data = await _client.from('categories').select().order('name');
    var list = data.map((e) => Category.fromJson(e)).toList();
    if (onlyActive) list = list.where((c) => c.isActive).toList();
    return list;
  }

  Future<Category> getById(String id) async {
    final data = await _client.from('categories').select();
    return Category.fromJson(data.firstWhere((r) => r['id'] == id));
  }

  Future<Category> create(Category category) async {
    final data = await _client
        .from('categories')
        .insert(category.toJson())
        .select()
        .single();
    return Category.fromJson(data);
  }

  Future<Category> update(String id, Category category) async {
    final data = await _client
        .from('categories')
        .update(category.toJson())
        .match({'id': id})
        .select()
        .single();
    return Category.fromJson(data);
  }

  Future<void> delete(String id) async {
    await _client.from('categories').delete().match({'id': id});
  }
}
