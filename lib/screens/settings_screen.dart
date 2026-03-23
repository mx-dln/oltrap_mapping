import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import '../services/database_helper.dart';
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
      
      // Get the database path
      final dbPath = path.join(await getDatabasesPath(), 'oltrap_database.db');
      final dbFile = File(dbPath);
      
      // Check if database file exists
      if (!await dbFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No database file found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Get all OLTraps to show count in message
      final allTraps = await DatabaseHelper.instance.getAllOLTraps();
      
      // Let user select directory for export
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder to export OLTrap Database',
      );
      
      if (selectedDirectory == null) {
        // User cancelled the dialog
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export cancelled'),
              backgroundColor: Colors.grey,
            ),
          );
        }
        return;
      }
      
      // Create export filename with timestamp
      final fileName = 'oltrap_database_${DateTime.now().millisecondsSinceEpoch}.db';
      final outputPath = path.join(selectedDirectory, fileName);
      final exportFile = File(outputPath);
      
      // Copy the database file to selected location
      await dbFile.copy(exportFile.path);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database exported successfully (${allTraps.length} traps)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Show Path',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('File saved at: ${exportFile.path}'),
                    duration: const Duration(seconds: 5),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting database: $e'),
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
        final allTraps = await DatabaseHelper.instance.getAllOLTraps();
        final trapCount = allTraps.length;
        
        // Clear all data
        await DatabaseHelper.instance.clearAllOLTraps();
        
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
        
        // Get the database path
        final dbPath = path.join(await getDatabasesPath(), 'oltrap_database.db');
        final targetFile = File(dbPath);
        
        // Close any existing database connections
        await DatabaseHelper.instance.close();
        
        // Copy the imported database file
        await sourceFile.copy(targetFile.path);
        
        // Reopen the database
        await DatabaseHelper.instance.database;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database imported successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
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
                          subtitle: const Text(
                            'Export all OLTrap data to a file',
                            style: TextStyle(fontSize: 14),
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
                            'Version 1.0.0\nOriental Leafhopper Trap Mapping System',
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
