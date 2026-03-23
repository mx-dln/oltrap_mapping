import 'package:flutter/material.dart';
import '../models/oltrap.dart';
import '../services/database_helper.dart';
import '../services/geojson_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<OLTrap> _oltraps = [];
  List<String> _locations = [];
  String? _selectedLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final oltraps = await DatabaseHelper.instance.getAllOLTraps();
      final locations = await DatabaseHelper.instance.getAllLocationNames();
      
      setState(() {
        _oltraps = oltraps;
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _deleteOLTrap(String id) async {
    try {
      await DatabaseHelper.instance.deleteOLTrap(id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OLTrap deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting OLTrap: $e')),
        );
      }
    }
  }

  void _showOLTrapDetails(OLTrap oltrap) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('OLTrap Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('QR Code: ${oltrap.qrCodeData}'),
              const SizedBox(height: 8),
              Text('Location: ${oltrap.location.latitude.toStringAsFixed(6)}, ${oltrap.location.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 8),
              Text('Date: ${oltrap.timestamp.toString().split('.')[0]}'),
              if (oltrap.locationName != null) ...[
                const SizedBox(height: 8),
                Text('Location Name: ${oltrap.locationName}'),
              ],
              if (oltrap.notes != null) ...[
                const SizedBox(height: 8),
                Text('Notes: ${oltrap.notes}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editOLTrapLocation(oltrap);
            },
            child: const Text('Edit Location'),
          ),
        ],
      ),
    );
  }

  void _editOLTrapLocation(OLTrap oltrap) {
    final TextEditingController controller = TextEditingController(text: oltrap.locationName ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Location Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Location Name (e.g., ISU Echague)',
            hintText: 'Enter location name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final updatedOLTrap = oltrap.copyWith(locationName: controller.text.trim());
              await DatabaseHelper.instance.updateOLTrap(updatedOLTrap);
              Navigator.pop(context);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _createNewLocation() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Location'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Location Name (e.g., ISU Echague)',
            hintText: 'Enter location name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                // Navigate to map with location name context
                Navigator.pushReplacementNamed(
                  context,
                  '/',
                  arguments: {'locationName': controller.text.trim()},
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportGeoJSON() async {
    try {
      if (_oltraps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No OLTraps to export')),
        );
        return;
      }

      final geoJsonContent = await GeoJSONService.exportToGeoJSON(_oltraps);
      await GeoJSONService.saveGeoJSONFile(geoJsonContent, 'oltraps_${DateTime.now().millisecondsSinceEpoch}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OLTraps exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importGeoJSON() async {
    try {
      final importedOLTraps = await GeoJSONService.importFromGeoJSON();
      
      if (importedOLTraps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No OLTraps found in file')),
        );
        return;
      }

      // Save imported OLTraps to database
      for (final oltrap in importedOLTraps) {
        await DatabaseHelper.instance.insertOLTrap(oltrap);
      }
      
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${importedOLTraps.length} OLTraps successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  List<OLTrap> get _filteredOLTraps {
    if (_selectedLocation == null) return _oltraps;
    return _oltraps.where((trap) => trap.locationName == _selectedLocation).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OLTrap History'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _exportGeoJSON,
            tooltip: 'Export to GeoJSON',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _importGeoJSON,
            tooltip: 'Import from GeoJSON',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewLocation,
            tooltip: 'Create New Location',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Location filter
                if (_locations.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Location',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Locations'),
                        ),
                        ..._locations.map((location) => DropdownMenuItem(
                          value: location,
                          child: Text(location),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value;
                        });
                      },
                    ),
                  ),
                // List of OLTraps
                Expanded(
                  child: _filteredOLTraps.isEmpty
                      ? const Center(
                          child: Text(
                            'No OLTraps found. Start scanning to add some!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredOLTraps.length,
                          itemBuilder: (context, index) {
                            final oltrap = _filteredOLTraps[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                leading: const Icon(Icons.location_on, color: Colors.red),
                                title: Text(oltrap.qrCodeData),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Location: ${oltrap.location.latitude.toStringAsFixed(4)}, ${oltrap.location.longitude.toStringAsFixed(4)}',
                                    ),
                                    if (oltrap.locationName != null)
                                      Text('Area: ${oltrap.locationName}'),
                                    Text(
                                      'Date: ${oltrap.timestamp.toString().split('.')[0]}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'view',
                                      child: const Text('View Details'),
                                    ),
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: const Text('Edit Location'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'view':
                                        _showOLTrapDetails(oltrap);
                                        break;
                                      case 'edit':
                                        _editOLTrapLocation(oltrap);
                                        break;
                                      case 'delete':
                                        _deleteOLTrap(oltrap.id);
                                        break;
                                    }
                                  },
                                ),
                                onTap: () => _showOLTrapDetails(oltrap),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.map, color: Colors.white),
        tooltip: 'Back to Map',
      ),
    );
  }
}
