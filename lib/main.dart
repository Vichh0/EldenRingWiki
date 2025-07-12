import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'Pages/bosses.dart';
import 'Pages/infocriaturas.dart';
import 'Pages/config.dart';
import 'services/theme_provider.dart';
import 'Pages/Home.dart'; // Asegúrate de importar tu nuevo HomePage

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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'EldenRing Wiki',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(fontSize: themeProvider.fontSize),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(fontSize: themeProvider.fontSize),
            ),
            useMaterial3: true,
          ),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const MainMenu(),
        );
      },
    );
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    HomePage(), // <-- Cambia esto por tu nuevo HomePage
    BossesPage(),
    CreaturesPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EldenRing Wiki'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.deepPurple), // Cambiado a morado
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield, color: Colors.deepPurple), // Cambiado a morado
            label: 'Jefes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets, color: Colors.deepPurple), // Cambiado a morado
            label: 'Criaturas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, color: Colors.deepPurple), // Cambiado a morado
            label: 'Preferencias',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.deepPurple, // Opcional: morado para no seleccionados
        onTap: _onItemTapped,
      ),
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
