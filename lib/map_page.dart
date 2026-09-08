import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:moj_projekt_flutter/results_page.dart';

import 'login_page.dart';

import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  bool showOrtofoto = false;

  final MapController mapController = MapController();

  StreamSubscription<Position>? positionStream;
  List<Position> routePoints = [];
  bool isMeasuring = false;

  Future<void> startMeasurement() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usługi lokalizacyjne są wyłączone')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak uprawnień do lokalizacji')),
      );
      return;
    }

    routePoints.clear();

    setState(() {
      isMeasuring = true;
    });

    final LocationSettings locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      intervalDuration: const Duration(seconds: 1),
    );

    bool firstPosition = true;

    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
              if (!isMeasuring) return;

              setState(() {
                routePoints.add(position);
              });

              if (firstPosition) {
                mapController.move(
                  LatLng(position.latitude, position.longitude),
                  17,
                );

                firstPosition = false;
              }

              print(
                'Pozycja: '
                '${position.latitude}, '
                '${position.longitude} '
                '${position.timestamp}',
              );
            });
  }

  void stopMeasurement() {
    positionStream?.cancel();
    positionStream = null;

    setState(() {
      isMeasuring = false;
    });

    print('Pomiar zakończony.');
    print('Liczba zapisanych punktów: ${routePoints.length}');
  }

  void resetMeasurement() {
    positionStream?.cancel();
    positionStream = null;
    setState(() {
      isMeasuring = false;
      routePoints.clear();
    });
    print('Pomiar i trasa zostały wyczyszczone.');
  }

  Future<void> saveMeasurement() async {
    if (routePoints.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Brak trasy do zapisania')));
      return;
    }
    final geoJson = {
      "type": "Feature",
      "properties": {
        "created_at": DateTime.now().toIso8601String(),
        "points_count": routePoints.length,

        "points": routePoints.map((position) {
          return {
            "latitude": position.latitude,
            "longitude": position.longitude,
            "timestamp": position.timestamp.toIso8601String(),
            "accuracy": position.accuracy,
            "altitude": position.altitude,
            "speed": position.speed,
          };
        }).toList(),
      },
      "geometry": {
        "type": "LineString",
        "coordinates": routePoints.map((position) {
          return [position.longitude, position.latitude];
        }).toList(),
      },
    };

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${directory.path}/trasa_$timestamp.geojson');
    await file.writeAsString(jsonEncode(geoJson));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Trasa została zapisana\n${file.path}')),
    );
    print('Zapisano trasę: ${file.path}');
  }

  Future<void> exportRoutes() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory
        .listSync()
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.geojson') &&
              file.path.split(Platform.pathSeparator).last.startsWith('trasa_'),
        )
        .toList();
    if (files.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak zapisanych tras do eksportu')),
      );
      return;
    }
    // Udostępnienie wszystkich plików GeoJSON
    await SharePlus.instance.share(
      ShareParams(
        text: 'Zapisane trasy GPS',
        files: files.map((file) => XFile(file.path)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WalkTracker'),

        actions: [
          // ZMIANA MAPY
          IconButton(
            icon: Icon(showOrtofoto ? Icons.map : Icons.satellite_alt),
            tooltip: showOrtofoto
                ? 'Przełącz na OSM'
                : 'Przełącz na ortofotomapę',

            onPressed: () {
              setState(() {
                showOrtofoto = !showOrtofoto;
              });
            },
          ),

          // MENU UŻYTKOWNIKA
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Menu użytkownika',

            onSelected: (value) {
              if (value == 'logout') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },

            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'logout',

                child: Row(
                  children: [
                    Icon(Icons.logout),

                    SizedBox(width: 10),

                    Text('Wyloguj'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(width: 5),
        ],
      ),

      body: Stack(
        children: [
          // MAPA
          FlutterMap(
            mapController: mapController,

            options: const MapOptions(
              initialCenter: LatLng(52.2297, 21.0122),
              initialZoom: 12,
              minZoom: 5,
              maxZoom: 19,
            ),

            children: [
              if (!showOrtofoto)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                  userAgentPackageName: 'com.example.moj_projekt_flutter',

                  maxZoom: 19,
                ),

              if (showOrtofoto)
                TileLayer(
                  wmsOptions: WMSTileLayerOptions(
                    baseUrl: 'https://mapy.geoportal.gov.pl/wss/service/PZGIK/ORTO/WMS/StandardResolution?',

                    layers: const ['Raster'],

                    format: 'image/jpeg',
                    transparent: false,
                    version: '1.3.0',
                  ),

                  userAgentPackageName: 'com.example.moj_projekt_flutter',
                ),

              PolylineLayer(
                polylines: [
                  if (routePoints.length >= 2)
                    Polyline(
                      points: routePoints
                          .map(
                            (position) =>
                                LatLng(position.latitude, position.longitude),
                          )
                          .toList(),
                      strokeWidth: 5,
                    ),
                ],
              ),

              RichAttributionWidget(
                attributions: [
                  if (!showOrtofoto)
                    const TextSourceAttribution('OpenStreetMap contributors'),

                  if (showOrtofoto)
                    const TextSourceAttribution('Geoportal.gov.pl'),
                ],
              ),
            ],
          ),

          Positioned(
            right: 15,
            bottom: 90,

            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,

                  onPressed: () {
                    mapController.move(
                      mapController.camera.center,
                      mapController.camera.zoom + 1,
                    );
                  },

                  child: const Icon(Icons.add),
                ),

                const SizedBox(height: 8),

                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,

                  onPressed: () {
                    mapController.move(
                      mapController.camera.center,
                      mapController.camera.zoom - 1,
                    );
                  },

                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Rozpocznij pomiar
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Rozpocznij pomiar',
              onPressed: startMeasurement,
            ),

            // Zakończ pomiar
            IconButton(
              icon: const Icon(Icons.stop),
              tooltip: 'Zakończ pomiar',
              onPressed: stopMeasurement,
            ),

            // Resetuj
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Resetuj',
              onPressed: resetMeasurement,
            ),

            // Zapisz
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Zapisz',
              onPressed: saveMeasurement,
            ),

            // Wyniki
            IconButton(
              icon: const Icon(Icons.analytics),
              tooltip: 'Wyniki',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ResultsPage()),
                );
              },
            ),

            // Eksportuj
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: 'Eksportuj',
              onPressed: exportRoutes,
            ),
          ],
        ),
      ),
    );
  }
}
