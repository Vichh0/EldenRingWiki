import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'services/theme_provider.dart';
import 'Pages/Home.dart';
import 'Pages/splahsscreen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        // Verifica acceso a la API
        final response = await http.get(Uri.parse('https://eldenring.fanapis.com/api/bosses')).timeout(const Duration(seconds: 5));
        return response.statusCode == 200;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'EldenRing Wiki',
          theme: ThemeData(
            fontFamily: 'CENTAUR',
            cardColor: const Color(0xFF5C4A1F), // dorado oscuro
            scaffoldBackgroundColor: const Color(0xFFEEE8AA), // fondo pergamino claro
            colorScheme: const ColorScheme(
              brightness: Brightness.light,
              primary: Color(0xFFB39525),       // dorado
              onPrimary: Color.fromARGB(255, 170, 127, 42),
              secondary: Color(0xFFC9B458),     // amarillo místico
              onSecondary: Colors.black,
              background: Color(0xFFEEE8AA),    // pergamino claro
              onBackground: Colors.black,
              surface: Color(0xFFD6C77A),       // superficie (cartas claras)
              onSurface: Colors.black,
              error: Color(0xFF7A2E2E),
              onError: Colors.white,
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(fontSize: themeProvider.fontSize, color: Colors.black),
            ),
            useMaterial3: true,
          ),

          darkTheme: ThemeData(
            cardColor: const Color.fromARGB(255, 71, 63, 7), // Color para las cards en modo oscuro
            fontFamily: 'CENTAUR',
            colorScheme: ColorScheme(
              brightness: Brightness.dark,
              primary: Color(0xFFB39525),
              onPrimary: Colors.black,
              secondary: Color(0xFFC9B458),
              onSecondary: Colors.black,
              background: Color(0xFF0D0D0D), // negro carbón
              onBackground: Color(0xFFE0DED1),
              surface: Color(0xFF2E2E2E), // gris pizarra
              onSurface: Color(0xFFE0DED1),
              error: Color(0xFF7A2E2E),
              onError: Colors.white,
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(fontSize: themeProvider.fontSize, color: Color(0xFFE0DED1)),
            ),
            useMaterial3: true,
          ),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: FutureBuilder<bool>(
            future: checkInternetConnection(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SplashScreen();
              }
              if (snapshot.data == false) {
                return Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, color: Color.fromARGB(255, 145, 143, 42), size: 80),
                        const SizedBox(height: 24),
                        const Text(
                          'No hay conexión a internet',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Verifica tu conexión e intenta nuevamente.',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const HomePage();
            },
          ),
        );
      },
    );
  }
}

class ServiceBusqueda {
  Future<List<dynamic>> buscarjefes() async {
    final response = await http.get(Uri.parse('https://eldenring.fanapis.com/api/bosses'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Error al cargar jefes');
    }
  }
}

Future<bool> checkInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('example.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
