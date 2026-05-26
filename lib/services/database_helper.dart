import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/oltrap.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;

  DatabaseHelper._internal();

  static const Duration _requestTimeout = Duration(seconds: 15);

  SupabaseClient get _client => Supabase.instance.client;
  String get _table => 'oltraps';

  Map<String, dynamic> _trapToMap(OLTrap oltrap) {
    return {
      'id': oltrap.id,
      'qr_code_data': oltrap.qrCodeData,
      'latitude': oltrap.location.latitude,
      'longitude': oltrap.location.longitude,
      'timestamp': oltrap.timestamp.toIso8601String(),
      'notes': oltrap.notes,
      'location_name': oltrap.locationName,
      'status': oltrap.status.toJson,
      'is_missing': oltrap.isMissing,
      'is_damaged': oltrap.isDamaged,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  OLTrap _mapToTrap(Map<String, dynamic> map) {
    // Normalize snake_case response to what OLTrap.fromJson expects
    final json = Map<String, dynamic>.from(map);
    if (json.containsKey('is_missing')) {
      json['isMissing'] = json.remove('is_missing');
    }
    if (json.containsKey('is_damaged')) {
      json['isDamaged'] = json.remove('is_damaged');
    }
    return OLTrap.fromJson(json);
  }

  Future<int> insertOLTrap(OLTrap oltrap) async {
    try {
      await _client
          .from(_table)
          .upsert(_trapToMap(oltrap))
          .timeout(_requestTimeout);
      return 1;
    } catch (e) {
      print('Error inserting OLTrap: $e');
      rethrow;
    }
  }

  Future<List<OLTrap>> getAllOLTraps() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .order('created_at', ascending: false)
          .timeout(_requestTimeout);

      final List<dynamic> data = response;
      final traps = <OLTrap>[];
      for (final map in data) {
        try {
          traps.add(_mapToTrap(map as Map<String, dynamic>));
        } catch (e, stackTrace) {
          print('Skipping bad record $map: $e');
          print(stackTrace);
        }
      }
      return traps;
    } catch (e) {
      print('Error getting all OLTraps: $e');
      return [];
    }
  }

  Future<List<OLTrap>> getOLTrapsByLocation(String locationName) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('location_name', locationName)
          .order('created_at', ascending: false)
          .timeout(_requestTimeout);

      final List<dynamic> data = response;
      final traps = <OLTrap>[];
      for (final map in data) {
        try {
          traps.add(_mapToTrap(map as Map<String, dynamic>));
        } catch (e, stackTrace) {
          print('Skipping bad record $map: $e');
          print(stackTrace);
        }
      }
      return traps;
    } catch (e) {
      print('Error getting OLTraps by location: $e');
      return [];
    }
  }

  Future<int> updateOLTrap(OLTrap oltrap) async {
    try {
      await _client
          .from(_table)
          .update(_trapToMap(oltrap))
          .eq('id', oltrap.id)
          .timeout(_requestTimeout);
      return 1;
    } catch (e) {
      print('Error updating OLTrap: $e');
      rethrow;
    }
  }

  Future<int> deleteOLTrap(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id).timeout(_requestTimeout);
      return 1;
    } catch (e) {
      print('Error deleting OLTrap: $e');
      rethrow;
    }
  }

  Future<bool> qrCodeExists(String qrCodeData) async {
    try {
      final response = await _client
          .from(_table)
          .select('id')
          .eq('qr_code_data', qrCodeData)
          .limit(1)
          .timeout(_requestTimeout);

      final List<dynamic> data = response;
      return data.isNotEmpty;
    } catch (e) {
      print('Error checking QR code existence: $e');
      return false;
    }
  }

  Future<List<String>> getAllLocationNames() async {
    try {
      final response = await _client
          .from(_table)
          .select('location_name')
          .not('location_name', 'is', null)
          .order('location_name', ascending: true)
          .timeout(_requestTimeout);

      final List<dynamic> data = response;
      return data
          .map((map) => map['location_name'] as String?)
          .where((name) => name != null)
          .cast<String>()
          .toSet()
          .toList();
    } catch (e) {
      print('Error getting location names: $e');
      return [];
    }
  }

  Future<void> clearAllOLTraps() async {
    try {
      await _client
          .from(_table)
          .delete()
          .neq('id', '')
          .timeout(_requestTimeout);
    } catch (e) {
      print('Error clearing OLTraps: $e');
      rethrow;
    }
  }

  Future<void> mergeOLTraps(List<OLTrap> newTraps) async {
    try {
      final existing = await getAllOLTraps();
      final existingQrCodes = existing.map((t) => t.qrCodeData).toSet();

      final trapsToInsert = newTraps
          .where((trap) => !existingQrCodes.contains(trap.qrCodeData))
          .map(_trapToMap)
          .toList();

      if (trapsToInsert.isNotEmpty) {
        await _client
            .from(_table)
            .upsert(trapsToInsert)
            .timeout(_requestTimeout);
      }
    } catch (e) {
      print('Error merging OLTraps: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    // No-op for Supabase; client lifecycle is managed by the SDK
  }
}
