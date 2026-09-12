// Biblioteka do kodowania i dekodowania danych JSON.
import 'dart:convert';
// Biblioteka do pracy z plikami i systemem plików.
import 'dart:io';

// Podstawowe widgety Fluttera i Material Design.
import 'package:flutter/material.dart';
// Biblioteka do wyświetlania map.
import 'package:flutter_map/flutter_map.dart';
// Biblioteka zawierająca klasę LatLng
import 'package:latlong2/latlong.dart';
// Biblioteka umożliwiająca dostęp do katalogu dokumentów aplikacji.
import 'package:path_provider/path_provider.dart';

// ResultsPage odpowiada za wyświetlenie listy tras zapisanych w plikach GeoJSON.
//
// StatefulWidget jest używany, ponieważ lista plików może się zmieniać
class ResultsPage extends StatefulWidget {
  // Konstruktor strony.
  const ResultsPage({super.key});
  // Utworzenie obiektu przechowującego stan strony.
  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  // Lista plików reprezentujących zapisane trasy.
  List<File> routeFiles = [];
  // Informacja, czy lista tras jest aktualnie wczytywana.
  bool isLoading = true;

  // initState() jest wywoływane jeden raz
  @override
  void initState() {
    // Wywołanie implementacji klasy nadrzędnej.
    super.initState();
    // Automatyczne wczytanie zapisanych tras
    loadRoutes();
  }

  Future<void> loadRoutes() async {
    // Pobranie katalogu dokumentów aplikacji,
    final directory = await getApplicationDocumentsDirectory();
    // Pobranie zawartości katalogu.
    final files = directory
        .listSync()
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.geojson') &&
              file.path.split(Platform.pathSeparator).last.startsWith('trasa_'),
        )
        .toList();

    // Posortowanie tras
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    // Sprawdzenie, czy widget nadal znajduje się w drzewie widgetów.
    if (!mounted) return;

