import 'package:flutter/material.dart';
import '../theme/neumorphism_theme.dart';
import '../services/database_helper.dart';
import 'qr_scanner_screen.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final TextEditingController _locationController = TextEditingController();
  List<String> _recentLocations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentLocations();
  }

  Future<void> _loadRecentLocations() async {
    try {
      final locations = await DatabaseHelper.instance.getAllLocationNames();
      setState(() {
        _recentLocations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _recentLocations = ['ISU Echague', 'Main Campus', 'Science Building', 'Library'];
      });
    }
  }

  void _showCreateLocationModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter location name:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'e.g., ISU Echague',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _locationController.clear();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_locationController.text.isNotEmpty) {
                  setState(() {
                    _recentLocations.insert(0, _locationController.text);
                  });
                  Navigator.of(context).pop();
                  _locationController.clear();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectLocation(String locationName) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(locationName: locationName),
      ),
    );
    
    // If something was scanned, trigger refresh
    if (result == true && mounted) {
      _loadRecentLocations(); // Refresh the list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateLocationModal,
            tooltip: 'Create New Location',
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadRecentLocations,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Locations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _recentLocations.isEmpty
                        ? const Center(
                            child: Text(
                              'No recent locations found',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _recentLocations.length,
                            itemBuilder: (context, index) {
                              final location = _recentLocations[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.location_on),
                                  title: Text(location),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () => _selectLocation(location),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }
}
