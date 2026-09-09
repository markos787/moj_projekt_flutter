// Import podstawowych elementów frameworka Flutter, m.in.:
import 'package:flutter/material.dart';

// Import własnego pliku zawierającego stronę logowania.
import 'login_page.dart';

// Główna funkcja programu.
void main() {
  // runApp() uruchamia aplikację i wyświetla przekazany do niej widget.
  // MyApp jest głównym widgetem całej aplikacji.
  runApp(const MyApp());
}

// StatelessWidget oznacza, że sam widget nie przechowuje zmiennego stanu, który powodowałby jego przebudowanie.
class MyApp extends StatelessWidget {
  // const pozwala utworzyć widget jako stałą, jeżeli jego właściwości nie zmieniają się w czasie.
  const MyApp({super.key});

  // Metoda build() odpowiada za zdefiniowanie wyglądu i struktury widgetu.
  // Flutter wywołuje ją w celu utworzenia elementów interfejsu użytkownika.
  @override
  Widget build(BuildContext context) {
    // MaterialApp jest głównym widgetem aplikacji korzystającej z Material Design.
    // Odpowiada m.in. za konfigurację motywu, nawigację oraz stronę startową.
    return MaterialApp(
      // Usuwa napis "DEBUG" pojawiający się standardowo w trybie debugowania.
      debugShowCheckedModeBanner: false,
      // Tytuł aplikacji.
      title: 'Moja aplikacja',

      // Konfiguracja wyglądu całej aplikacji.
      theme: ThemeData(
        // fromSeed() automatycznie tworzy kompletną paletę kolorów
        // na podstawie jednego koloru bazowego.
        colorScheme: .fromSeed(seedColor: Colors.green),
      ),
      // LoginPage jest widgetem zdefiniowanym w pliku login_page.dart.
      // const oznacza, że jeżeli konstruktor LoginPage na to pozwala,
      // widget może zostać utworzony jako stała.
      home: const LoginPage(),
    );
  }
}

/*
  Poniższa część jest zakomentowanym przykładem strony głównej aplikacji.
  MyHomePage jest przykładem StatefulWidget, czyli widgetu,
  którego wygląd może zależeć od zmieniającego się stanu.
  W przeciwieństwie do StatelessWidget, StatefulWidget współpracuje
  z osobnym obiektem State, który przechowuje zmienne dane widgetu.
*/

// // StatefulWidget stosuje się wtedy, gdy zawartość interfejsu
// // może zmieniać się podczas działania aplikacji.
// class MyHomePage extends StatefulWidget {

//   // Konstruktor widgetu.
//   // Wymagany jest parametr title, który zostanie przekazany
//   // do obiektu MyHomePage.
//   const MyHomePage({super.key, required this.title});

//   // final oznacza, że wartość zostaje ustalona podczas tworzenia
//   // widgetu i nie może być później zmieniona.
//   final String title;

//   // Metoda createState() tworzy obiekt przechowujący zmienny stan tego widgetu.
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// // Klasa przechowująca zmienny stan widgetu MyHomePage.
// // Znak "_" na początku nazwy oznacza, że klasa jest prywatna
// // dla tego pliku.
// class _MyHomePageState extends State<MyHomePage> {

//   int _counter = 0;

//   // Funkcja zmieniająca wartość licznika.
//   void _incrementCounter() {

//     // setState() informuje Fluttera, że stan widgetu został zmieniony.
//     // Po wykonaniu setState() Flutter ponownie wywoła metodę build()
//     // i odświeży elementy interfejsu zależne od zmienionych danych.
//     setState(() {
//       _counter--;
//     });
//   }

//   // Metoda odpowiedzialna za utworzenie interfejsu strony.
//   @override
//   Widget build(BuildContext context) {

//     // Scaffold zapewnia podstawową strukturę strony aplikacji
//     // zgodną z Material Design.
//     return Scaffold(

//       // AppBar to górny pasek aplikacji.
//       appBar: AppBar(

//         // Ustawienie koloru tła paska.
//         //
//         // Theme.of(context) pobiera aktualny motyw aplikacji,
//         // a colorScheme.inversePrimary pobiera jeden z kolorów zdefiniowanych w tym motywie.
//         backgroundColor: Theme.of(context)
//             .colorScheme
//             .inversePrimary,

//         // Tekst wyświetlany na pasku aplikacji.
//         title: Text(widget.title),
//       ),

//       // body jest główną częścią strony
//       body: Center(

//         // Center umieszcza swój element potomny na środku dostępnego
//         child: Column(

//           // Column układa swoje elementy jeden pod drugim.
//           // mainAxisAlignment.center powoduje wyśrodkowanie elementów
//           mainAxisAlignment: .center,

//           // Lista widgetów znajdujących się wewnątrz Column.
//           children: [

//             const Text(
//               'You have pushed the button this many times:',
//             ),

//             // Wyświetlenie aktualnej wartości zmiennej _counter.
//             Text(
//               '$_counter',

//               // headlineMedium jest jednym ze zdefiniowanych stylów tekstu.
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),

//       // floatingActionButton to przycisk umieszczony standardowo
//       // w dolnym obszarze strony.
//       floatingActionButton: FloatingActionButton(

//         // Funkcja wykonywana po naciśnięciu przycisku.
//         onPressed: _incrementCounter,

//         // Tekst pomocniczy wyświetlany np. po przytrzymaniu przycisku.
//         tooltip: 'Increment',

//         // Ikona znajdująca się wewnątrz przycisku.
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
