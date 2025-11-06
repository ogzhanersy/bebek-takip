import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class SyncService {
  static const String _queueKey = 'pending_ops_queue_v1';
  static bool _isProcessing = false;

  static Future<bool> isOnline() async {
    final status = await Connectivity().checkConnectivity();
    return status != ConnectivityResult.none;
  }

  static Future<void> initialize() async {
    // Listen connectivity changes and process queue when online
    Connectivity().onConnectivityChanged.listen((_) async {
      if (await isOnline()) {
        await processQueue();
      }
    });
    // Also try once on startup
    if (await isOnline()) {
      await processQueue();
    }
  }

  static Future<void> enqueue(Map<String, dynamic> op) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    final List queue = raw != null ? jsonDecode(raw) as List : [];
    queue.add({'id': DateTime.now().millisecondsSinceEpoch, 'op': op});
    await prefs.setString(_queueKey, jsonEncode(queue));
  }

  static Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_queueKey);
      List queue = raw != null ? jsonDecode(raw) as List : [];
      if (queue.isEmpty) return;

      final newQueue = <dynamic>[];

      for (final item in queue) {
        final Map<String, dynamic> op = Map<String, dynamic>.from(item['op']);
        final type = op['type'];
        try {
          if (type == 'create' &&
              op['table'] != null &&
              op['payload'] != null) {
            await SupabaseService.from(op['table']).insert(op['payload']);
          } else if (type == 'update') {
            await SupabaseService.from(
              op['table'],
            ).update(op['payload']).eq('id', op['id']);
          } else if (type == 'delete') {
            await SupabaseService.from(op['table']).delete().eq('id', op['id']);
          } else {
            // Unknown op, drop it
          }
        } catch (_) {
          // Keep in queue to retry later
          newQueue.add(item);
        }
      }

      await prefs.setString(_queueKey, jsonEncode(newQueue));
    } finally {
      _isProcessing = false;
    }
  }
}
