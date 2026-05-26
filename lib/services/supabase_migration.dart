import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class SupabaseMigration {
  static bool enableStartupMigration = false;

  static Future<int> migrateFromDbFile(String dbFilePath) async {
    if (!enableStartupMigration) return 0;

    if (!File(dbFilePath).existsSync()) {
      throw Exception('Database file not found: $dbFilePath');
    }

    // Copy to a temp location so sqflite can open it (avoids locks)
    final tempDir = Directory.systemTemp;
    final tempPath = p.join(
      tempDir.path,
      'temp_migration_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    await File(dbFilePath).copy(tempPath);

    final db = await openDatabase(tempPath, readOnly: true);
    final maps = await db.query('oltraps');
    await db.close();
    await File(tempPath).delete();

    final traps = <Map<String, dynamic>>[];
    for (final map in maps) {
      // Normalize timestamp
      DateTime ts;
      final rawTs = map['timestamp'];
      if (rawTs is int) {
        ts = DateTime.fromMillisecondsSinceEpoch(rawTs);
      } else if (rawTs is String) {
        ts = DateTime.tryParse(rawTs) ?? DateTime.now();
      } else {
        ts = DateTime.now();
      }

      // Normalize created_at
      DateTime createdAt;
      final rawCa = map['created_at'];
      if (rawCa is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(rawCa);
      } else if (rawCa is String) {
        createdAt = DateTime.tryParse(rawCa) ?? DateTime.now();
      } else {
        createdAt = DateTime.now();
      }

      // Normalize booleans (SQLite stores as 0/1)
      bool parseBool(dynamic v) {
        if (v == null) return false;
        if (v is bool) return v;
        if (v is int) return v == 1;
        if (v is String) return v == '1' || v.toLowerCase() == 'true';
        return false;
      }

      // Normalize status
      final statusStr = map['status']?.toString() ?? 'deployed';

      traps.add({
        'id': map['id']?.toString() ?? '',
        'qr_code_data': map['qr_code_data']?.toString() ?? '',
        'latitude': (map['latitude'] as num?)?.toDouble() ?? 0.0,
        'longitude': (map['longitude'] as num?)?.toDouble() ?? 0.0,
        'timestamp': ts.toIso8601String(),
        'notes': map['notes']?.toString(),
        'location_name': map['location_name']?.toString(),
        'status': statusStr,
        'is_missing': parseBool(map['isMissing']),
        'is_damaged': parseBool(map['isDamaged']),
        'created_at': createdAt.toIso8601String(),
      });
    }

    if (traps.isEmpty) return 0;

    // Upsert in batches of 100 to avoid request size limits
    final client = Supabase.instance.client;
    int inserted = 0;
    const batchSize = 100;
    for (var i = 0; i < traps.length; i += batchSize) {
      final batch = traps.skip(i).take(batchSize).toList();
      await client.from('oltraps').upsert(batch);
      inserted += batch.length;
    }

    return inserted;
  }

  /// Convenience: migrate from the default app database path
  static Future<int> migrateDefaultDatabase() async {
    final dbPath = p.join(await getDatabasesPath(), 'oltrap_database.db');
    return migrateFromDbFile(dbPath);
  }
}
