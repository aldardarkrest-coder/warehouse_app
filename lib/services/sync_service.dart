import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_storage_service.dart';

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  bool _isSyncing = false;
  Timer? _timer;

  void startPeriodicSync() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => processQueue());
  }

  void stopSync() {
    _timer?.cancel();
    _timer = null;
  }

  Future<bool> isOnline() async {
    try {
      await Supabase.instance.client.from('items').select('id').limit(1).then((_) {});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> processQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final online = await isOnline();
      if (!online) { _isSyncing = false; return; }

      final queue = await LocalStorageService.instance.getPendingOperations();
      if (queue.isEmpty) { _isSyncing = false; return; }

      final client = Supabase.instance.client;
      for (final item in queue) {
        try {
          final table = item['table_name'] as String;
          final operation = item['operation'] as String;
          final recordId = item['record_id'] as String?;
          final rawData = item['data'] as String?;
          final data = rawData != null ? jsonDecode(rawData) as Map<String, dynamic> : null;

          if (operation == 'INSERT' && data != null) {
            final result = await client.from(table).insert(data).select().single();
            await LocalStorageService.instance.cacheItem(table, result);
          } else if (operation == 'UPDATE' && data != null && recordId != null) {
            final result = await client.from(table).update(data).match({'id': recordId}).select().single();
            await LocalStorageService.instance.cacheItem(table, result);
          } else if (operation == 'DELETE' && recordId != null) {
            await client.from(table).delete().match({'id': recordId});
            await LocalStorageService.instance.removeCachedItem(table, recordId);
          }
          await LocalStorageService.instance.removeFromQueue(item['id'] as int);
        } catch (_) {
          await LocalStorageService.instance.incrementRetry(item['id'] as int);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
