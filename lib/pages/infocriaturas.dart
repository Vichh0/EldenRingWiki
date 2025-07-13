import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreaturesPage extends StatefulWidget {
  const CreaturesPage({super.key});

  @override
  State<CreaturesPage> createState() => _CreaturesPageState();
}

class _CreaturesPageState extends State<CreaturesPage> {
  late Future<List<dynamic>> _criaturasFuture;
  Map<String, bool> likes = {};
  Map<String, bool> dislikes = {};
  Map<String, int> victories = {};
  Map<String, int> defeats = {};
  Map<String, bool> favoritos = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    _criaturasFuture = buscarCriaturas();
    _loadVotes();
    _loadStats();
    _loadFavoritos();
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

  // Cargar votos (likes/dislikes) desde SharedPreferences
  Future<void> _loadVotes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      likes = Map<String, bool>.from(jsonDecode(prefs.getString('likes_creatures') ?? '{}'));
      dislikes = Map<String, bool>.from(jsonDecode(prefs.getString('dislikes_creatures') ?? '{}'));
    });
  }

  // Guardar votos (likes/dislikes) en SharedPreferences
  Future<void> _saveVotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('likes_creatures', jsonEncode(likes));
    await prefs.setString('dislikes_creatures', jsonEncode(dislikes));
  }

  // Cargar estadísticas (victorias/derrotas) desde SharedPreferences
  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      victories = Map<String, int>.from(jsonDecode(prefs.getString('victories_creatures') ?? '{}'));
      defeats = Map<String, int>.from(jsonDecode(prefs.getString('defeats_creatures') ?? '{}'));
    });
  }

  // Guardar estadísticas (victorias/derrotas) en SharedPreferences
  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('victories_creatures', jsonEncode(victories));
    await prefs.setString('defeats_creatures', jsonEncode(defeats));
  }

  // Cargar favoritos desde SharedPreferences
  Future<void> _loadFavoritos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoritos = Map<String, bool>.from(jsonDecode(prefs.getString('favoritos_creatures') ?? '{}'));
    });
  }

  // Guardar favoritos en SharedPreferences
  Future<void> _saveFavoritos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favoritos_creatures', jsonEncode(favoritos));
  }

  // Lógica para dar "like" a una criatura
  void _likeCriatura(String criaturaId) {
    setState(() {
      if (likes[criaturaId] == true) {
        likes.remove(criaturaId);
      } else {
        likes[criaturaId] = true;
        dislikes.remove(criaturaId);
      }
    });
    _saveVotes();
  }

  // Lógica para dar "dislike" a una criatura
  void _dislikeCriatura(String criaturaId) {
    setState(() {
      if (dislikes[criaturaId] == true) {
        dislikes.remove(criaturaId);
      } else {
        dislikes[criaturaId] = true;
        likes.remove(criaturaId);
      }
    });
    _saveVotes();
  }

  // Incrementar contador de victorias
  void _incrementVictory(String criaturaId) {
    setState(() {
      victories[criaturaId] = (victories[criaturaId] ?? 0) + 1;
    });
    _saveStats();
  }

  // Incrementar contador de derrotas
  void _incrementDefeat(String criaturaId) {
    setState(() {
      defeats[criaturaId] = (defeats[criaturaId] ?? 0) + 1;
    });
    _saveStats();
  }

  // Lógica para marcar/desmarcar como favorito
  void _toggleFavorito(String criaturaId) {
    setState(() {
      favoritos[criaturaId] = !(favoritos[criaturaId] ?? false);
    });
    _saveFavoritos();
  }

  // Obtener criaturas desde la API
  Future<List<dynamic>> buscarCriaturas() async {
    final response = await http.get(Uri.parse('https://eldenring.fanapis.com/api/creatures'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Error al cargar criaturas');
    }
  }

  // Obtener configuración de SharedPreferences
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

  // Mostrar diálogo con detalles de la criatura
  void _mostrarDetalleCriatura(BuildContext context, dynamic criatura, bool ocultarLikesDislikes) {
    final criaturaId = criatura['id'] ?? criatura['name'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(criatura['name'] ?? 'Sin nombre'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imagen de la criatura
              (criatura['image'] != null && criatura['image'].toString().isNotEmpty)
                  ? Image.network(
                      criatura['image'],
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
                    )
                  : const Icon(Icons.image_not_supported, size: 100),
              const SizedBox(height: 12),
              // Descripción
              Text(
                criatura['description'] ?? 'Sin descripción',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              // Ubicación
              if (criatura['location'] != null && criatura['location'].toString().isNotEmpty)
                Text('Ubicación: ${criatura['location']}'),
              // Drops
              if (criatura['drops'] != null && criatura['drops'] is List && criatura['drops'].isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text('Drops:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...List<Widget>.from(
                      (criatura['drops'] as List).map((drop) => Text('- $drop')),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              // Botones de like/dislike
              if (!ocultarLikesDislikes)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        likes[criaturaId] == true ? Icons.thumb_up : Icons.thumb_up_off_alt,
                        color: likes[criaturaId] == true ? Colors.green : Colors.grey,
                      ),
                      onPressed: () {
                        _likeCriatura(criaturaId);
                        Navigator.of(context).pop(); // Cierra y reabre para actualizar
                        _mostrarDetalleCriatura(context, criatura, ocultarLikesDislikes);
                      },
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: Icon(
                        dislikes[criaturaId] == true ? Icons.thumb_down : Icons.thumb_down_off_alt,
                        color: dislikes[criaturaId] == true ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        _dislikeCriatura(criaturaId);
                        Navigator.of(context).pop();
                        _mostrarDetalleCriatura(context, criatura, ocultarLikesDislikes);
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              // Contadores de victorias/derrotas
              StatefulBuilder(
                builder: (context, setStateDialog) => Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Color(0xFFD9B157),
                      ),
                      onPressed: () {
                        _incrementVictory(criaturaId);
                        setStateDialog(() {});
                        setState(() {});
                      },
                      icon: const Icon(Icons.emoji_events, color: Colors.yellow),
                      label: Text(
                        'Victorias: ${victories[criaturaId] ?? 0}',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Color(0xFFD9B157),
                      ),
                      onPressed: () {
                        _incrementDefeat(criaturaId);
                        setStateDialog(() {});
                        setState(() {});
                      },
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: Text(
                        'Derrotas: ${defeats[criaturaId] ?? 0}',
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
                color: Colors.black, // Texto visible
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
                    // Campo de búsqueda
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Buscar criatura por nombre',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    // Lista de criaturas
                    Expanded(
                      child: FutureBuilder<List<dynamic>>(
                        future: _criaturasFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            final criaturas = snapshot.data!;
                            // Aplicar filtros
                            final filteredCriaturas = criaturas.where((criatura) {
                              final criaturaId = criatura['id'] ?? criatura['name'];
                              final isDefeated = victories[criaturaId] != null && victories[criaturaId]! > 0;
                              final matchesSearch = _searchText.isEmpty ||
                                ((criatura['name'] ?? '').toString().toLowerCase().contains(_searchText));
                              final isFavorito = favoritos[criaturaId] == true;
                              if (excluirDerrotados && isDefeated) return false;
                              if (buscarSoloFavoritos && !isFavorito) return false;
                              return matchesSearch;
                            }).toList();
                            // Ordenar por favoritos
                            filteredCriaturas.sort((a, b) {
                              final aId = a['id'] ?? a['name'];
                              final bId = b['id'] ?? b['name'];
                              final aFav = favoritos[aId] == true ? 0 : 1;
                              final bFav = favoritos[bId] == true ? 0 : 1;
                              if (aFav != bFav) {
                                return aFav.compareTo(bFav);
                              }
                              return (a['name'] ?? '').compareTo(b['name'] ?? '');
                            });
                            if (filteredCriaturas.isEmpty) {
                              return const Center(child: Text('No se encontraron criaturas.'));
                            }
                            // Construir la lista
                            return ListView.builder(
                              itemCount: filteredCriaturas.length,
                              itemBuilder: (context, index) {
                                final criatura = filteredCriaturas[index];
                                final criaturaId = criatura['id'] ?? criatura['name'];
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
                                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          leading: (criatura['image'] != null && criatura['image'].toString().isNotEmpty)
                                              ? Image.network(
                                                  criatura['image'],
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Icon(Icons.broken_image, size: 60),
                                                )
                                              : const Icon(Icons.image_not_supported, size: 60),
                                          title: Text(
                                            criatura['name'] ?? 'Sin nombre',
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center,
                                          ),
                                          onTap: () => _mostrarDetalleCriatura(context, criatura, ocultarLikesDislikes),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            // Botón de favorito
                                            IconButton(
                                              icon: Icon(
                                                favoritos[criaturaId] == true ? Icons.star : Icons.star_border,
                                                color: favoritos[criaturaId] == true ? Colors.amber : Colors.grey,
                                                size: 32,
                                              ),
                                              onPressed: () => _toggleFavorito(criaturaId),
                                            ),
                                            // Botones de like/dislike en la tarjeta
                                            if (!ocultarLikesDislikes) ...[
                                              IconButton(
                                                icon: Icon(
                                                  likes[criaturaId] == true ? Icons.thumb_up : Icons.thumb_up_off_alt,
                                                  color: likes[criaturaId] == true ? Colors.green : Colors.grey,
                                                  size: 28,
                                                ),
                                                onPressed: () => _likeCriatura(criaturaId),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: Icon(
                                                  dislikes[criaturaId] == true ? Icons.thumb_down : Icons.thumb_down_off_alt,
                                                  color: dislikes[criaturaId] == true ? Colors.red : Colors.grey,
                                                  size: 28,
                                                ),
                                                onPressed: () => _dislikeCriatura(criaturaId),
                                              ),
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
                            return const Center(child: Text('No se encontraron criaturas.'));
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