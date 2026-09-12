// Podstawowe elementy frameworka Flutter,
import 'package:flutter/material.dart';
// Biblioteka służąca do wyświetlania map
import 'package:flutter_map/flutter_map.dart';
// Biblioteka zawierająca klasy związane ze współrzędnymi
import 'package:latlong2/latlong.dart';

import 'package:moj_projekt_flutter/results_page.dart';

import 'login_page.dart';

// Biblioteka umożliwiająca korzystanie z operacji asynchronicznych
import 'dart:async';

// Biblioteka służąca do pobierania lokalizacji urządzenia
import 'package:geolocator/geolocator.dart';

// Biblioteka służąca m.in. do kodowania danych do formatu JSON.
import 'dart:convert';
// Biblioteka umożliwiająca pracę z plikami i systemem plików urządzenia.
import 'dart:io';

// Biblioteka pozwalająca uzyskać dostęp do katalogów aplikacji.
import 'package:path_provider/path_provider.dart';
// Biblioteka pozwalająca udostępniać pliki
import 'package:share_plus/share_plus.dart';

// MapPage jest stroną zawierającą mapę
// StatefulWidget jest używany, ponieważ podczas działania strony zmieniają się jej dane
class MapPage extends StatefulWidget {
  // Konstruktor strony mapy.
  const MapPage({super.key});

  // Utworzenie obiektu przechowującego stan strony.
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Określa, który podkład mapowy jest aktualnie wyświetlany.
  bool showOrtofoto = false;

  // Umożliwia programowe sterowanie mapą
  final MapController mapController = MapController();

  // Obiekt przechowujący aktywną subskrypcję strumienia danych GPS.
  StreamSubscription<Position>? positionStream;

  // Lista wszystkich punktów GPS
  List<Position> routePoints = [];

  // Informuje, czy pomiar GPS jest aktualnie wykonywany.
  bool isMeasuring = false;

