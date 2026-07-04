import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

class CategoryService {
  final SupabaseClient _client;

  CategoryService(this._client);

  Future<List<Category>> getAll({bool onlyActive = false}) {
    var query = _client.from('categories').select().order('name');
    if (onlyActive) query = query.eq('is_active', true);
    return query.then((data) => data.map((e) => Category.fromJson(e)).toList());
  }

  Future<Category> getById(String id) {
    return _client
        .from('categories')
        .select()
        .eq('id', id)
        .single()
        .then((data) => Category.fromJson(data));
  }

  Future<Category> create(Category category) {
    return _client
        .from('categories')
        .insert(category.toJson())
        .select()
        .single()
        .then((data) => Category.fromJson(data));
  }

  Future<Category> update(String id, Category category) {
    return _client
        .from('categories')
        .update(category.toJson())
        .eq('id', id)
        .select()
        .single()
        .then((data) => Category.fromJson(data));
  }

  Future<void> delete(String id) {
    return _client.from('categories').delete().eq('id', id);
  }
}
