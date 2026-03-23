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

  OLTrap({
    required this.id,
    required this.qrCodeData,
    required this.location,
    required this.timestamp,
    this.notes,
    this.locationName,
    this.status = OLTrapStatus.deployed,
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
    };
  }

  factory OLTrap.fromJson(Map<String, dynamic> json) {
    return OLTrap(
      id: json['id'],
      qrCodeData: json['qrCodeData'],
      location: LatLng(
        json['location']['latitude'],
        json['location']['longitude'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      notes: json['notes'],
      locationName: json['locationName'],
      status: json.containsKey('status') 
          ? OLTrapStatusExtension.fromJson(json['status'])
          : OLTrapStatus.deployed,
    );
  }

  OLTrap copyWith({
    String? id,
    String? qrCodeData,
    LatLng? location,
    DateTime? timestamp,
    String? notes,
    String? locationName,
    OLTrapStatus? status,
  }) {
    return OLTrap(
      id: id ?? this.id,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      locationName: locationName ?? this.locationName,
      status: status ?? this.status,
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
}
