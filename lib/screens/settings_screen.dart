import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import '../services/supabase_database_helper.dart' as supabase_helper;
import '../models/oltrap.dart';
import '../theme/neumorphism_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  Future<void> _exportDatabase() async {
    try {
      setState(() => _isLoading = true);
      
      // Get all OLTraps to show count in message
      final allTraps = await supabase_helper.DatabaseHelper.instance.getAllOLTraps();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ OLTrap data is automatically synced to Supabase!'),
                Text('� Total traps: ${allTraps.length}'),
                Text('� Real-time sync enabled'),
                Text('☁️ Cloud database active'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error accessing Supabase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Clear All Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete all OLTrap data?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All OLTrap records will be permanently deleted.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Clear All',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        
        // Get current trap count for feedback
        final allTraps = await supabase_helper.DatabaseHelper.instance.getAllOLTraps();
        final trapCount = allTraps.length;
        
        // Clear all data
        await supabase_helper.DatabaseHelper.instance.clearAllOLTraps();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully deleted $trapCount OLTrap record${trapCount == 1 ? '' : 's'}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _importDatabase() async {
    try {
      setState(() => _isLoading = true);
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      
      if (result != null && result.files.single.path != null) {
        final sourceFile = File(result.files.single.path!);
        final fileName = sourceFile.path.split('/').last.toLowerCase();
        
        // Validate file extension
        if (!fileName.endsWith('.db')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a valid database file (.db)'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        
        // Get current trap count before import
        final currentTraps = await supabase_helper.DatabaseHelper.instance.getAllOLTraps();
        final currentCount = currentTraps.length;
        
        // Read and parse imported data
        final bytes = await sourceFile.readAsBytes();
        final tempDbPath = path.join(await getDatabasesPath(), 'temp_import.db');
        final tempDbFile = File(tempDbPath);
        
        // Copy imported database to temporary location
        await tempDbFile.writeAsBytes(bytes);
        
        // Read traps from temporary database
        final tempDb = await openDatabase(tempDbPath);
        final tempMaps = await tempDb.query('oltraps');
        
        // Convert to OLTrap objects
        final importedTraps = tempMaps.map((map) {
          // Generate unique ID based on QR code if ID is missing or conflicts
          final qrCode = map['qr_code_data']?.toString() ?? '';
          final existingId = map['id']?.toString() ?? '';
          final uniqueId = qrCode.isNotEmpty ? qrCode.hashCode.toString() : existingId;
          
          return OLTrap.fromJson({
            'id': uniqueId,
            'qr_code_data': qrCode,
            'latitude': (map['latitude'] as num?)?.toDouble() ?? 0.0,
            'longitude': (map['longitude'] as num?)?.toDouble() ?? 0.0,
            'timestamp': map['timestamp']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            'notes': map['notes']?.toString(),
            'location_name': map['location_name']?.toString(),
            'status': map['status']?.toString() ?? 'deployed',
            'isMissing': map['isMissing']?.toString() ?? 'false',
            'isDamaged': map['isDamaged']?.toString() ?? 'false',
          });
        }).toList();
        
        await tempDb.close();
        
        // Delete temporary database
        await tempDbFile.delete();
        
        // Reopen main database
        await supabase_helper.DatabaseHelper.instance.initializeDatabase();
        
        // Merge new traps with existing data
        await supabase_helper.DatabaseHelper.instance.mergeOLTraps(importedTraps);
        
        // Get final trap count
        final finalTraps = await supabase_helper.DatabaseHelper.instance.getAllOLTraps();
        final finalCount = finalTraps.length;
        final newCount = finalCount - currentCount;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newCount > 0 
                    ? 'Successfully imported $newCount new OLTrap record${newCount == 1 ? '' : 's'} (Total: $finalCount)'
                    : 'Import complete - no new records found (Total: $finalCount)'
              ),
              backgroundColor: newCount > 0 ? Colors.green : Colors.blue,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing database: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Data Management Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Data Management',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        // Export Database
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.file_download,
                              color: Colors.blue.shade600,
                              size: 24,
                            ),
                          ),
                          title: const Text(
                            'Export Database',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Export all OLTrap data to Downloads folder',
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '📁 Direct download to device storage',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _exportDatabase,
                        ),
                        const Divider(height: 1),
                        // Import Database
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.file_upload,
                              color: Colors.green.shade600,
                              size: 24,
                            ),
                          ),
                          title: const Text(
                            'Import Database',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Import OLTrap data from a file',
                            style: TextStyle(fontSize: 14),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _importDatabase,
                        ),
                        const Divider(height: 1),
                        // Clear All Data
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.delete_forever,
                              color: Colors.red.shade600,
                              size: 24,
                            ),
                          ),
                          title: const Text(
                            'Clear All Data',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                          subtitle: const Text(
                            'Delete all OLTrap records permanently',
                            style: TextStyle(fontSize: 14),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _clearAllData,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // App Info Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'About',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info,
                              color: Colors.grey.shade600,
                              size: 24,
                            ),
                          ),
                          title: const Text(
                            'OLTrap Locator',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Version 1.1.0\nOvicidal/Larvicidal Trap Mapping System',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
