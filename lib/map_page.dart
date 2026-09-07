import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  bool showOrtofoto = false;

  final MapController mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),

        actions: [
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
            bottom: 30,

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
    );
  }
}
