import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/database_helper.dart';
import '../models/oltrap.dart';
import '../theme/neumorphism_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  Future<void> _requestStoragePermissions() async {
    try {
      // Request storage permissions for Android
      if (Platform.isAndroid) {
        // For Android 11+, we need MANAGE_EXTERNAL_STORAGE for public Downloads access
        await Permission.storage.request();
        await Permission.manageExternalStorage.request();

        // Check if permissions are granted
        var storageStatus = await Permission.storage.status;
        var manageStorageStatus = await Permission.manageExternalStorage.status;

        if (!storageStatus.isGranted && !manageStorageStatus.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '⚠️ Storage permissions required for Downloads folder access',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error requesting storage permissions: $e');
    }
  }

  Future<void> _exportDatabase() async {
    try {
      setState(() => _isLoading = true);

      // Request storage permissions first
      await _requestStoragePermissions();

      // Get all OLTraps from Supabase
      final allTraps = await DatabaseHelper.instance.getAllOLTraps();

      if (allTraps.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No data to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Build JSON payload
      final exportData = {
        'version': '1.1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'count': allTraps.length,
        'traps': allTraps.map((t) => t.toJson()).toList(),
      };
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Generate timestamped filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final version = '1.1.0';
      final fileName = 'oltrap_export_v${version}_$timestamp.json';

      bool exportSuccessful = false;
      String? exportPath;
      String exportMethod = '';

      // Method 1: Try public Downloads directory
      try {
        if (Platform.isAndroid) {
          final downloadsPath = '/storage/emulated/0/Download';
          final downloadsDir = Directory(downloadsPath);
          if (await downloadsDir.exists()) {
            exportPath = path.join(downloadsPath, fileName);
            await _writeJsonToPath(jsonString, exportPath);
            exportSuccessful = true;
            exportMethod = 'Public Downloads folder';
          }
        }
      } catch (e) {
        print('Public Downloads directory failed: $e');
      }

      // Method 2: Try getDownloadsDirectory()
      if (!exportSuccessful) {
        try {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null &&
              !downloadsDir.path.contains('Android/data')) {
            exportPath = path.join(downloadsDir.path, fileName);
            await _writeJsonToPath(jsonString, exportPath);
            exportSuccessful = true;
            exportMethod = 'Downloads folder';
          }
        } catch (e) {
          print('Downloads directory failed: $e');
        }
      }

      // Method 3: Try external storage Downloads
      if (!exportSuccessful) {
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            final basePath = externalDir.path.split('Android')[0];
            final downloadsPath = path.join(basePath, 'Download');
            final downloadsDir = Directory(downloadsPath);
            if (await downloadsDir.exists()) {
              exportPath = path.join(downloadsPath, fileName);
              await _writeJsonToPath(jsonString, exportPath);
              exportSuccessful = true;
              exportMethod = 'External Downloads folder';
            }
          }
        } catch (e) {
          print('External Downloads directory failed: $e');
        }
      }

      // Method 4: Try directory picker
      if (!exportSuccessful) {
        try {
          String? selectedDirectory = await FilePicker.platform
              .getDirectoryPath(
                dialogTitle: 'Select folder to export OLTrap data',
              );
          if (selectedDirectory != null) {
            exportPath = path.join(selectedDirectory, fileName);
            await _writeJsonToPath(jsonString, exportPath);
            exportSuccessful = true;
            exportMethod = 'Selected folder';
          }
        } catch (e) {
          print('Directory picker failed: $e');
        }
      }

      // Method 5: Try external storage OLTrap folder
      if (!exportSuccessful) {
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            final oltrapDir = Directory(path.join(externalDir.path, 'OLTrap'));
            if (!await oltrapDir.exists()) {
              await oltrapDir.create(recursive: true);
            }
            exportPath = path.join(oltrapDir.path, fileName);
            await _writeJsonToPath(jsonString, exportPath);
            exportSuccessful = true;
            exportMethod = 'OLTrap folder';
          }
        } catch (e) {
          print('External storage failed: $e');
        }
      }

      // Method 6: Try app documents directory
      if (!exportSuccessful) {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          exportPath = path.join(appDir.path, fileName);
          await _writeJsonToPath(jsonString, exportPath);
          exportSuccessful = true;
          exportMethod = 'App documents';
        } catch (e) {
          print('App documents directory failed: $e');
        }
      }

      // Method 7: Share via dialog
      if (!exportSuccessful) {
        try {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File(path.join(tempDir.path, fileName));
          await tempFile.writeAsString(jsonString);

          await Share.shareXFiles(
            [XFile(tempFile.path, name: fileName)],
            subject: 'OLTrap Data Export',
            text: 'Exported ${allTraps.length} OLTraps',
          );

          exportSuccessful = true;
          exportMethod = 'Share dialog';
          exportPath = tempFile.path;
        } catch (e) {
          print('Share method failed: $e');
        }
      }

      if (mounted) {
        if (exportSuccessful && exportPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ Data exported successfully!'),
                  Text('📁 ${allTraps.length} traps saved'),
                  Text('📍 Location: $exportMethod'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: exportMethod != 'Share dialog'
                  ? SnackBarAction(
                      label: 'View',
                      textColor: Colors.white,
                      onPressed: () {
                        _showExportLocation(exportPath!);
                      },
                    )
                  : null,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ Export failed: Unable to access storage on this device',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _writeJsonToPath(String jsonString, String targetPath) async {
    final targetFile = File(targetPath);
    final directory = targetFile.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    await targetFile.writeAsString(jsonString);
  }

  Future<void> _showExportLocation(String filePath) async {
    try {
      // On Android, this might not work consistently, but we try
      if (Platform.isAndroid) {
        // Show a dialog with file path
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Export Location'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Data exported to:'),
                  const SizedBox(height: 8),
                  SelectableText(
                    filePath,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('Failed to show export location: $e');
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  Icon(
                    Icons.info_outline,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
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
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
              content: Text(
                'Successfully deleted $trapCount OLTrap record${trapCount == 1 ? '' : 's'}',
              ),
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

      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null && result.files.single.path != null) {
        final sourceFile = File(result.files.single.path!);
        final fileName = sourceFile.path.split('/').last.toLowerCase();

        // Validate file extension
        if (!fileName.endsWith('.json')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a valid export file (.json)'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // Read and parse JSON file
        final jsonString = await sourceFile.readAsString();
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

        // Extract traps array (support both wrapped export and flat array)
        final List<dynamic> trapMaps;
        if (jsonData.containsKey('traps')) {
          trapMaps = jsonData['traps'] as List<dynamic>;
        } else if (jsonData.containsKey('oltraps')) {
          trapMaps = jsonData['oltraps'] as List<dynamic>;
        } else {
          trapMaps = [jsonData];
        }

        // Get existing QR codes to check for duplicates
        final existingTraps = await DatabaseHelper.instance.getAllOLTraps();
        final existingQrCodes = existingTraps.map((t) => t.qrCodeData).toSet();

        final List<OLTrap> newTraps = [];
        final List<String> duplicateQrCodes = [];

        for (final map in trapMaps) {
          final data = map as Map<String, dynamic>;
          final qrCode = data['qr_code_data']?.toString() ?? '';

          if (qrCode.isEmpty) continue;

          if (existingQrCodes.contains(qrCode)) {
            duplicateQrCodes.add(qrCode);
            continue;
          }

          final uniqueId = qrCode.hashCode.toString();

          newTraps.add(
            OLTrap.fromJson({
              'id': uniqueId,
              'qr_code_data': qrCode,
              'latitude': (data['latitude'] as num?)?.toDouble() ?? 0.0,
              'longitude': (data['longitude'] as num?)?.toDouble() ?? 0.0,
              'timestamp': DateTime.now().toIso8601String(),
              'notes': data['notes']?.toString(),
              'location_name': data['location_name']?.toString(),
              'status': data['status']?.toString() ?? 'deployed',
              'isMissing': data['isMissing']?.toString() ?? 'false',
              'isDamaged': data['isDamaged']?.toString() ?? 'false',
            }),
          );
        }

        if (newTraps.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Data already exists'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // Insert new traps via Supabase
        await DatabaseHelper.instance.mergeOLTraps(newTraps);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully imported ${newTraps.length} OLTrap record${newTraps.length == 1 ? '' : 's'}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing data: $e'),
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Settings'),
            Text(
              'Data and app controls',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OLTrap Locator',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Keep records portable, backed up, and clean.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Data Management Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.outlineColor),
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
                                'Direct download to device storage',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
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
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
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
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
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
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.outlineColor),
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
