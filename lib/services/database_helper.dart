import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:latlong2/latlong.dart';
import '../models/oltrap.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;
  
  DatabaseHelper._internal();
  
  Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDatabase();
      return _database!;
    } catch (e, stackTrace) {
      print('Error initializing database: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'oltrap_database.db');
    
    return await openDatabase(
      path,
      version: 3, // Increment version for migration (add isMissing/isDamaged)
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE oltraps (
        id TEXT PRIMARY KEY,
        qr_code_data TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        notes TEXT,
        location_name TEXT,
        status TEXT NOT NULL DEFAULT 'deployed',
        isMissing INTEGER NOT NULL DEFAULT 0,
        isDamaged INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add status column to existing table
      await db.execute('ALTER TABLE oltraps ADD COLUMN status TEXT NOT NULL DEFAULT \'deployed\'');
    }
    if (oldVersion < 3) {
      // Add isMissing and isDamaged columns for version 3
      await db.execute('ALTER TABLE oltraps ADD COLUMN isMissing INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE oltraps ADD COLUMN isDamaged INTEGER NOT NULL DEFAULT 0');
    }
  }
  
  Future<int> insertOLTrap(OLTrap oltrap) async {
    final db = await database;
    return await db.insert(
      'oltraps',
      {
        'id': oltrap.id,
        'qr_code_data': oltrap.qrCodeData,
        'latitude': oltrap.location.latitude,
        'longitude': oltrap.location.longitude,
        'timestamp': oltrap.timestamp.millisecondsSinceEpoch,
        'notes': oltrap.notes,
        'location_name': oltrap.locationName,
        'status': oltrap.status.toJson,
        'isMissing': oltrap.isMissing ? 1 : 0,
        'isDamaged': oltrap.isDamaged ? 1 : 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<List<OLTrap>> getAllOLTraps() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'oltraps',
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) {
      return OLTrap(
        id: maps[i]['id'],
        qrCodeData: maps[i]['qr_code_data'],
        location: LatLng(maps[i]['latitude'], maps[i]['longitude']),
        timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']),
        notes: maps[i]['notes'],
        locationName: maps[i]['location_name'],
        status: maps[i].containsKey('status') 
            ? OLTrapStatusExtension.fromJson(maps[i]['status'])
            : OLTrapStatus.deployed,
        isMissing: maps[i].containsKey('isMissing') 
            ? (maps[i]['isMissing'] == 1)
            : false,
        isDamaged: maps[i].containsKey('isDamaged') 
            ? (maps[i]['isDamaged'] == 1)
            : false,
      );
    });
  }
  
  Future<List<OLTrap>> getOLTrapsByLocation(String locationName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'oltraps',
      where: 'location_name = ?',
      whereArgs: [locationName],
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) {
      return OLTrap(
        id: maps[i]['id'],
        qrCodeData: maps[i]['qr_code_data'],
        location: LatLng(maps[i]['latitude'], maps[i]['longitude']),
        timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']),
        notes: maps[i]['notes'],
        locationName: maps[i]['location_name'],
        status: maps[i].containsKey('status') 
            ? OLTrapStatusExtension.fromJson(maps[i]['status'])
            : OLTrapStatus.deployed,
        isMissing: maps[i].containsKey('isMissing') 
            ? (maps[i]['isMissing'] == 1)
            : false,
        isDamaged: maps[i].containsKey('isDamaged') 
            ? (maps[i]['isDamaged'] == 1)
            : false,
      );
    });
  }
  
  Future<int> updateOLTrap(OLTrap oltrap) async {
    final db = await database;
    return await db.update(
      'oltraps',
      {
        'qr_code_data': oltrap.qrCodeData,
        'latitude': oltrap.location.latitude,
        'longitude': oltrap.location.longitude,
        'timestamp': oltrap.timestamp.millisecondsSinceEpoch,
        'notes': oltrap.notes,
        'location_name': oltrap.locationName,
        'status': oltrap.status.toJson,
      },
      where: 'id = ?',
      whereArgs: [oltrap.id],
    );
  }
  
  Future<int> deleteOLTrap(String id) async {
    final db = await database;
    return await db.delete(
      'oltraps',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<bool> qrCodeExists(String qrCodeData) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'oltraps',
      where: 'qr_code_data = ?',
      whereArgs: [qrCodeData],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<List<String>> getAllLocationNames() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'oltraps',
      columns: ['location_name'],
      distinct: true,
      where: 'location_name IS NOT NULL',
      orderBy: 'location_name ASC',
    );
    
    return maps.map((map) => map['location_name'] as String).toList();
  }
  
  Future<void> clearAllOLTraps() async {
    final db = await database;
    await db.delete('oltraps');
  }
  
  Future<void> mergeOLTraps(List<OLTrap> newTraps) async {
    final db = await database;
    final batch = db.batch();
    
    for (final trap in newTraps) {
      // Check if trap already exists by QR code
      final existingMaps = await db.query(
        'oltraps',
        where: 'qr_code_data = ?',
        whereArgs: [trap.qrCodeData],
        limit: 1,
      );
      
      if (existingMaps.isEmpty) {
        // Insert new trap
        batch.insert('oltraps', trap.toMap());
      }
    }
    
    await batch.commit(noResult: true);
  }
  
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
