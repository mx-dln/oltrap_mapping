import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class SearchQRScannerScreen extends StatefulWidget {
  const SearchQRScannerScreen({super.key});

  @override
  State<SearchQRScannerScreen> createState() => _SearchQRScannerScreenState();
}

class _SearchQRScannerScreenState extends State<SearchQRScannerScreen> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
        content: const Text('Camera permission is required to scan QR codes for search. Please enable it in settings.'),
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
      // Stop camera before returning
      await _controller?.stop();
      
      if (mounted) {
        // Return the QR code data for search
        Navigator.pop(context, qrData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing QR code: $e'),
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
          title: const Text('Scan QR Code for Search'),
          backgroundColor: Colors.blue,
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
        title: const Text('Scan QR Code for Search'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            await _controller?.stop();
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
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
                      'Processing QR code...',
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
                'Position QR code within frame to search for OLTrap',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
