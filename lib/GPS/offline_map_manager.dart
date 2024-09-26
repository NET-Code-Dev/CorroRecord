import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Offline Region model
class OfflineRegion {
  final int id;
  final String name;
  final LatLngBounds bounds;
  final int minZoom;
  final int maxZoom;

  OfflineRegion({
    required this.id,
    required this.name,
    required this.bounds,
    required this.minZoom,
    required this.maxZoom,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'minLat': bounds.southwest.latitude,
      'minLng': bounds.southwest.longitude,
      'maxLat': bounds.northeast.latitude,
      'maxLng': bounds.northeast.longitude,
      'minZoom': minZoom,
      'maxZoom': maxZoom,
    };
  }

  static OfflineRegion fromMap(Map<String, dynamic> map) {
    return OfflineRegion(
      id: map['id'],
      name: map['name'],
      bounds: LatLngBounds(
        southwest: LatLng(map['minLat'], map['minLng']),
        northeast: LatLng(map['maxLat'], map['maxLng']),
      ),
      minZoom: map['minZoom'],
      maxZoom: map['maxZoom'],
    );
  }
}

// Database helper
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('offline_maps.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offline_regions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        minLat REAL,
        minLng REAL,
        maxLat REAL,
        maxLng REAL,
        minZoom INTEGER,
        maxZoom INTEGER
      )
    ''');
  }

  Future<int> insertOfflineRegion(OfflineRegion region) async {
    final db = await database;
    return await db.insert('offline_regions', region.toMap());
  }

  Future<List<OfflineRegion>> getOfflineRegions() async {
    final db = await database;
    final maps = await db.query('offline_regions');
    return List.generate(maps.length, (i) => OfflineRegion.fromMap(maps[i]));
  }

  Future<void> deleteOfflineRegion(int id) async {
    final db = await database;
    await db.delete('offline_regions', where: 'id = ?', whereArgs: [id]);
  }
}

// Custom Tile Provider
class CachedTileProvider extends TileProvider {
  final String urlTemplate;
  final BaseCacheManager cacheManager;

  CachedTileProvider({required this.urlTemplate, required this.cacheManager});

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    final url = urlTemplate.replaceAll('{x}', x.toString()).replaceAll('{y}', y.toString()).replaceAll('{z}', zoom.toString());

    try {
      final file = await cacheManager.getSingleFile(url);
      final bytes = await file.readAsBytes();
      return Tile(256, 256, bytes);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load tile: $e');
      }
      // Return a transparent tile in case of error
      return Tile(256, 256, Uint8List.fromList(List.filled(256 * 256 * 4, 0)));
    }
  }
}

// Main Widget
class OfflineGoogleMaps extends StatefulWidget {
  const OfflineGoogleMaps({super.key});

  @override
  createState() => _OfflineGoogleMapsState();
}

class _OfflineGoogleMapsState extends State<OfflineGoogleMaps> {
  GoogleMapController? _mapController;
  Set<TileOverlay> _offlineMaps = {};
  List<OfflineRegion> _offlineRegions = [];
  bool _isDownloading = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final BaseCacheManager _cacheManager = DefaultCacheManager();

  @override
  void initState() {
    super.initState();
    _loadOfflineRegions();
  }

  Future<void> _loadOfflineRegions() async {
    final regions = await _dbHelper.getOfflineRegions();
    setState(() {
      _offlineRegions = regions;
      _offlineMaps = regions
          .map((region) => TileOverlay(
                tileOverlayId: TileOverlayId(region.id.toString()),
                tileProvider: CachedTileProvider(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  cacheManager: _cacheManager,
                ),
              ))
          .toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Google Maps')),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(target: LatLng(0, 0), zoom: 2),
              onMapCreated: (controller) => _mapController = controller,
              tileOverlays: _offlineMaps,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _offlineRegions.length,
              itemBuilder: (context, index) {
                final region = _offlineRegions[index];
                return ListTile(
                  title: Text(region.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteOfflineRegion(region),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isDownloading ? null : _downloadOfflineRegion,
        child: _isDownloading ? const CircularProgressIndicator() : const Icon(Icons.download),
      ),
    );
  }

  Future<void> _downloadOfflineRegion() async {
    if (_mapController == null) return;

    setState(() => _isDownloading = true);

    try {
      final bounds = await _mapController!.getVisibleRegion();
      final name = 'Region ${_offlineRegions.length + 1}';
      final region = OfflineRegion(
        id: DateTime.now().millisecondsSinceEpoch,
        name: name,
        bounds: bounds,
        minZoom: 10,
        maxZoom: 15,
      );

      await _dbHelper.insertOfflineRegion(region);
      await _downloadTiles(region);

      setState(() {
        _offlineRegions.add(region);
        _offlineMaps.add(TileOverlay(
          tileOverlayId: TileOverlayId(region.id.toString()),
          tileProvider: CachedTileProvider(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            cacheManager: _cacheManager,
          ),
        ));
      });

      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Offline region downloaded successfully')),
      //   );
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading offline region: $e');
      }
      //  ScaffoldMessenger.of(context).showSnackBar(
      //    SnackBar(content: Text('Failed to download offline region')),
      //  );
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _downloadTiles(OfflineRegion region) async {
    for (int zoom = region.minZoom; zoom <= region.maxZoom; zoom++) {
      final tiles = _getTileCoordinates(region.bounds, zoom);
      for (final tile in tiles) {
        final url = 'https://tile.openstreetmap.org/$zoom/${tile.x}/${tile.y}.png';
        await _cacheManager.downloadFile(url);
      }
    }
  }

  List<Point> _getTileCoordinates(LatLngBounds bounds, int zoom) {
    final minX = _lon2tile(bounds.southwest.longitude, zoom);
    final maxX = _lon2tile(bounds.northeast.longitude, zoom);
    final minY = _lat2tile(bounds.northeast.latitude, zoom);
    final maxY = _lat2tile(bounds.southwest.latitude, zoom);

    final tiles = <Point>[];
    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        tiles.add(Point(x, y));
      }
    }
    return tiles;
  }

  int _lon2tile(double lon, int z) {
    return ((lon + 180) / 360 * (1 << z)).floor();
  }

  int _lat2tile(double lat, int z) {
    return ((1 - log(tan(lat * pi / 180) + 1 / cos(lat * pi / 180)) / pi) / 2 * (1 << z)).floor();
  }

  Future<void> _deleteOfflineRegion(OfflineRegion region) async {
    await _dbHelper.deleteOfflineRegion(region.id);
    setState(() {
      _offlineRegions.removeWhere((r) => r.id == region.id);
      _offlineMaps.removeWhere((overlay) => overlay.tileOverlayId.value == region.id.toString());
    });
//    ScaffoldMessenger.of(context).showSnackBar(
//      SnackBar(content: Text('Offline region deleted')),
//    );
  }
}
