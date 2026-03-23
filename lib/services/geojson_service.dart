import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:latlong2/latlong.dart';
import '../models/oltrap.dart';

class GeoJSONService {
  static Future<String> exportToGeoJSON(List<OLTrap> oltraps) async {
    final features = oltraps.map((oltrap) => {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [oltrap.location.longitude, oltrap.location.latitude],
      },
      'properties': {
        'id': oltrap.id,
        'qrCodeData': oltrap.qrCodeData,
        'timestamp': oltrap.timestamp.toIso8601String(),
        'notes': oltrap.notes,
        'locationName': oltrap.locationName,
      },
    }).toList();

    final geoJson = {
      'type': 'FeatureCollection',
      'features': features,
    };

    return const JsonEncoder.withIndent('  ').convert(geoJson);
  }

  static Future<List<OLTrap>> importFromGeoJSON() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'geojson'],
      );

      if (result == null || result.files.isEmpty) return [];

      final file = result.files.first;
      final content = await file.xFile.readAsString();
      
      final geoJson = jsonDecode(content) as Map<String, dynamic>;
      
      if (geoJson['type'] != 'FeatureCollection') {
        throw Exception('Invalid GeoJSON format. Expected FeatureCollection.');
      }

      final features = geoJson['features'] as List;
      return features.map((feature) {
        final properties = feature['properties'] as Map<String, dynamic>;
        final geometry = feature['geometry'] as Map<String, dynamic>;
        final coordinates = geometry['coordinates'] as List;
        
        return OLTrap(
          id: properties['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          qrCodeData: properties['qrCodeData'] ?? 'Imported',
          location: LatLng(coordinates[1], coordinates[0]), // lat, lng order
          timestamp: DateTime.parse(properties['timestamp'] ?? DateTime.now().toIso8601String()),
          notes: properties['notes'],
          locationName: properties['locationName'],
        );
      }).toList();
    } catch (e) {
      throw Exception('Error importing GeoJSON: $e');
    }
  }

  static Future<void> saveGeoJSONFile(String content, String filename) async {
    try {
      final result = await FilePicker.platform.saveFile(
        fileName: '$filename.geojson',
        type: FileType.custom,
        allowedExtensions: ['geojson'],
        bytes: utf8.encode(content),
      );
      
      if (result != null) {
        print('GeoJSON saved to: $result');
      }
    } catch (e) {
      throw Exception('Error saving GeoJSON file: $e');
    }
  }
}
