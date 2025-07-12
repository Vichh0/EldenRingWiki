import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../services/theme_provider.dart';
import 'bosses.dart';
import 'infocriaturas.dart';
import 'config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;
  Map<String, dynamic>? _randomBoss;
  Map<String, dynamic>? _randomCreature;
  Timer? _timer;

  static final List<Widget> _pages = <Widget>[
    // Puedes poner aquí widgets de bienvenida o información si lo deseas
    // Ejemplo: Center(child: Text('Bienvenido a EldenRing Wiki')),
    BossesPage(),
    CreaturesPage(),
    SettingsPage(),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchRandomBoss();
    _fetchRandomCreature();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchRandomBoss();
      _fetchRandomCreature();
    });
  }

  Future<void> _fetchRandomBoss() async {
    final response = await http.get(Uri.parse('https://eldenring.fanapis.com/api/bosses'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final bosses = data['data'] as List<dynamic>;
      if (bosses.isNotEmpty) {
        final randomBoss = bosses[Random().nextInt(bosses.length)];
        setState(() {
          _randomBoss = randomBoss;
        });
      }
    }
  }

  Future<void> _fetchRandomCreature() async {
    final response = await http.get(Uri.parse('https://eldenring.fanapis.com/api/creatures'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final creatures = data['data'] as List<dynamic>;
      if (creatures.isNotEmpty) {
        final randomCreature = creatures[Random().nextInt(creatures.length)];
        setState(() {
          _randomCreature = randomCreature;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchRandomBoss();
    _fetchRandomCreature();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('EldenRing Wiki'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _selectedIndex == 0
          ? Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _randomBoss == null
                        ? const CircularProgressIndicator()
                        : Card(
                            elevation: 4,
                            margin: const EdgeInsets.all(24),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _randomBoss!['name'] ?? 'Sin nombre',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  _randomBoss!['image'] != null && _randomBoss!['image'].toString().isNotEmpty
                                      ? Image.network(
                                          _randomBoss!['image'],
                                          height: 180,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.broken_image, size: 100),
                                        )
                                      : const Icon(Icons.image_not_supported, size: 100),
                                  const SizedBox(height: 12),
                                  Text(
                                    _randomBoss!['description'] ?? 'Sin descripción',
                                    style: const TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                    const SizedBox(height: 24),
                    if (_randomCreature != null)
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.all(24),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _randomCreature!['name'] ?? 'Sin nombre',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              _randomCreature!['image'] != null && _randomCreature!['image'].toString().isNotEmpty
                                  ? Image.network(
                                      _randomCreature!['image'],
                                      height: 180,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.broken_image, size: 100),
                                    )
                                  : const Icon(Icons.image_not_supported, size: 100),
                              const SizedBox(height: 12),
                              Text(
                                _randomCreature!['description'] ?? 'Sin descripción',
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : _pages[_selectedIndex - 1],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.deepPurple),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield, color: Colors.deepPurple),
            label: 'Jefes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets, color: Colors.deepPurple),
            label: 'Criaturas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, color: Colors.deepPurple),
            label: 'Preferencias',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}