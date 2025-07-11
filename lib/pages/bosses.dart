import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BossesPage extends StatefulWidget {
  const BossesPage({super.key});

  @override
  State<BossesPage> createState() => _BossesPageState();
}

class _BossesPageState extends State<BossesPage> {
  late Future<List<dynamic>> _jefesFuture;
  Map<String, int> likes = {};
  Map<String, int> dislikes = {};
  Map<String, int> victories = {};
  Map<String, int> defeats = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    _jefesFuture = buscarjefes();
    _loadVotes();
    _loadStats();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVotes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      likes = Map<String, int>.from(jsonDecode(prefs.getString('likes') ?? '{}'));
      dislikes = Map<String, int>.from(jsonDecode(prefs.getString('dislikes') ?? '{}'));
    });
  }

  Future<void> _saveVotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('likes', jsonEncode(likes));
    await prefs.setString('dislikes', jsonEncode(dislikes));
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      victories = Map<String, int>.from(jsonDecode(prefs.getString('victories') ?? '{}'));
      defeats = Map<String, int>.from(jsonDecode(prefs.getString('defeats') ?? '{}'));
    });
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('victories', jsonEncode(victories));
    await prefs.setString('defeats', jsonEncode(defeats));
  }

  void _likeJefe(String jefeId) {
    setState(() {
      likes[jefeId] = (likes[jefeId] ?? 0) + 1;
    });
    _saveVotes();
  }

  void _dislikeJefe(String jefeId) {
    setState(() {
      dislikes[jefeId] = (dislikes[jefeId] ?? 0) + 1;
    });
    _saveVotes();
  }

  void _incrementVictory(String jefeId) {
    setState(() {
      victories[jefeId] = (victories[jefeId] ?? 0) + 1;
    });
    _saveStats();
  }

  void _incrementDefeat(String jefeId) {
    setState(() {
      defeats[jefeId] = (defeats[jefeId] ?? 0) + 1;
    });
    _saveStats();
  }

  Future<List<dynamic>> buscarjefes() async {
    final response = await http.get(Uri.parse('https://eldenring.fanapis.com/api/bosses'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Error al cargar jefes');
    }
  }

  void _mostrarDetalleJefe(BuildContext context, dynamic jefe, bool ocultarLikesDislikes) {
    final jefeId = jefe['id'] ?? jefe['name'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(jefe['name'] ?? 'Sin nombre'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              (jefe['image'] != null && jefe['image'].toString().isNotEmpty)
                  ? Image.network(
                      jefe['image'],
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
                    )
                  : const Icon(Icons.image_not_supported, size: 100),
              const SizedBox(height: 12),
              Text(
                jefe['description'] ?? 'Sin descripción',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (jefe['region'] != null && jefe['region'].toString().isNotEmpty)
                Text('Región: ${jefe['region']}'),
              if (jefe['location'] != null && jefe['location'].toString().isNotEmpty)
                Text('Ubicación: ${jefe['location']}'),
              if (jefe['drops'] != null && jefe['drops'] is List && jefe['drops'].isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text('Drops:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...List<Widget>.from(
                      (jefe['drops'] as List).map((drop) => Text('- $drop')),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              if (!ocultarLikesDislikes)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.thumb_up, color: Colors.green),
                    const SizedBox(width: 4),
                    Text('${likes[jefeId] ?? 0}'),
                    const SizedBox(width: 24),
                    const Icon(Icons.thumb_down, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('${dislikes[jefeId] ?? 0}'),
                  ],
                ),
              const SizedBox(height: 24),
              // Usa StatefulBuilder y Wrap para los contadores de victorias/derrotas
              StatefulBuilder(
                builder: (context, setStateDialog) => Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _incrementVictory(jefeId);
                        setStateDialog(() {});
                        setState(() {});
                      },
                      icon: const Icon(Icons.emoji_events, color: Colors.yellow),
                      label: Text('Victorias: ${victories[jefeId] ?? 0}'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _incrementDefeat(jefeId);
                        setStateDialog(() {});
                        setState(() {});
                      },
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: Text('Derrotas: ${defeats[jefeId] ?? 0}'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<bool> _getExcluirDerrotados() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('excluirDerrotados') ?? false;
  }

  Future<bool> _getOcultarLikesDislikes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('ocultarLikesDislikes') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _getExcluirDerrotados(),
      builder: (context, excluirSnapshot) {
        final excluirDerrotados = excluirSnapshot.data ?? false;
        return FutureBuilder<bool>(
          future: _getOcultarLikesDislikes(),
          builder: (context, ocultarSnapshot) {
            final ocultarLikesDislikes = ocultarSnapshot.data ?? false;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar jefe por nombre',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: _jefesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final jefes = snapshot.data!;
                        final filteredJefes = jefes.where((jefe) {
                          final jefeId = jefe['id'] ?? jefe['name'];
                          final isDefeated = victories[jefeId] != null && victories[jefeId]! > 0;
                          final matchesSearch = _searchText.isEmpty ||
                            ((jefe['name'] ?? '').toString().toLowerCase().contains(_searchText));
                          if (excluirDerrotados && isDefeated) return false;
                          return matchesSearch;
                        }).toList();
                        if (filteredJefes.isEmpty) {
                          return const Center(child: Text('No se encontraron jefes.'));
                        }
                        return ListView.builder(
                          itemCount: filteredJefes.length,
                          itemBuilder: (context, index) {
                            final jefe = filteredJefes[index];
                            final jefeId = jefe['id'] ?? jefe['name'];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                title: Text(jefe['name'] ?? 'Sin nombre'),
                                subtitle: Text(jefe['description'] ?? 'Sin descripción'),
                                trailing: ocultarLikesDislikes
                                  ? null
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.thumb_up, color: Colors.green),
                                          onPressed: () => _likeJefe(jefeId),
                                        ),
                                        Text('${likes[jefeId] ?? 0}'),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.thumb_down, color: Colors.red),
                                          onPressed: () => _dislikeJefe(jefeId),
                                        ),
                                        Text('${dislikes[jefeId] ?? 0}'),
                                      ],
                                    ),
                                onTap: () => _mostrarDetalleJefe(context, jefe, ocultarLikesDislikes),
                              ),
                            );
                          },
                        );
                      } else {
                        return const Center(child: Text('No se encontraron jefes.'));
                      }
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}