import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/oltrap.dart';
import 'screens/map_screen.dart';
import 'screens/location_history_screen.dart';
import 'screens/settings_screen.dart';
import 'services/supabase_database_helper.dart' as supabase_helper;
import 'theme/neumorphism_theme.dart';

void main() {
  runApp(const OLTrapMappingApp());
}

class OLTrapMappingApp extends StatelessWidget {
  const OLTrapMappingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OLTrap Locator V2',
      theme: AppTheme.theme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: true,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  List<OLTrap> _oltraps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app resumes
      _loadOLTraps();
    }
  }

  Future<void> _initializeApp() async {
    try {
      print('Initializing app...');
      await _requestPermissions();
      await _loadOLTraps();
      print('App initialized successfully');
    } catch (e, stackTrace) {
      print('Error initializing app: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      print('Requesting permissions...');
      await Permission.camera.request();
      await Permission.location.request();
      print('Permissions requested');
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  Future<void> _loadOLTraps() async {
    try {
      print('Loading OLTraps...');
      // Initialize Supabase first
      await supabase_helper.DatabaseHelper.instance.initializeDatabase();
      final oltraps = await supabase_helper.DatabaseHelper.instance.getAllOLTraps();
      print('Fetched ${oltraps.length} OLTraps from Supabase');
      
      // Print details of each trap for debugging
      for (int i = 0; i < oltraps.length; i++) {
        final trap = oltraps[i];
        print('  Trap $i: ${trap.qrCodeData} at (${trap.location.latitude}, ${trap.location.longitude}) - ${trap.locationName ?? 'No location'}');
      }
      
      setState(() {
        _oltraps = oltraps;
        _isLoading = false;
      });
      print('Loaded ${oltraps.length} OLTraps into UI state');
    } catch (e, stackTrace) {
      print('Error loading OLTraps: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _oltraps = [];
      });
    }
  }

  Future<void> _addTrap(OLTrap trap) async {
    try {
      print('Adding OLTrap: ${trap.qrCodeData}');
      
      // If this is a refresh trigger, just reload the data
      if (trap.qrCodeData == 'refresh') {
        print('Refresh trigger detected, reloading data...');
        await _loadOLTraps();
        print('Data reload completed');
        return;
      }
      
      print('Inserting new OLTrap to database...');
      await supabase_helper.DatabaseHelper.instance.insertOLTrap(trap);
      print('OLTrap inserted, reloading data...');
      await _loadOLTraps();
      print('Data reload after insert completed');
    } catch (e) {
      print('Error saving OLTrap: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading OLTrap Locator...'),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        return await _showExitConfirmation();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            MapScreen(
              oltraps: _oltraps,
              onTrapAdded: _addTrap,
            ),
            const LocationHistoryScreen(),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Map tab
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentIndex = 0;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _currentIndex == 0 
                              ? AppTheme.primaryColor.withOpacity(0.1) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.map,
                              size: 24,
                              color: _currentIndex == 0 
                                  ? AppTheme.primaryColor 
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Map',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _currentIndex == 0 
                                    ? FontWeight.w600 
                                    : FontWeight.w500,
                                color: _currentIndex == 0 
                                    ? AppTheme.primaryColor 
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Locations tab
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentIndex = 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _currentIndex == 1 
                              ? AppTheme.primaryColor.withOpacity(0.1) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history,
                              size: 24,
                              color: _currentIndex == 1 
                                  ? AppTheme.primaryColor 
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Locations',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _currentIndex == 1 
                                    ? FontWeight.w600 
                                    : FontWeight.w500,
                                color: _currentIndex == 1 
                                    ? AppTheme.primaryColor 
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Settings tab
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentIndex = 2;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _currentIndex == 2 
                              ? AppTheme.primaryColor.withOpacity(0.1) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.settings,
                              size: 24,
                              color: _currentIndex == 2 
                                  ? AppTheme.primaryColor 
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _currentIndex == 2 
                                    ? FontWeight.w600 
                                    : FontWeight.w500,
                                color: _currentIndex == 2 
                                    ? AppTheme.primaryColor 
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Exit App',
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
              'Are you sure you want to exit OLTrap Locator?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Make sure you have saved all your data before exiting.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_oltraps.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'You currently have ${_oltraps.length} OLTrap${_oltraps.length == 1 ? '' : 's'} in your database.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
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
              'Exit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }
}