  // Funkcja uruchamiająca rejestrowanie pozycji GPS.
  // Future<void> oznacza, że funkcja wykonuje operacje asynchroniczne i może oczekiwać na ich zakończenie.
  Future<void> startMeasurement() async {
    // Jeżeli pomiar już trwa, nie uruchamiamy kolejnego.
    if (isMeasuring) {
      return;
    }

    // Sprawdzenie, czy usługi lokalizacyjne urządzenia są włączone.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usługi lokalizacyjne są wyłączone')),
      );
      return;
    }

    // Sprawdzenie aktualnego stanu uprawnień aplikacji do korzystania z lokalizacji.
    LocationPermission permission = await Geolocator.checkPermission();

    // Jeżeli użytkownik nie udzielił jeszcze zgody, aplikacja prosi o przyznanie uprawnienia.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak uprawnień do lokalizacji')),
      );
      // Pomiar nie może zostać rozpoczęty.
      return;
    }

    // Usunięcie punktów zapisanych podczas poprzedniego pomiaru.
    routePoints.clear();

    // Aktualizacja stanu strony.
    setState(() {
      isMeasuring = true;
    });

    // Określenie sposobu pobierania pozycji GPS.
    final LocationSettings locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,

      // distanceFilter = 0 oznacza, że pozycja może być rejestrowana niezależnie od przebytej odległości.
      distanceFilter: 0,

      intervalDuration: const Duration(seconds: 1),
    );

    bool firstPosition = true;

    // getPositionStream() będzie dostarczał kolejne pozycje GPS urządzenia.
    // listen() wykonuje podaną funkcję za każdym razem, gdy pojawi się nowa pozycja.
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
              // Jeżeli pomiar został zakończony, ignorujemy kolejne pozycje.
              if (!isMeasuring) return;

              setState(() {
                routePoints.add(position);
              });

              if (firstPosition) {
                // Przesunięcie mapy na aktualną pozycję GPS.
                mapController.move(
                  LatLng(position.latitude, position.longitude),
                  17,
                );

                // Po pierwszym ustawiamy false, aby kolejne punkty nie przesuwały automatycznie.
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

  // Funkcja zatrzymująca aktualnie wykonywany pomiar GPS.
  void stopMeasurement() {
    // Anulowanie subskrypcji strumienia GPS.
    positionStream?.cancel();
    // Usunięcie odwołania do zakończonego strumienia.
    positionStream = null;
    // Aktualizacja stanu aplikacji.
    setState(() {
      isMeasuring = false;
    });
    print('Pomiar zakończony.');
    print('Liczba zapisanych punktów: ${routePoints.length}');
  }

  // Funkcja resetująca aktualny pomiar.
  void resetMeasurement() {
    positionStream?.cancel();
    // Wyzerowanie referencji do strumienia.
    positionStream = null;
    setState(() {
      isMeasuring = false;
      // Usunięcie wszystkich zapisanych punktów trasy.
      routePoints.clear();
    });
    print('Pomiar i trasa zostały wyczyszczone.');
  }

  // Funkcja zapisująca aktualnie zarejestrowaną trasę
  Future<void> saveMeasurement() async {
    if (routePoints.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Brak trasy do zapisania')));
      return;
    }

    // Tworzenie obiektu zawierającego dane w strukturze GeoJSON.
    // "Feature" oznacza pojedynczy obiekt przestrzenny.
    final geoJson = {
      "type": "Feature",
      // Atrybuty
      "properties": {
        "created_at": DateTime.now().toIso8601String(),
        "points_count": routePoints.length,
        "points": routePoints.map((position) {
          // Utworzenie zestawu atrybutów dla pojedynczego punktu.
          return {
            "latitude": position.latitude,
            "longitude": position.longitude,
            // ? oznacza możliwość pusego atrybutu
            "timestamp": position.timestamp?.toIso8601String(),
            "accuracy": position.accuracy,
            "altitude": position.altitude,
            "speed": position.speed,
          };
        }).toList(),
      },

      "geometry": {
        // Typ geometrii.
        "type": "LineString",

        // Utworzenie listy współrzędnych tworzących trasę.
        "coordinates": routePoints.map((position) {
          return [position.longitude, position.latitude];
        }).toList(),
      },
    };

    // ========================================================
    // 15. UTWORZENIE NAZWY I LOKALIZACJI PLIKU
    // ========================================================

    // Pobranie katalogu dokumentów aplikacji.
    final directory = await getApplicationDocumentsDirectory();

    // Utworzenie znacznika czasu, który zostanie wykorzystany
    // w nazwie pliku.
    //
    // Zamiana ":" i "." na "-" pozwala uniknąć problemów
    // z nazwą pliku.
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');

    // Utworzenie obiektu reprezentującego plik.
    final file = File('${directory.path}/trasa_$timestamp.geojson');

    // jsonEncode() zamienia strukturę Dart na tekst w formacie JSON.
    await file.writeAsString(jsonEncode(geoJson));

    // Sprawdzenie, czy widget nadal istnieje.
    // Jest to ważne po operacji asynchronicznej, ponieważ użytkownik mógł w tym czasie opuścić stronę.
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Trasa została zapisana\n${file.path}')),
    );
    print('Zapisano trasę: ${file.path}');
  }

  // Funkcja wyszukująca zapisane trasy GeoJSON i przekazująca je do mechanizmu udostępniania.
  Future<void> exportRoutes() async {
    try {
      // Pobranie katalogu dokumentów aplikacji.
      final directory = await getApplicationDocumentsDirectory();
      // Pobranie listy elementów znajdujących się w katalogu.
      final files = directory
          .listSync()
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('.geojson') &&
                file.path
                    .split(Platform.pathSeparator)
                    .last
                    .startsWith('trasa_'),
          )
          .toList();

      if (files.isEmpty) {
        // Sprawdzenie, czy strona nadal istnieje.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Brak zapisanych tras do eksportu')),
        );
        return;
      }

      // Wywołanie systemowego mechanizmu udostępniania.
      await SharePlus.instance.share(
        // ShareParams zawiera informacje przekazywane do mechanizmu udostępniania.
        ShareParams(
          title: 'Eksport tras',
          text: 'Zapisane trasy GPS',
          // Zamiana obiektów File na XFile,
          files: files.map((file) => XFile(file.path)).toList(),
        ),
      );
    } catch (e) {
      // Sprawdzenie, czy strona nadal istnieje.
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Błąd eksportu: $e')));
    }
  }

  // Metoda build() tworzy cały interfejs strony mapy.
  @override
  Widget build(BuildContext context) {
    // Scaffold tworzy podstawową strukturę strony.
    return Scaffold(
      // AppBar znajduje się w górnej części ekranu.
      appBar: AppBar(
        title: const Text('WalkTracker'),
        // actions zawiera przyciski
        actions: [
          IconButton(
            // Ikona zależy od aktualnego podkładu.
            icon: Icon(showOrtofoto ? Icons.map : Icons.satellite_alt),
            tooltip: showOrtofoto
                ? 'Przełącz na OSM'
                : 'Przełącz na ortofotomapę',
            onPressed: () {
              // Zmiana wartości showOrtofoto na przeciwną.
              setState(() {
                showOrtofoto = !showOrtofoto;
              });
            },
          ),

          // PopupMenuButton tworzy rozwijane menu użytkownika.
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Menu użytkownika',
            onSelected: (value) {
              if (value == 'logout') {
                // pushAndRemoveUntil() usuwa wszystkie wcześniejsze strony ze stosu nawigacji.
                Navigator.pushAndRemoveUntil(
                  context,
                  // Strona, do której przechodzimy.
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  // false oznacza, że wszystkie poprzednie strony mają zostać usunięte.
                  (route) => false,
                );
              }
            },

            // Elementy znajdujące się w rozwijanym menu.
            itemBuilder: (context) => [
              // Opcja "Wyloguj".
              const PopupMenuItem<String>(
                value: 'logout',
                // Zawartość elementu menu.
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    // Odstęp pomiędzy ikoną a tekstem.
                    SizedBox(width: 10),
                    Text('Wyloguj'),
                  ],
                ),
              ),
            ],
          ),
          // Niewielki odstęp od prawej krawędzi.
          const SizedBox(width: 5),
        ],
      ),

      // Stack pozwala nakładać na siebie kilka widgetów.
      body: Stack(
        children: [
          // FlutterMap tworzy interaktywną mapę.
          FlutterMap(
            mapController: mapController,
            // Podstawowe ustawienia mapy.
            options: const MapOptions(
              initialCenter: LatLng(52.2297, 21.0122),
              initialZoom: 12,
              minZoom: 5,
              maxZoom: 19,
            ),

            // Lista warstw wyświetlanych na mapie.
            children: [
              // Warstwa OSM jest dodawana tylko wtedy, gdy showOrtofoto == false.
              if (!showOrtofoto)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // Identyfikator aplikacji korzystającej z danych mapowych.
                  userAgentPackageName: 'com.example.moj_projekt_flutter',
                  maxZoom: 19,
                ),

              // Ortofotomapa jest dodawana tylko wtedy, gdy showOrtofoto == true.
              if (showOrtofoto)
                TileLayer(
                  // Konfiguracja połączenia z usługą WMS.
                  wmsOptions: WMSTileLayerOptions(
                    baseUrl: 'https://mapy.geoportal.gov.pl/wss/service/PZGIK/ORTO/WMS/StandardResolution?',
                    layers: const ['Raster'],
                    format: 'image/jpeg',
                    transparent: false,
                    version: '1.3.0',
                  ),

                  // Identyfikator aplikacji.
                  userAgentPackageName: 'com.example.moj_projekt_flutter',
                ),

              // PolylineLayer służy do wyświetlenia linii
              PolylineLayer(
                polylines: [
                  if (routePoints.length >= 2)
                    Polyline(
                      // Zamiana obiektów Position na LatLng,
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

              // RichAttributionWidget wyświetla informacje o źródle wykorzystanych danych mapowych.
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

          // Positioned pozwala określić dokładne położenie elementu wewnątrz Stack.
          Positioned(
            right: 15,
            bottom: 90,
            child: Column(
              children: [
                FloatingActionButton(
                  // Unikalny identyfikator przycisku.
                  heroTag: 'zoom_in',
                  mini: true,
                  onPressed: () {
                    // Przesunięcie mapy na jej aktualne centrum i zwiększenie poziomu powiększenia o 1.
                    mapController.move(
                      mapController.camera.center,
                      mapController.camera.zoom + 1,
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                // Odstęp pomiędzy przyciskami.
                const SizedBox(height: 8),

                FloatingActionButton(
                  // Unikalny identyfikator przycisku.
                  heroTag: 'zoom_out',
                  mini: true,
                  onPressed: () {
                    // Zachowanie aktualnego środka mapy i zmniejszenie poziomu powiększenia o 1.
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

      // BottomAppBar tworzy pasek znajdujący się na dole ekranu.
      bottomNavigationBar: BottomAppBar(
        // Row układa przyciski poziomo.
        child: Row(
          // Rozstawienie przycisków z równymi odstępami.
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Rozpocznij pomiar',
              onPressed: startMeasurement,
            ),

            IconButton(
              icon: const Icon(Icons.stop),
              tooltip: 'Zakończ pomiar',
              onPressed: stopMeasurement,
            ),

            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Resetuj',
              onPressed: resetMeasurement,
            ),

            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Zapisz',
              onPressed: saveMeasurement,
            ),

            IconButton(
              icon: const Icon(Icons.analytics),
              tooltip: 'Wyniki',
              onPressed: () {
                // Przejście do strony ResultsPage.
                // push() dodaje nową stronę do stosu nawigacji, dzięki czemu można później wrócić do mapy.
                Navigator.push(
                  context,
                  // Utworzenie strony wyników.
                  MaterialPageRoute(builder: (context) => const ResultsPage()),
                );
              },
            ),

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
