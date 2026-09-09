// Import podstawowych widgetów Fluttera
import 'package:flutter/material.dart';

// Import strony mapy
import 'map_page.dart';

// LoginPage dziedziczy po StatefulWidget
class LoginPage extends StatefulWidget {
  // super.key przekazuje opcjonalny klucz do klasy nadrzędnej.
  const LoginPage({super.key});

  // Metoda tworząca obiekt przechowujący stan strony.
  // _LoginPageState będzie zawierał logikę strony,
  @override
  State<LoginPage> createState() => _LoginPageState();
}

// Klasa _LoginPageState przechowuje dane i logikę potrzebną do działania LoginPage.
// Znak "_" na początku nazwy oznacza, że klasa jest prywatna
class _LoginPageState extends State<LoginPage> {
  // TextEditingController pozwala programowi odczytać, co użytkownik wpisał w pole tekstowe.
  final TextEditingController usernameController = TextEditingController();

  // Pozwala odczytać tekst wpisany przez użytkownika do pola hasła.
  final TextEditingController passwordController = TextEditingController();

  // Funkcja login() jest wykonywana po naciśnięciu "Zaloguj".
  void login() {
    // Pobranie wartości wpisanej przez użytkownika
    String username = usernameController.text;
    String password = passwordController.text;

    // Sprawdzenie, czy podany login i hasło są prawidłowe.
    if (username == 'admin' && password == '1234') {
      // Navigator odpowiada za przemieszczanie się pomiędzy stronami aplikacji.
      // pushReplacement() otwiera nową stronę i jednocześnie usuwa aktualną stronę logowania ze stosu.
      Navigator.pushReplacement(
        // context identyfikuje aktualne miejsce w strukturze widgetów aplikacji.
        context,

        // MaterialPageRoute określa sposób utworzenia nowej strony.
        MaterialPageRoute(
          // Po przejściu nawigacja utworzy stronę MapPage.
          builder: (context) => const MapPage(),
        ),
      );
    } else {
      // ScaffoldMessenger pozwala wyświetlać krótkie komunikaty użytkownikowi.
      ScaffoldMessenger.of(context).showSnackBar(
        // SnackBar jest krótkim komunikatem
        const SnackBar(content: Text('Nieprawidłowy login lub hasło')),
      );
    }
  }

  // Metoda build() definiuje wygląd strony logowania.
  @override
  Widget build(BuildContext context) {
    // Scaffold tworzy podstawową strukturę strony
    return Scaffold(
      // body zawiera główną zawartość strony.
      body: Center(
        // Center umieszcza zawartość na środku dostępnego obszaru.
        child: SingleChildScrollView(
          // SingleChildScrollView umożliwia przewijanie zawartości.
          padding: const EdgeInsets.all(30),
          // Column układa wszystkie elementy formularza jeden pod drugim.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            // Lista elementów znajdujących się na stronie.
            children: [
              // Ikona informująca użytkownika, że znajduje się na stronie logowania.
              const Icon(Icons.lock_outline, size: 80),
              const SizedBox(height: 30),

              const Text(
                'Logowanie',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              // Odstęp pomiędzy nagłówkiem a formularzem.
              const SizedBox(height: 40),

              // TextField tworzy pole tekstowe,
              TextField(
                // Podłączenie kontrolera do pola tekstowego.
                controller: usernameController,
                // Dekoracja pola tekstowego.
                decoration: const InputDecoration(
                  labelText: 'Login',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              // Odstęp pomiędzy polem loginu a polem hasła.
              const SizedBox(height: 20),

              // Drugie pole tekstowe przeznaczone na hasło.
              TextField(
                // Podłączenie kontrolera hasła.
                controller: passwordController,
                // Ukrywanie wpisywanego tekstu.
                obscureText: true,
                // Wygląd pola hasła.
                decoration: const InputDecoration(
                  labelText: 'Hasło',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                // double.infinity powoduje rozciągnięcie przycisku na całą dostępną szerokość.
                width: double.infinity,
                // ElevatedButton tworzy podniesiony przycisk.
                child: ElevatedButton(
                  // Funkcja wykonywana po naciśnięciu przycisku.
                  onPressed: login,
                  // Padding tworzy wewnętrzny odstęp pomiędzy tekstem a krawędzią przycisku.
                  child: const Padding(
                    padding: EdgeInsets.all(15),
                    child: Text('Zaloguj', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
