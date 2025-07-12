import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _randomBoss;
  Timer? _timer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchRandomBoss();
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se llama cada vez que se vuelve a la página Home
    _fetchRandomBoss();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: _randomBoss == null
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
    );
  }
}