import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/oltrap.dart';
import 'screens/map_screen.dart';
import 'screens/location_history_screen.dart';
import 'screens/settings_screen.dart';
import 'services/database_helper.dart';
import 'theme/neumorphism_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OLTrapMappingApp());
}

class OLTrapMappingApp extends StatelessWidget {
  const OLTrapMappingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OLTrap Locator',
      theme: AppTheme.theme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
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
  bool _locationsTabVisited = false;
  bool _settingsTabVisited = false;
  bool _supabaseReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _supabaseReady) {
      // Refresh data when app resumes
      _loadOLTraps();
    }
  }

  Future<void> _initializeApp() async {
    try {
      print('Initializing app...');
      final supabaseReady = await _initializeSupabase();
      if (!mounted) return;
      if (supabaseReady) {
        _supabaseReady = true;
        _loadOLTraps();
      }
      print('App initialized successfully');
    } catch (e, stackTrace) {
      print('Error initializing app: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<bool> _initializeSupabase() async {
    try {
      await Supabase.initialize(
        url: 'https://glcgsvyuxfxojrpvqdku.supabase.co',
        anonKey: 'sb_publishable_yoz3Np5-jAVMRo2DYnE8Ng_cUtXiD30',
      ).timeout(const Duration(seconds: 8));
      return true;
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
      return false;
    }
  }

  Future<void> _loadOLTraps() async {
    if (!_supabaseReady) return;
    try {
      print('Loading OLTraps...');
      final oltraps = await DatabaseHelper.instance.getAllOLTraps();
      if (!mounted) return;
      setState(() {
        _oltraps = oltraps;
      });
      print('Loaded ${oltraps.length} OLTraps');
    } catch (e, stackTrace) {
      print('Error loading OLTraps: $e');
      print('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _oltraps = [];
      });
    }
  }

  Future<void> _addTrap(OLTrap trap) async {
    if (!_supabaseReady) return;
    try {
      // If this is a refresh trigger, just reload the data
      if (trap.qrCodeData == 'refresh') {
        _loadOLTraps();
        return;
      }

      await DatabaseHelper.instance.insertOLTrap(trap);
      _loadOLTraps();
    } catch (e) {
      print('Error saving OLTrap: $e');
    }
      print('Adding OLTrap: ${trap.qrCodeData}');

  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await _showExitConfirmation();
      },
      child: Scaffold(
        body: _buildCurrentScreen(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
              if (index == 1) _locationsTabVisited = true;
              if (index == 2) _settingsTabVisited = true;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.location_on_outlined),
              selectedIcon: Icon(Icons.location_on),
              label: 'Locations',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        MapScreen(oltraps: _oltraps, onTrapAdded: _addTrap),
        _locationsTabVisited
            ? const LocationHistoryScreen()
            : const SizedBox.shrink(),
        _settingsTabVisited ? const SettingsScreen() : const SizedBox.shrink(),
      ],
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Exit',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
