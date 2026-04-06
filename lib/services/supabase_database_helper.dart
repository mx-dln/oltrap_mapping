import '../models/oltrap.dart';
import 'supabase_service.dart';

/// Database Helper using Supabase instead of SQLite
/// Maintains the same interface as the original DatabaseHelper
/// for easy migration and compatibility
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;
  
  DatabaseHelper._internal();
  
  final SupabaseService _supabaseService = SupabaseService();

  // Initialize database (Supabase connection)
  Future<void> initializeDatabase() async {
    await _supabaseService.initialize();
  }

  // Insert OLTrap
  Future<int> insertOLTrap(OLTrap oltrap) async {
    try {
      await _supabaseService.insertOLTrap(oltrap);
      return 1; // Return success indicator
    } catch (e) {
      throw Exception('Failed to insert OLTrap: $e');
    }
  }

  // Get all OLTraps
  Future<List<OLTrap>> getAllOLTraps() async {
    try {
      return await _supabaseService.getAllOLTraps();
    } catch (e) {
      throw Exception('Failed to get all OLTraps: $e');
    }
  }

  // Get OLTraps by location
  Future<List<OLTrap>> getOLTrapsByLocation(String locationName) async {
    try {
      return await _supabaseService.getOLTrapsByLocation(locationName);
    } catch (e) {
      throw Exception('Failed to get OLTraps by location: $e');
    }
  }

  // Update OLTrap
  Future<int> updateOLTrap(OLTrap oltrap) async {
    try {
      await _supabaseService.updateOLTrap(oltrap);
      return 1; // Return success indicator
    } catch (e) {
      throw Exception('Failed to update OLTrap: $e');
    }
  }

  // Delete OLTrap
  Future<int> deleteOLTrap(String id) async {
    try {
      await _supabaseService.deleteOLTrap(id);
      return 1; // Return success indicator
    } catch (e) {
      throw Exception('Failed to delete OLTrap: $e');
    }
  }

  // Merge OLTraps (for import functionality)
  Future<void> mergeOLTraps(List<OLTrap> newTraps) async {
    try {
      await _supabaseService.mergeOLTraps(newTraps);
    } catch (e) {
      throw Exception('Failed to merge OLTraps: $e');
    }
  }

  // Clear all OLTraps
  Future<void> clearAllOLTraps() async {
    try {
      await _supabaseService.clearAllOLTraps();
    } catch (e) {
      throw Exception('Failed to clear all OLTraps: $e');
    }
  }

  // Get statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      return await _supabaseService.getStatistics();
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }

  // Search OLTraps
  Future<List<OLTrap>> searchOLTraps(String query) async {
    try {
      return await _supabaseService.searchOLTraps(query);
    } catch (e) {
      throw Exception('Failed to search OLTraps: $e');
    }
  }

  // Get OLTraps by date range
  Future<List<OLTrap>> getOLTrapsByDateRange(DateTime start, DateTime end) async {
    try {
      return await _supabaseService.getOLTrapsByDateRange(start, end);
    } catch (e) {
      throw Exception('Failed to get OLTraps by date range: $e');
    }
  }

  // Real-time subscription to OLTraps changes
  Stream<List<OLTrap>> subscribeToOLTraps() {
    return _supabaseService.subscribeToOLTraps();
  }

  // Close database connection (not needed for Supabase, but kept for compatibility)
  Future<void> close() async {
    // Supabase doesn't require explicit connection closing
    // This method is kept for interface compatibility
  }
}
