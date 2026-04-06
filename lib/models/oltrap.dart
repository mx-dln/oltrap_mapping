import 'package:latlong2/latlong.dart';

enum OLTrapStatus {
  deployed,
  harvested;
}

extension OLTrapStatusExtension on OLTrapStatus {
  String get displayName {
    switch (this) {
      case OLTrapStatus.deployed:
        return 'Deployed';
      case OLTrapStatus.harvested:
        return 'Harvested';
    }
  }

  String get toJson {
    switch (this) {
      case OLTrapStatus.deployed:
        return 'deployed';
      case OLTrapStatus.harvested:
        return 'harvested';
    }
  }

  static OLTrapStatus fromJson(String json) {
    switch (json) {
      case 'deployed':
        return OLTrapStatus.deployed;
      case 'harvested':
        return OLTrapStatus.harvested;
      default:
        return OLTrapStatus.deployed;
    }
  }
}

class OLTrap {
  final String id;
  final String qrCodeData;
  final LatLng location;
  final DateTime timestamp;
  final String? notes;
  final String? locationName;
  final OLTrapStatus status;
  final bool isMissing;
  final bool isDamaged;

  OLTrap({
    required this.id,
    required this.qrCodeData,
    required this.location,
    required this.timestamp,
    this.notes,
    this.locationName,
    this.status = OLTrapStatus.deployed,
    this.isMissing = false,
    this.isDamaged = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'qrCodeData': qrCodeData,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'locationName': locationName,
      'status': status.toJson,
      'isMissing': isMissing,
      'isDamaged': isDamaged,
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        final intValue = int.tryParse(timestamp) ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(intValue);
      }
    }
    
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    
    if (timestamp is double) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    }
    return DateTime.now();
  }

  factory OLTrap.fromJson(Map<String, dynamic> json) {
    return OLTrap(
      id: json['id'] ?? '',
      qrCodeData: json['qr_code_data'] ?? '',
      location: LatLng(
        json['latitude']?.toDouble() ?? 0.0,
        json['longitude']?.toDouble() ?? 0.0,
      ),
      timestamp: _parseTimestamp(json['timestamp']),
      notes: json['notes'],
      locationName: json['location_name'],
      status: json.containsKey('status') 
          ? OLTrapStatusExtension.fromJson(json['status'])
          : OLTrapStatus.deployed,
      isMissing: _parseBool(json['isMissing']),
      isDamaged: _parseBool(json['isDamaged']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is int) {
      return value == 1;
    }
    return false;
  }

  OLTrap copyWith({
    String? id,
    String? qrCodeData,
    LatLng? location,
    DateTime? timestamp,
    String? notes,
    String? locationName,
    OLTrapStatus? status,
    bool? isMissing,
    bool? isDamaged,
  }) {
    return OLTrap(
      id: id ?? this.id,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      locationName: locationName ?? this.locationName,
      status: status ?? this.status,
      isMissing: isMissing ?? this.isMissing,
      isDamaged: isDamaged ?? this.isDamaged,
    );
  }

  @override
  String toString() {
    return 'OLTrap(id: $id, location: ${location.latitude}, ${location.longitude}, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OLTrap &&
        other.id == id &&
        other.qrCodeData == qrCodeData &&
        other.location == location &&
        other.timestamp == timestamp &&
        other.notes == notes &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        qrCodeData.hashCode ^
        location.hashCode ^
        timestamp.hashCode ^
        notes.hashCode ^
        status.hashCode;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'qr_code_data': qrCodeData,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'timestamp': timestamp.millisecondsSinceEpoch.toString(),
      'notes': notes,
      'location_name': locationName,
      'status': status.toJson,
      'isMissing': isMissing,
      'isDamaged': isDamaged,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
