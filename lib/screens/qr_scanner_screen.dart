import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/oltrap.dart';
import '../services/supabase_database_helper.dart' as supabase_helper;

class QRScannerScreen extends StatefulWidget {
  final String? locationName;

  const QRScannerScreen({
    super.key,
    this.locationName,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  bool _isInitialized = false;
  List<OLTrap> _scannedOLTraps = [];
  bool _showList = false;
  OLTrapStatus _selectedStatus = OLTrapStatus.deployed;
  String _selectedNotes = 'Scanned from QR Code'; // Default value

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadScannedOLTraps();
  }

  Future<void> _loadScannedOLTraps() async {
    try {
      if (widget.locationName != null) {
        final oltraps = await supabase_helper.DatabaseHelper.instance.getOLTrapsByLocation(widget.locationName!);
        setState(() {
          _scannedOLTraps = oltraps;
        });
      } else {
        final oltraps = await supabase_helper.DatabaseHelper.instance.getAllOLTraps();
        setState(() {
          _scannedOLTraps = oltraps;
        });
      }
    } catch (e) {
      print('Error loading scanned OLTraps: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameraPermission = await Permission.camera.request();
      if (cameraPermission.isGranted) {
        setState(() {
          _controller = MobileScannerController(
            detectionSpeed: DetectionSpeed.normal,
            facing: CameraFacing.back,
            torchEnabled: false,
          );
          _isInitialized = true;
        });
      } else {
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      _showErrorDialog('Failed to initialize camera: $e');
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text('Camera permission is required to scan QR codes. Please enable it in settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<LatLng> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    try {
      // Try multiple times to get the most accurate location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
        forceAndroidLocationManager: false,
      );

      // If accuracy is not good enough, try again with higher accuracy
      if (position.accuracy > 20) {
        // Wait a bit and try again for better accuracy
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation,
            timeLimit: const Duration(seconds: 10),
          );
        } catch (e) {
          // If second attempt fails, use the first result
          print('Second location attempt failed: $e');
        }
      }
      
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      throw Exception('Failed to get accurate location: $e');
    }
  }

  void _onBarcodeCapture(BarcodeCapture capture) {
    if (_isProcessing) return;
    
    final barcode = capture.barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() {
      _isProcessing = true;
    });

    _processQRCode(barcode.rawValue!);
  }

  Future<void> _processQRCode(String qrData) async {
    try {
      // Check if QR code already exists
      final oltraps = await supabase_helper.DatabaseHelper.instance.getAllOLTraps();
      final exists = oltraps.any((trap) => trap.qrCodeData == qrData);
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This QR code has already been scanned!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final currentLocation = await _getCurrentLocation();
      
      final oltrap = OLTrap(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        qrCodeData: qrData,
        location: currentLocation,
        timestamp: DateTime.now(),
        notes: _selectedNotes == 'Scanned from QR Code' ? null : _selectedNotes,
        locationName: widget.locationName,
        status: _selectedStatus,
      );

      // Save directly to database
      await supabase_helper.DatabaseHelper.instance.insertOLTrap(oltrap);
      
      // Refresh the list
      await _loadScannedOLTraps();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OLTrap added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Stop camera before navigation
        await _controller?.stop();
        Navigator.pop(context, true); // Return true to indicate successful scan
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding OLTrap: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan OLTrap QR Code'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan OLTrap QR Code'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showList ? Icons.camera_alt : Icons.list),
            onPressed: () {
              setState(() {
                _showList = !_showList;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Selection
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              children: [
                Text(
                  'Status:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: OLTrapStatus.values.map((status) {
                      final isSelected = _selectedStatus == status;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedStatus = status;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.green : Colors.white,
                              border: Border.all(
                                color: isSelected ? Colors.green : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.displayName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Notes Input
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan Area Notes:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildNotesButton('Scanned from QR Code', _selectedNotes == 'Scanned from QR Code'),
                    _buildNotesButton('Missing', _selectedNotes == 'Missing'),
                    _buildNotesButton('Damaged', _selectedNotes == 'Damaged'),
                  ],
                ),
              ],
            ),
          ),
          // Scanner or List View
          Expanded(
            child: _showList 
                ? RefreshIndicator(
                    onRefresh: _loadScannedOLTraps,
                    child: _buildScannedList(),
                  )
                : _buildScannerView(),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller!,
          onDetect: _onBarcodeCapture,
        ),
        if (_isProcessing)
          Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Processing OLTrap...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Position QR code on the lawanit within the frame to automatically add the OLTrap location',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScannedList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Row(
            children: [
              Icon(Icons.list_alt, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Scanned OLTraps (${_scannedOLTraps.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _scannedOLTraps.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No QR codes scanned yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the camera icon to start scanning',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _scannedOLTraps.length,
                  itemBuilder: (context, index) {
                    final oltrap = _scannedOLTraps[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row with status
                              Row(
                                children: [
                                  // Status indicator with icon
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: oltrap.status == OLTrapStatus.deployed 
                                          ? Colors.red.shade50 
                                          : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: oltrap.status == OLTrapStatus.deployed 
                                            ? Colors.red.shade200 
                                            : Colors.orange.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          oltrap.status == OLTrapStatus.deployed 
                                              ? Icons.location_on 
                                              : Icons.location_on,
                                          color: oltrap.status == OLTrapStatus.deployed 
                                              ? Colors.red.shade700 
                                              : Colors.orange.shade700,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          oltrap.status.displayName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: oltrap.status == OLTrapStatus.deployed 
                                                ? Colors.red.shade700 
                                                : Colors.orange.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  // Delete button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.delete_outline, color: Colors.red.shade700, size: 20),
                                      onPressed: () => _showDeleteConfirmation(oltrap),
                                      tooltip: 'Delete OLTrap',
                                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // QR Code section
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.qr_code_scanner, color: Colors.grey.shade600, size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          'QR Code',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      oltrap.qrCodeData,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Details grid
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDetailCard(
                                      icon: Icons.location_on,
                                      label: 'Location',
                                      value: oltrap.locationName ?? 'Unknown',
                                      iconColor: Colors.blue.shade600,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildDetailCard(
                                      icon: Icons.calendar_today,
                                      label: 'Date',
                                      value: _formatDate(oltrap.timestamp),
                                      iconColor: Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Coordinates
                              _buildDetailCard(
                                icon: Icons.gps_fixed,
                                label: 'Coordinates',
                                value: '${oltrap.location.latitude.toStringAsFixed(6)}, ${oltrap.location.longitude.toStringAsFixed(6)}',
                                iconColor: Colors.purple.shade600,
                              ),
                              if (oltrap.notes != null && oltrap.notes!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: _buildDetailCard(
                                    icon: Icons.note_alt,
                                    label: 'Notes',
                                    value: oltrap.notes!,
                                    iconColor: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(OLTrap oltrap) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Delete OLTrap',
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
            Text(
              'Are you sure you want to delete this OLTrap?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QR Code:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    oltrap.qrCodeData,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (oltrap.locationName != null)
              Text(
                'Location: ${oltrap.locationName}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await supabase_helper.DatabaseHelper.instance.deleteOLTrap(oltrap.id);
              await _loadScannedOLTraps();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('OLTrap "${oltrap.qrCodeData}" deleted successfully'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  Widget _buildNotesButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNotes = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
