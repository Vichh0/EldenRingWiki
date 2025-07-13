import 'dart:developer';
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
  Map<String, bool> likes = {};     // true si le dio like, false/null si no
  Map<String, bool> dislikes = {};  // true si le dio dislike, false/null si no
  Map<String, int> victories = {};
  Map<String, int> defeats = {};
  Map<String, bool> favoritos = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    _jefesFuture = buscarjefes();
    _loadVotes();
    _loadStats();
    _loadFavoritos(); // <-- Añade esta línea
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
    final likesString = prefs.getString('likes');
    final dislikesString = prefs.getString('dislikes');
    setState(() {
      if (likesString != null && likesString.isNotEmpty) {
        final decodedLikes = jsonDecode(likesString);
        likes = decodedLikes is Map ? Map<String, bool>.from(decodedLikes) : {};
      } else {
        likes = {};
      }
      if (dislikesString != null && dislikesString.isNotEmpty) {
        final decodedDislikes = jsonDecode(dislikesString);
        dislikes = decodedDislikes is Map ? Map<String, bool>.from(decodedDislikes) : {};
      } else {
        dislikes = {};
      }
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

  Future<void> _loadFavoritos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoritos = Map<String, bool>.from(jsonDecode(prefs.getString('favoritos') ?? '{}'));
    });
  }

  Future<void> _saveFavoritos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favoritos', jsonEncode(favoritos));
  }

  void _likeJefe(String jefeId) {
    setState(() {
      if (likes[jefeId] == true) {
        likes[jefeId] = false; // Quita el like si ya lo tenía
      } else {
        likes[jefeId] = true;
        dislikes[jefeId] = false; // Solo puede tener una opción activa
      }
    });
    _saveVotes();
  }

  void _dislikeJefe(String jefeId) {
    setState(() {
      if (dislikes[jefeId] == true) {
        dislikes[jefeId] = false; // Quita el dislike si ya lo tenía
      } else {
        dislikes[jefeId] = true;
        likes[jefeId] = false; // Solo puede tener una opción activa
      }
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
                    Icon(
                      likes.containsKey(jefeId) && likes[jefeId] == true
                      ? Icons.thumb_up
                      : Icons.thumb_up_off_alt,
                      color: likes.containsKey(jefeId) && likes[jefeId] == true
                      ? Colors.green
                      : Colors.grey,
                      size: 28,
                    ),
                    Icon(
                      dislikes.containsKey(jefeId) && dislikes[jefeId] == true
                      ? Icons.thumb_down
                      : Icons.thumb_down_off_alt,
                      color: dislikes.containsKey(jefeId) && dislikes[jefeId] == true
                      ? Colors.red
                      : Colors.grey,
                      size: 28,
                    ),
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
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black, // <-- Cambia color del texto e ícono
                        backgroundColor: const Color(0xFFD9B157), // opcional: color de fondo claro
                      ),
                      onPressed: () {
                        _incrementVictory(jefeId);
                        setStateDialog(() {});
                        setState(() {});
                      },
                      icon: const Icon(Icons.emoji_events, color: Colors.yellow),
                      label: Text(
                        'Victorias: ${victories[jefeId] ?? 0}',
                        style: const TextStyle(color: Colors.black), // <-- Texto visible
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: const Color(0xFFD9B157),
                      ),
                      onPressed: () {
                        _incrementDefeat(jefeId);
                        setStateDialog(() {});
                        setState(() {});
                      },
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: Text(
                        'Derrotas: ${defeats[jefeId] ?? 0}',
                        style: const TextStyle(color: Colors.black),
                      ),
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
            child: const Text(
              'Cerrar',
              style: TextStyle(
                color: Colors.black, // Usa negro u otro color oscuro visible
                fontWeight: FontWeight.bold,
              ),
            ),
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

  Future<bool> _getBuscarSoloFavoritos() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('buscarSoloFavoritos') ?? false;
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
            return FutureBuilder<bool>(
              future: _getBuscarSoloFavoritos(),
              builder: (context, favoritosSnapshot) {
                final buscarSoloFavoritos = favoritosSnapshot.data ?? false;
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
                              final isFavorito = favoritos[jefeId] == true;
                              if (excluirDerrotados && isDefeated) return false;
                              if (buscarSoloFavoritos && !isFavorito) return false;
                              return matchesSearch;
                            }).toList();
                            filteredJefes.sort((a, b) {
                              final aId = a['id'] ?? a['name'];
                              final bId = b['id'] ?? b['name'];
                              final aFav = favoritos[aId] == true ? 0 : 1;
                              final bFav = favoritos[bId] == true ? 0 : 1;
                              return aFav.compareTo(bFav);
                            });
                            if (filteredJefes.isEmpty) {
                              return const Center(child: Text('No se encontraron jefes.'));
                            }
                            return ListView.builder(
                              itemCount: filteredJefes.length,
                              itemBuilder: (context, index) {
                                final jefe = filteredJefes[index];
                                final jefeId = jefe['id'] ?? jefe['name'];
                                return Card(
                                  color: const Color(0xFFD6C77A), 
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  elevation: 6,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          tileColor: const Color(0xFFD6C77A), 
                                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          leading: (jefe['image'] != null && jefe['image'].toString().isNotEmpty)
                                              ? Image.network(
                                                  jefe['image'],
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Icon(Icons.broken_image, size: 60),
                                                )
                                              : const Icon(Icons.image_not_supported, size: 60),
                                          title: Text(
                                            jefe['name'] ?? 'Sin nombre',
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center,
                                          ),
                                          onTap: () => _mostrarDetalleJefe(context, jefe, ocultarLikesDislikes),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                favoritos[jefeId] == true ? Icons.star : Icons.star_border,
                                                color: favoritos[jefeId] == true ? Colors.amber : Colors.grey,
                                                size: 32,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  favoritos[jefeId] = !(favoritos[jefeId] ?? false);
                                                });
                                                _saveFavoritos();
                                              },
                                            ),
                                            if (!ocultarLikesDislikes) ...[
                                              IconButton(
                                                icon: Icon(
                                                  likes.containsKey(jefeId) && likes[jefeId] == true
                                                  ? Icons.thumb_up 
                                                  : Icons.thumb_up_off_alt,
                                                  color: likes.containsKey(jefeId) && likes[jefeId] == true
                                                  ? Colors.green
                                                  : Colors.grey,
                                                  size: 28,
                                                ),
                                                onPressed: () => _likeJefe(jefeId),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: Icon(
                                                  dislikes.containsKey(jefeId) && dislikes[jefeId] == true
                                                  ? Icons.thumb_down 
                                                  : Icons.thumb_down_off_alt,
                                                  color: dislikes.containsKey(jefeId) && dislikes[jefeId] == true
                                                  ? Colors.red
                                                  : Colors.grey,
                                                  size: 28,
                                                ),
                                                onPressed: () => _dislikeJefe(jefeId),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
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
      },
    );
  }
}