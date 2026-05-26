import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class OfflineMapService {
  static const String bundledAssetPath = 'assets/maps/oltrap.mbtiles';
  static const String localFileName = 'oltrap.mbtiles';

  static Future<MbTilesTileProvider?> loadTileProvider() async {
    final mbtilesPath = await _ensureLocalMbtiles();
    if (mbtilesPath == null) return null;

    return MbTilesTileProvider.fromPath(path: mbtilesPath);
  }

  static Future<String?> _ensureLocalMbtiles() async {
    final supportDir = await getApplicationSupportDirectory();
    final mapsDir = Directory(path.join(supportDir.path, 'offline_maps'));
    if (!await mapsDir.exists()) {
      await mapsDir.create(recursive: true);
    }

    final localFile = File(path.join(mapsDir.path, localFileName));
    if (await localFile.exists() && await localFile.length() > 0) {
      return localFile.path;
    }

    try {
      final data = await rootBundle.load(bundledAssetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await localFile.writeAsBytes(bytes, flush: true);
      return localFile.path;
    } on FlutterError {
      return null;
    } on FileSystemException {
      return null;
    }
  }
}