    // Aktualizacja interfejsu.
    setState(() {
      // Przypisanie znalezionych plików do listy tras.
      routeFiles = files;
      isLoading = false;
    });
  }

  Future<void> deleteRoute(File file) async {
    await file.delete();
    // Ponowne wczytanie listy tras.
    await loadRoutes();
  }

  // Funkcja zamienia obiekt DateTime na bardziej czytelny zapis:
  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold tworzy podstawową strukturę strony.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zapisane wyniki'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Wróć do mapy',
          // Po naciśnięciu następuje powrót
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),

      // Operator warunkowy wybiera, co ma zostać wyświetlone.
      body: isLoading
          // TRWA ŁADOWANIE
          ? const Center(child: CircularProgressIndicator())
          // BRAK ZAPISANYCH TRAS
          : routeFiles.isEmpty
          ? const Center(
              child: Text(
                'Brak zapisanych tras',
                style: TextStyle(fontSize: 18),
              ),
            )
          // LISTA ZAPISANYCH TRAS
          : ListView.builder(
              // Liczba elementów na liście odpowiada liczbie znalezionych plików.
              itemCount: routeFiles.length,
              // Funkcja tworząca pojedynczy element listy.
              itemBuilder: (context, index) {
                // Pobranie pliku o konkretnym indeksie.
                final file = routeFiles[index];
                // Pobranie samej nazwy pliku,
                final fileName = file.path.split(Platform.pathSeparator).last;
                // ListTile tworzy pojedynczy wiersz listy.
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.route)),
                  title: Text(
                    fileName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Data ostatniej modyfikacji pliku.
                  subtitle: Text(formatDate(file.lastModifiedSync())),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                        context: context,
                        // Funkcja budująca okno dialogowe.
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Usuń trasę'),
                            content: const Text(
                              'Czy na pewno chcesz usunąć tę trasę?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Anuluj'),
                              ),

                              TextButton(
                                // Funkcja asynchroniczna, ponieważ usuwanie pliku może potrwać.
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await deleteRoute(file);
                                },
                                child: const Text('Usuń'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  // Funkcja wykonywana po kliknięciu całego elementu listy.
                  onTap: () {
                    // Przejście do strony szczegółów.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // Do RouteDetailsPage przekazywana jest ścieżka wybranego pliku.
                        builder: (context) =>
                            RouteDetailsPage(filePath: file.path),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// RouteDetailsPage wyświetla dane dotyczące jednej wybranej trasy.
class RouteDetailsPage extends StatefulWidget {
  // Ścieżka do pliku zawierającego trasę.
  final String filePath;
  // Konstruktor wymaga podania filePath.
  const RouteDetailsPage({super.key, required this.filePath});

  // Utworzenie stanu strony.
  @override
  State<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends State<RouteDetailsPage> {
  List<LatLng> routePoints = [];
  double distance = 0.0;
  Duration duration = Duration.zero;
  double averageSpeed = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Wczytanie trasy po otwarciu strony.
    loadRoute();
  }

  Future<void> loadRoute() async {
    try {
      // Utworzenie obiektu File
      final file = File(widget.filePath);
      // Odczyt całej zawartości pliku jako tekst.
      final content = await file.readAsString();
      // Zamiana tekstu JSON na strukturę danych Dart.
      final geoJson = jsonDecode(content);

      // Pobranie zapisanej wcześniej listy punktów GPS z sekcji properties -> points.
      final pointsData = geoJson['properties']['points'] as List;

      // Każdy zapisany punkt jest zamieniany na LatLng
      routePoints = pointsData
          .map(
            (point) => LatLng(
              (point['latitude'] as num).toDouble(),
              (point['longitude'] as num).toDouble(),
            ),
          )
          .toList();

      final distanceCalculator = const Distance();
      double totalDistance = 0.0;

      // Pętla rozpoczyna się od drugiego punktu, bo każdy jest porównywany z poprzednim.
      for (int i = 1; i < routePoints.length; i++) {
        totalDistance += distanceCalculator.as(
          LengthUnit.Meter,
          routePoints[i - 1],
          routePoints[i],
        );
      }
      // Przypisanie obliczonej sumy do zmiennej distance.
      distance = totalDistance;

      // Pobranie znaczników czasu ze wszystkich punktów.
      final timestamps = pointsData
          // Pobranie pola timestamp.
          .map((point) => point['timestamp'])
          // Usunięcie wartości null.
          .where((timestamp) => timestamp != null)
          // Zamiana tekstu na obiekty DateTime.
          .map((timestamp) => DateTime.parse(timestamp.toString()))
          // Zamiana wyniku na listę.
          .toList();

      if (timestamps.length >= 2) {
        final startTime = timestamps.first;
        final endTime = timestamps.last;
        duration = endTime.difference(startTime);
      }

      if (duration.inSeconds > 0) {
        averageSpeed = (distance / duration.inSeconds) * 3.6;
      } else {
        averageSpeed = 0.0;
      }
      // Sprawdzenie, czy widget nadal istnieje.
      if (!mounted) return;
      // Zakończenie ładowania danych.
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      // Informacja o błędzie w konsoli.
      print('Błąd podczas wczytywania trasy: $e');
      if (!mounted) return;
      // Nawet w przypadku błędu kończymy stan ładowania.
      setState(() {
        isLoading = false;
      });
    }
  }

  // Funkcja zamienia Duration na czytelny tekst.
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    // remainder(60) - reszta z dzielenia przez 60
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours h $minutes min $seconds s';
    }
    return '$minutes min $seconds s';
  }

  @override
  Widget build(BuildContext context) {
    // Jeżeli dane są jeszcze wczytywane, wyświetlany jest wskaźnik postępu.
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (routePoints.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wyniki')),
        body: const Center(child: Text('Brak wystarczających danych trasy')),
      );
    }

    final center = routePoints.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wyniki trasy'),

        // Przycisk zamknięcia.
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Zamknij',
          // Powrót do pierwszej strony
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),

      body: Column(
        children: [
          // Expanded sprawia, że mapa zajmuje część dostępnej wysokości ekranu.
          Expanded(
            child: FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 15),

              // Warstwy mapy.
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.moj_projekt_flutter',
                  maxZoom: 19,
                ),

                // Warstwa prezentująca przebieg zapisanej trasy.
                PolylineLayer(
                  polylines: [Polyline(points: routePoints, strokeWidth: 5)],
                ),
              ],
            ),
          ),

          Expanded(
            // Dodanie odstępu od krawędzi.
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Statystyki trasy',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  // Odstęp.
                  const SizedBox(height: 35),

                  // Row układa statystyki poziomo.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Statistic(
                        icon: Icons.route,
                        title: 'Odległość',
                        value: '${(distance / 1000).toStringAsFixed(2)} km',
                      ),

                      _Statistic(
                        icon: Icons.timer,
                        title: 'Czas',
                        // Wywołanie wcześniej utworzonej funkcji formatującej Duration.
                        value: formatDuration(duration),
                      ),

                      _Statistic(
                        icon: Icons.speed,
                        title: 'Średnia prędkość',
                        value: '${averageSpeed.toStringAsFixed(2)} km/h',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// _Statistic jest pomocniczym widgetem używanym do wyświetlania jednej statystyki.
class _Statistic extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  // Konstruktor wymaga przekazania wszystkich trzech wartości.
  const _Statistic({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    // Expanded powoduje równomierne rozłożenie poszczególnych statystyk w wierszu.
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 35),
          // Odstęp
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
