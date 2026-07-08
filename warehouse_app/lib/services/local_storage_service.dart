import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalStorageService {
  static final LocalStorageService instance = LocalStorageService._();
  LocalStorageService._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'warehouse_cache.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cache (
            table_name TEXT NOT NULL,
            record_id TEXT NOT NULL,
            data TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            PRIMARY KEY (table_name, record_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            table_name TEXT NOT NULL,
            operation TEXT NOT NULL,
            record_id TEXT,
            data TEXT,
            created_at TEXT NOT NULL,
            retries INTEGER DEFAULT 0
          )
        ''');
        await db.execute('CREATE INDEX idx_cache_table ON cache(table_name)');
        await db.execute('CREATE INDEX idx_queue_created ON sync_queue(created_at)');
      },
      version: 1,
    );
    return _db!;
  }

  Future<void> cacheList(String table, List<Map<String, dynamic>> items) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('cache', where: 'table_name = ?', whereArgs: [table]);
    final now = DateTime.now().toIso8601String();
    for (final item in items) {
      final id = item['id'];
      if (id == null) continue;
      batch.insert('cache', {
        'table_name': table,
        'record_id': id as String,
        'data': jsonEncode(item),
        'updated_at': now,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> cacheItem(String table, Map<String, dynamic> item) async {
    final id = item['id'];
    if (id == null) return;
    final db = await database;
    await db.insert(
      'cache',
      {
        'table_name': table,
        'record_id': id as String,
        'data': jsonEncode(item),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeCachedItem(String table, String id) async {
    final db = await database;
    await db.delete('cache', where: 'table_name = ? AND record_id = ?', whereArgs: [table, id]);
  }

  Future<List<Map<String, dynamic>>> getCachedList(String table) async {
    final db = await database;
    final rows = await db.query('cache',
      where: 'table_name = ?', whereArgs: [table],
      orderBy: 'updated_at DESC',
    );
    return rows.map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>).toList();
  }

  Future<void> queueOperation(String table, String operation, String? recordId, Map<String, dynamic>? data) async {
    final db = await database;
    await db.insert('sync_queue', {
      'table_name': table,
      'operation': operation,
      'record_id': recordId,
      'data': data != null ? jsonEncode(data) : null,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> getQueueLength() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM sync_queue');
    return result.first['count'] as int;
  }

  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final db = await database;
    return db.query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<void> removeFromQueue(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementRetry(int id) async {
    final db = await database;
    await db.rawUpdate('UPDATE sync_queue SET retries = retries + 1 WHERE id = ?', [id]);
  }

  String get errorOffline => 'غير متصل بالإنترنت. تم حفظ العملية محلياً وستتم مزامنتها لاحقاً.';
}
