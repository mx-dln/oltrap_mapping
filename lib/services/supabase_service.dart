import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../models/oltrap.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient _supabase;
  
  // Initialize Supabase
  Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://glcgsvyuxfxojrpvqdku.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdsY2dzdnl1eGZ4b2pycHZxZGt1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0NDU2MzksImV4cCI6MjA5MTAyMTYzOX0.CymO45Ie0405AEyvDTgnYLNQVhXQeX91aCiZQRIl7PA',
      debug: false,
    );
    _supabase = Supabase.instance.client;
  }

  SupabaseClient get client => _supabase;

  // CRUD Operations for OLTraps

  // Get all OLTraps
  Future<List<OLTrap>> getAllOLTraps() async {
    try {
      final response = await _supabase
          .from('oltraps')
          .select('*')
          .order('created_at', ascending: false);

      return response.map((map) => _mapToOLTrap(map)).toList();
    } catch (e) {
      throw Exception('Error fetching OLTraps: $e');
    }
  }

  // Get OLTraps by location name
  Future<List<OLTrap>> getOLTrapsByLocation(String locationName) async {
    try {
      final response = await _supabase
          .from('oltraps')
          .select('*')
          .eq('location_name', locationName)
          .order('created_at', ascending: false);

      return response.map((map) => _mapToOLTrap(map)).toList();
    } catch (e) {
      throw Exception('Error fetching OLTraps by location: $e');
    }
  }

  // Insert new OLTrap
  Future<void> insertOLTrap(OLTrap oltrap) async {
    try {
      await _supabase.from('oltraps').insert(_mapToSupabase(oltrap));
    } catch (e) {
      throw Exception('Error inserting OLTrap: $e');
    }
  }

  // Update existing OLTrap
  Future<void> updateOLTrap(OLTrap oltrap) async {
    try {
      await _supabase
          .from('oltraps')
          .update(_mapToSupabase(oltrap))
          .eq('id', oltrap.id);
    } catch (e) {
      throw Exception('Error updating OLTrap: $e');
    }
  }

  // Delete OLTrap
  Future<void> deleteOLTrap(String id) async {
    try {
      await _supabase.from('oltraps').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error deleting OLTrap: $e');
    }
  }

  // Merge OLTraps (for import functionality)
  Future<void> mergeOLTraps(List<OLTrap> newTraps) async {
    try {
      for (final trap in newTraps) {
        // Check if trap already exists by QR code
        final existing = await _supabase
            .from('oltraps')
            .select('*')
            .eq('qr_code_data', trap.qrCodeData)
            .maybeSingle();

        if (existing == null) {
          // Insert new trap
          await insertOLTrap(trap);
        }
      }
    } catch (e) {
      throw Exception('Error merging OLTraps: $e');
    }
  }

  // Clear all OLTraps
  Future<void> clearAllOLTraps() async {
    try {
      await _supabase.from('oltraps').delete().neq('id', '');
    } catch (e) {
      throw Exception('Error clearing OLTraps: $e');
    }
  }

  // Real-time subscription to OLTraps changes
  Stream<List<OLTrap>> subscribeToOLTraps() {
    return _supabase
        .from('oltraps')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((maps) => maps.map((map) => _mapToOLTrap(map)).toList());
  }

  // Helper methods to convert between OLTrap and Supabase format
  Map<String, dynamic> _mapToSupabase(OLTrap oltrap) {
    return {
      'id': oltrap.id,
      'qr_code_data': oltrap.qrCodeData,
      'latitude': oltrap.location.latitude,
      'longitude': oltrap.location.longitude,
      'timestamp': oltrap.timestamp.millisecondsSinceEpoch,
      'notes': oltrap.notes,
      'location_name': oltrap.locationName,
      'status': oltrap.status.toJson,
      'is_missing': oltrap.isMissing,
      'is_damaged': oltrap.isDamaged,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  OLTrap _mapToOLTrap(Map<String, dynamic> map) {
    return OLTrap(
      id: map['id'] ?? '',
      qrCodeData: map['qr_code_data'] ?? '',
      location: LatLng(
        (map['latitude'] as num?)?.toDouble() ?? 0.0,
        (map['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      notes: map['notes'],
      locationName: map['location_name'],
      status: map.containsKey('status')
          ? OLTrapStatusExtension.fromJson(map['status'])
          : OLTrapStatus.deployed,
      isMissing: _parseBool(map['is_missing']),
      isDamaged: _parseBool(map['is_damaged']),
    );
  }

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is int) {
      return value == 1;
    }
    return false;
  }

  // Get statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      final response = await _supabase
          .from('oltraps')
          .select('status, is_missing, is_damaged');

      int deployed = 0;
      int harvested = 0;
      int missing = 0;
      int damaged = 0;

      for (final trap in response) {
        switch (trap['status']) {
          case 'deployed':
            deployed++;
            break;
          case 'harvested':
            harvested++;
            break;
        }
        if (_parseBool(trap['is_missing'])) missing++;
        if (_parseBool(trap['is_damaged'])) damaged++;
      }

      return {
        'deployed': deployed,
        'harvested': harvested,
        'missing': missing,
        'damaged': damaged,
        'total': deployed + harvested,
      };
    } catch (e) {
      throw Exception('Error fetching statistics: $e');
    }
  }

  // Search OLTraps
  Future<List<OLTrap>> searchOLTraps(String query) async {
    try {
      final response = await _supabase
          .from('oltraps')
          .select('*')
          .or('qr_code_data.ilike.%$query%,location_name.ilike.%$query%,notes.ilike.%$query%')
          .order('created_at', ascending: false);

      return response.map((map) => _mapToOLTrap(map)).toList();
    } catch (e) {
      throw Exception('Error searching OLTraps: $e');
    }
  }

  // Get OLTraps by date range
  Future<List<OLTrap>> getOLTrapsByDateRange(DateTime start, DateTime end) async {
    try {
      final response = await _supabase
          .from('oltraps')
          .select('*')
          .gte('timestamp', start.millisecondsSinceEpoch)
          .lte('timestamp', end.millisecondsSinceEpoch)
          .order('created_at', ascending: false);

      return response.map((map) => _mapToOLTrap(map)).toList();
    } catch (e) {
      throw Exception('Error fetching OLTraps by date range: $e');
    }
  }
}
