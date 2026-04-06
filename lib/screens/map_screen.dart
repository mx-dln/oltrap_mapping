import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/oltrap.dart';
import '../services/supabase_database_helper.dart' as supabase_helper;
import 'location_selection_screen.dart';
import 'search_qr_scanner_screen.dart';

class MapScreen extends StatefulWidget {
  final List<OLTrap> oltraps;
  final Function(OLTrap) onTrapAdded;

  const MapScreen({
    super.key,
    required this.oltraps,
    required this.onTrapAdded,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  bool _isRefreshing = false;
  OLTrap? _selectedTrap;
  OLTrapStatus? _filterStatus;
  String? _filterLocation;
  String? _filterNotes;
  final TextEditingController _searchController = TextEditingController();
  List<OLTrap> _searchResults = [];
  bool _isSearching = false;
  bool _filtersExpanded = true;
  OLTrap? _searchedTrap; // Track the currently searched trap for highlighting
  
  late AnimationController _glowAnimationController;
  late Animation<double> _glowAnimation;
  
  // Location tracking
  StreamSubscription<Position>? _locationSubscription;
  Timer? _locationUpdateTimer;
  double? _currentAccuracy;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startLocationTracking();
    
    // Initialize glow animation
    _glowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimationController.repeat(reverse: true);
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied')),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      
      // Don't auto-center on current location when getting GPS
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  void _startLocationTracking() {
    // Start location stream for real-time updates like Google Maps
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5, // Update every 5 meters for smoother tracking
      ),
    ).listen((Position position) {
      if (mounted) {
        final newLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocation = newLocation;
          _currentAccuracy = position.accuracy;
        });
        
        // Auto-center on location updates
        _mapController.move(newLocation, 16.0);
      }
    });

    // Also set up periodic updates as backup for better reliability
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _getCurrentLocation();
    });
  }

  void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationUpdateTimer?.cancel();
  }

  Future<void> _refreshOLTraps() async {
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      // Trigger main screen to reload data
      if (mounted) {
        widget.onTrapAdded(OLTrap(
          id: 'refresh_${DateTime.now().millisecondsSinceEpoch}',
          qrCodeData: 'refresh',
          location: const LatLng(0, 0),
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _centerOnCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 22.0); // Maximum zoom level
    } else {
      _getCurrentLocation();
    }
  }

  void _toggleSearchContainer() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchResults.clear();
        _selectedTrap = null;
        _searchedTrap = null;
      }
    });
  }

  void _scanQRCode() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SearchQRScannerScreen(),
        ),
      );
      
      if (result != null && result is String && mounted) {
        // Auto-populate search field with scanned QR code
        setState(() {
          _searchController.text = result;
        });
        // Trigger search with the scanned QR code
        _onSearchChanged(result);
        // Auto-submit to find and show details
        _onSearchSubmitted(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning QR code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    print('Search query changed: "$query"'); // Debug
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _searchedTrap = null;
      });
      return;
    }

    final results = widget.oltraps.where((trap) {
      final qrCodeMatch = trap.qrCodeData.toLowerCase().contains(query.toLowerCase());
      final locationMatch = trap.locationName?.toLowerCase().contains(query.toLowerCase()) ?? false;
      final matches = qrCodeMatch || locationMatch;
      if (matches) {
        print('Match found: ${trap.qrCodeData} (QR: $qrCodeMatch, Location: $locationMatch)'); // Debug
      }
      return matches;
    }).toList();

    print('Search results: ${results.length} matches for query: "$query"'); // Debug
    setState(() {
      _searchResults = results;
      // Set searched trap for highlighting when there's exactly 1 result
      _searchedTrap = results.length == 1 ? results.first : null;
    });
  }

  void _onSearchSubmitted(String query) {
    if (_searchResults.isNotEmpty) {
      if (_searchResults.length == 1) {
        // Auto-open detail page for single result
        _showTrapDetails(_searchResults.first);
        // Don't auto-center on trap when searching
        // Close search after opening details
        setState(() {
          _isSearching = false;
          _searchController.clear();
          _searchResults.clear();
        });
      } else {
        _showMultipleTrapSelection(_searchResults);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No traps found matching your search'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showMultipleTrapSelection(List<OLTrap> traps) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Found ${traps.length} traps'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: traps.length,
              itemBuilder: (context, index) {
                final trap = traps[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: trap.status == OLTrapStatus.deployed 
                          ? Colors.red.shade100 
                          : Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      trap.status == OLTrapStatus.deployed 
                          ? Icons.bug_report 
                          : Icons.inventory_2,
                      color: trap.status == OLTrapStatus.deployed 
                          ? Colors.red.withOpacity(0.7) 
                          : Colors.orange.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    trap.qrCodeData,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (trap.locationName != null)
                        Text(trap.locationName!),
                      Text(
                        '${trap.location.latitude.toStringAsFixed(4)}, ${trap.location.longitude.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    trap.status.displayName,
                    style: TextStyle(
                      color: trap.status == OLTrapStatus.deployed 
                          ? Colors.red 
                          : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showTrapDetails(trap);
                    // Don't auto-center on trap when clicking search result
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'OLTrap Map',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleSpacing: 16,
        actions: [
          IconButton(
            icon: _isRefreshing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _refreshOLTraps,
            tooltip: 'Refresh map data',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _toggleSearchContainer,
            tooltip: 'Search traps',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnCurrentLocation,
            tooltip: 'Center on current location',
          ),
          IconButton(
            icon: const Icon(Icons.explore),
            onPressed: () {
              // Reset map rotation to north-up (0 degrees)
              _mapController.rotate(0.0);
            },
            tooltip: 'Reset map rotation to north',
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshOLTraps,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation ?? const LatLng(16.932411, 121.767825), // Current location or Manila fallback
                initialZoom: 15.0,
                minZoom: 3.0,
                maxZoom: 22.0, // Maximum possible zoom level
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.oltrap_mapping',
                ),
                MarkerLayer(
                  markers: [
                    if (_currentLocation != null) ...[
                      // Accuracy circle
                      if (_currentAccuracy != null)
                        Marker(
                          point: _currentLocation!,
                          width: _currentAccuracy! * 2, // Diameter in meters (approximate)
                          height: _currentAccuracy! * 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      // Current location marker
                      Marker(
                        point: _currentLocation!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                    ...widget.oltraps.where((trap) {
                      // Apply status filter
                      if (_filterStatus != null && trap.status != _filterStatus) return false;
                      
                      // Apply location filter
                      if (_filterLocation != null && trap.locationName != _filterLocation) return false;
                      
                      // Apply notes filter
                      if (_filterNotes != null && trap.notes != _filterNotes) return false;
                      
                      return true;
                    }).map(
                      (trap) {
                        final isSearchResult = _isSearching && _searchResults.contains(trap);
                        final isSelected = _selectedTrap?.id == trap.id;
                        final isSearchedTrap = _searchedTrap?.id == trap.id; // Check if this is the searched trap
                        
                        return Marker(
                          point: trap.location,
                          width: isSelected ? 80 : (isSearchedTrap ? 70 : 60),
                          height: isSelected ? 80 : (isSearchedTrap ? 70 : 60),
                          child: GestureDetector(
                            onTap: () => _showTrapDetails(trap),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glowing circle effect for selected trap
                                if (isSelected)
                                  AnimatedBuilder(
                                    animation: _glowAnimation,
                                    builder: (context, child) {
                                      return Container(
                                        width: 60 + (_glowAnimation.value * 20), // Pulsing size
                                        height: 60 + (_glowAnimation.value * 20), // Pulsing size
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.purple.withOpacity(0.1 + (_glowAnimation.value * 0.2)), // Pulsing opacity
                                          border: Border.all(
                                            color: Colors.purple.withOpacity(0.3 + (_glowAnimation.value * 0.3)), // Pulsing border
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.purple.withOpacity(0.4 + (_glowAnimation.value * 0.4)), // Pulsing shadow
                                              blurRadius: 20 + (_glowAnimation.value * 15), // Pulsing blur
                                              spreadRadius: 4 + (_glowAnimation.value * 4), // Pulsing spread
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                // Main marker container
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSearchedTrap
                                        ? Colors.amber.withOpacity(0.9)
                                        : isSelected
                                            ? Colors.purple.withOpacity(0.9)
                                            : isSearchResult
                                                ? Colors.blue.withOpacity(0.9)
                                                : (trap.notes == 'Missing' || trap.notes == 'Damaged')
                                                    ? Colors.red.withOpacity(0.9)
                                                    : trap.status == OLTrapStatus.deployed 
                                                        ? Colors.red.withOpacity(0.8) 
                                                        : Colors.orange.withOpacity(0.8),
                                    boxShadow: isSelected || isSearchedTrap
                                        ? [
                                            BoxShadow(
                                              color: isSelected 
                                                  ? Colors.purple.withOpacity(0.8)
                                                  : Colors.blue.withOpacity(0.6),
                                              blurRadius: isSelected ? 15 : 8,
                                              spreadRadius: isSelected ? 3 : 2,
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                  ),
                                  child: Icon(
                                    trap.status == OLTrapStatus.deployed 
                                        ? Icons.location_on 
                                        : Icons.location_on,
                                    color: Colors.white,
                                    size: isSearchedTrap ? 28 : (isSelected ? 24 : 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ).toList() // Convert to list and add searched trap at the end for highest z-index
                      ..sort((a, b) {
                        // Put searched trap at the end for highest z-index
                        final aIsSearched = _searchedTrap != null && a.point == _searchedTrap!.location;
                        final bIsSearched = _searchedTrap != null && b.point == _searchedTrap!.location;
                        if (aIsSearched && !bIsSearched) return 1;
                        if (!aIsSearched && bIsSearched) return -1;
                        return 0;
                      }),
                  ],
                ),
              ],
            ),
          ),
          // Search container overlay at top
          if (_isSearching)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Search OLTraps',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: _toggleSearchContainer,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      ),
                      // Search input field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Enter QR code or location name...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.green, width: 2),
                            ),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.qr_code_scanner, color: Colors.green),
                                  onPressed: _scanQRCode,
                                  tooltip: 'Scan QR Code',
                                ),
                              ],
                            ),
                          ),
                          onChanged: _onSearchChanged,
                          onSubmitted: _onSearchSubmitted,
                        ),
                      ),
                      // Search results indicator
                      if (_searchResults.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: GestureDetector(
                            onTap: () {
                              print('Search results tapped: ${_searchResults.length} results'); // Debug
                              print('Search results list: ${_searchResults.map((r) => r.qrCodeData).toList()}'); // Debug
                              if (_searchResults.isNotEmpty) {
                                if (_searchResults.length == 1) {
                                  final trap = _searchResults.first;
                                  print('Opening details for: ${trap.qrCodeData}'); // Debug
                                  print('Trap object: ${trap.toString()}'); // Debug
                                  // Use the same method as map markers
                                  _showTrapDetails(trap);
                                  // Don't auto-center on trap when clicking search result
                                  // Close search to allow bottom sheet to show properly
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    if (mounted) {
                                      setState(() {
                                        _isSearching = false;
                                        _searchController.clear();
                                        _searchResults.clear();
                                      });
                                    }
                                  });
                                } else {
                                  print('Showing multiple trap selection'); // Debug
                                  _showMultipleTrapSelection(_searchResults);
                                }
                              } else {
                                print('Search results is empty'); // Debug
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _searchResults.length == 1 ? Icons.touch_app : Icons.list,
                                    color: Colors.blue.withOpacity(0.7),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _searchResults.length == 1 
                                          ? 'Found 1 trap - Tap to view details'
                                          : 'Found ${_searchResults.length} traps - Tap to select',
                                      style: TextStyle(
                                        color: Colors.blue.withOpacity(0.7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.blue.withOpacity(0.7),
                                    size: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Filter options below search
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Filter header with toggle
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _filtersExpanded = !_filtersExpanded;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Filters',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (_filterStatus != null || _filterLocation != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Active',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green.withOpacity(0.7),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    const Spacer(),
                                    Icon(
                                      _filtersExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      color: Colors.grey.shade600,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Filter content (expandable)
                            if (_filtersExpanded)
                              Container(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  children: [
                                    // Status filter
                                    Row(
                                      children: [
                                        Icon(Icons.filter_list, color: Colors.grey.shade600, size: 16),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Status:',
                                          style: TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Wrap(
                                            spacing: 8,
                                            children: [
                                              FilterChip(
                                                label: const Text('All', style: TextStyle(fontSize: 11)),
                                                selected: _filterStatus == null,
                                                onSelected: (selected) {
                                                  setState(() {
                                                    _filterStatus = null;
                                                  });
                                                },
                                                backgroundColor: Colors.white,
                                                selectedColor: Colors.green.shade100,
                                                checkmarkColor: Colors.green,
                                              ),
                                              ...OLTrapStatus.values.map((status) {
                                                return FilterChip(
                                                  label: Text(status.displayName, style: const TextStyle(fontSize: 11)),
                                                  selected: _filterStatus == status,
                                                  onSelected: (selected) {
                                                    setState(() {
                                                      _filterStatus = selected ? status : null;
                                                    });
                                                  },
                                                  backgroundColor: Colors.white,
                                                  selectedColor: Colors.green.shade100,
                                                  checkmarkColor: Colors.green,
                                                );
                                              }),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Location filter
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, color: Colors.grey.shade600, size: 16),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Location:',
                                          style: TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: [
                                                FilterChip(
                                                  label: const Text('All', style: TextStyle(fontSize: 11)),
                                                  selected: _filterLocation == null,
                                                  onSelected: (selected) {
                                                    setState(() {
                                                      _filterLocation = null;
                                                    });
                                                  },
                                                  backgroundColor: Colors.white,
                                                  selectedColor: Colors.green.shade100,
                                                  checkmarkColor: Colors.green,
                                                ),
                                                const SizedBox(width: 8),
                                                ...widget.oltraps.map((trap) => trap.locationName).where((name) => name != null).toSet().toList().take(5).map((location) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(right: 8),
                                                    child: FilterChip(
                                                      label: Text(location!, style: const TextStyle(fontSize: 11)),
                                                      selected: _filterLocation == location,
                                                      onSelected: (selected) {
                                                        setState(() {
                                                          _filterLocation = selected ? location : null;
                                                        });
                                                      },
                                                      backgroundColor: Colors.white,
                                                      selectedColor: Colors.green.shade100,
                                                      checkmarkColor: Colors.green,
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Notes filter
                                    Row(
                                      children: [
                                        Icon(Icons.note, color: Colors.grey.shade600, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Notes:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          FilterChip(
                                            label: const Text('All', style: TextStyle(fontSize: 11)),
                                            selected: _filterNotes == null,
                                            onSelected: (selected) {
                                              setState(() {
                                                _filterNotes = null;
                                              });
                                            },
                                            backgroundColor: Colors.white,
                                            selectedColor: Colors.green.shade100,
                                            checkmarkColor: Colors.green,
                                          ),
                                          const SizedBox(width: 8),
                                          FilterChip(
                                            label: const Text('Missing', style: TextStyle(fontSize: 11)),
                                            selected: _filterNotes == 'Missing',
                                            onSelected: (selected) {
                                              setState(() {
                                                _filterNotes = selected ? 'Missing' : null;
                                              });
                                            },
                                            backgroundColor: Colors.white,
                                            selectedColor: Colors.red.shade100,
                                            checkmarkColor: Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          FilterChip(
                                            label: const Text('Damaged', style: TextStyle(fontSize: 11)),
                                            selected: _filterNotes == 'Damaged',
                                            onSelected: (selected) {
                                              setState(() {
                                                _filterNotes = selected ? 'Damaged' : null;
                                              });
                                            },
                                            backgroundColor: Colors.white,
                                            selectedColor: Colors.red.shade100,
                                            checkmarkColor: Colors.red,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "qr_scanner",
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const LocationSelectionScreen(),
            ),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
        tooltip: 'Scan QR Code',
      ),
      bottomSheet: _selectedTrap != null ? _buildTrapDetailsSheet() : null,
    );
  }

  void _showTrapDetails(OLTrap trap) {
    print('_showTrapDetails called for: ${trap.qrCodeData}'); // Debug
    setState(() {
      _selectedTrap = trap;
    });
    
    // Position trap higher on the map (not centered)
    // Move the trap up by about 50% of the screen to place it in upper portion
    final currentZoom = 16.0; // Target zoom level
    
    // Calculate latitude offset to position trap higher
    // Subtract offset to move trap higher on visible screen
    final latOffset = 0.04 / currentZoom; // Offset for higher positioning
    final adjustedCenter = LatLng(trap.location.latitude - latOffset, trap.location.longitude);
    
    // Center on adjusted position
    _mapController.move(adjustedCenter, currentZoom);
  }

  Widget _buildTrapDetailsSheet() {
    print('_buildTrapDetailsSheet called, _selectedTrap: ${_selectedTrap?.qrCodeData}'); // Debug
    if (_selectedTrap == null) {
      print('No selected trap, returning SizedBox.shrink()'); // Debug
      return const SizedBox.shrink();
    }
    
    print('Building details sheet for: ${_selectedTrap!.qrCodeData}'); // Debug
    
    return Container(
      constraints: const BoxConstraints(maxHeight: 280), // Further reduced height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: GestureDetector(
        onPanEnd: (details) {
          // Check if the user swiped down
          if (details.velocity.pixelsPerSecond.dy > 500) {
            // Swipe down detected, close the details
            setState(() {
              _selectedTrap = null;
            });
          }
        },
        child: SingleChildScrollView( // Make it scrollable to prevent overflow
          child: Padding(
            padding: const EdgeInsets.all(12), // Further reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar for swipe indication
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header row with title and status (no close button)
                Row(
                  children: [
                    // Title section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'OLTrap Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Status indicator
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Smaller padding
                                decoration: BoxDecoration(
                                  color: _selectedTrap!.status == OLTrapStatus.deployed 
                                      ? Colors.red.shade50 
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(4), // Smaller radius
                                  border: Border.all(
                                    color: _selectedTrap!.status == OLTrapStatus.deployed 
                                        ? Colors.red.shade200 
                                        : Colors.orange.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _selectedTrap!.status == OLTrapStatus.deployed 
                                          ? Icons.location_on 
                                          : Icons.location_on,
                                      color: _selectedTrap!.status == OLTrapStatus.deployed 
                                          ? Colors.red.withOpacity(0.7) 
                                          : Colors.orange.withOpacity(0.7),
                                      size: 12, // Smaller icon
                                    ),
                                    const SizedBox(width: 3), // Smaller spacing
                                    Text(
                                      _selectedTrap!.status.displayName,
                                      style: TextStyle(
                                        fontSize: 11, // Smaller font to match text
                                        fontWeight: FontWeight.w600,
                                        color: _selectedTrap!.status == OLTrapStatus.deployed 
                                            ? Colors.red.withOpacity(0.7) 
                                            : Colors.orange.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_selectedTrap!.locationName != null)
                            Text(
                              _selectedTrap!.locationName!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.withOpacity(0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 8),
              
              // Compact info row
              Row(
                children: [
                  // QR Code
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.qr_code_scanner, color: Colors.grey.shade600, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'QR Code',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedTrap!.qrCodeData,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Date
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade200, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.blue.shade600, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(_selectedTrap!.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Coordinates and notes row
              Row(
                children: [
                  // Coordinates
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.purple.shade200, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.gps_fixed, color: Colors.purple.shade600, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Coordinates',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_selectedTrap!.location.latitude.toStringAsFixed(4)}, ${_selectedTrap!.location.longitude.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.purple.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedTrap!.notes != null && _selectedTrap!.notes!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    // Notes
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade200, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.note_alt, color: Colors.grey.shade600, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Notes',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedTrap!.notes!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Action buttons - only Harvest button (full width)
              if (_selectedTrap!.status == OLTrapStatus.deployed)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _toggleTrapStatus(_selectedTrap!);
                    },
                    icon: const Icon(Icons.location_on, size: 14),
                    label: const Text('Harvest'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleTrapStatus(OLTrap trap) async {
    print('Current trap status before toggle: ${trap.status}'); // Debug
    try {
      final newStatus = trap.status == OLTrapStatus.deployed 
          ? OLTrapStatus.harvested 
          : OLTrapStatus.deployed;
      
      print('New status to set: $newStatus'); // Debug
      
      final updatedTrap = trap.copyWith(status: newStatus);
      await supabase_helper.DatabaseHelper.instance.updateOLTrap(updatedTrap);
      
      setState(() {
        _selectedTrap = null;
      });
      
      // Trigger refresh
      widget.onTrapAdded(OLTrap(
        id: 'refresh_${DateTime.now().millisecondsSinceEpoch}',
        qrCodeData: 'refresh',
        location: const LatLng(0, 0),
        timestamp: DateTime.now(),
      ));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OLTrap status updated to ${newStatus.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _stopLocationTracking();
    _searchController.dispose();
    _glowAnimationController.dispose();
    super.dispose();
  }
}
