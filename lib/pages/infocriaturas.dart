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
  Map<String, int> likes = {};
  Map<String, int> dislikes = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    _criaturasFuture = buscarCriaturas();
    _loadVotes();
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
      likes = Map<String, int>.from(jsonDecode(prefs.getString('likes_creatures') ?? '{}'));
      dislikes = Map<String, int>.from(jsonDecode(prefs.getString('dislikes_creatures') ?? '{}'));
    });
  }

  Future<void> _saveVotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('likes_creatures', jsonEncode(likes));
    await prefs.setString('dislikes_creatures', jsonEncode(dislikes));
  }

  void _likeCriatura(String criaturaId) {
    setState(() {
      likes[criaturaId] = (likes[criaturaId] ?? 0) + 1;
    });
    _saveVotes();
  }

  void _dislikeCriatura(String criaturaId) {
    setState(() {
      dislikes[criaturaId] = (dislikes[criaturaId] ?? 0) + 1;
    });
    _saveVotes();
  }

  Future<List<dynamic>> buscarCriaturas() async {
    final response = await http.get(Uri.parse('https://eldenring.fanapis.com/api/creatures'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Error al cargar criaturas');
    }
  }

  void _mostrarDetalleCriatura(BuildContext context, dynamic criatura) {
    final criaturaId = criatura['id'] ?? criatura['name'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(criatura['name'] ?? 'Sin nombre'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              (criatura['image'] != null && criatura['image'].toString().isNotEmpty)
                  ? Image.network(
                      criatura['image'],
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
                    )
                  : const Icon(Icons.image_not_supported, size: 100),
              const SizedBox(height: 12),
              Text(
                criatura['description'] ?? 'Sin descripción',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (criatura['location'] != null && criatura['location'].toString().isNotEmpty)
                Text('Ubicación: ${criatura['location']}'),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.thumb_up, color: Colors.green),
                    onPressed: () {
                      _likeCriatura(criaturaId);
                      setState(() {});
                    },
                  ),
                  Text('${likes[criaturaId] ?? 0}'),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(Icons.thumb_down, color: Colors.red),
                    onPressed: () {
                      _dislikeCriatura(criaturaId);
                      setState(() {});
                    },
                  ),
                  Text('${dislikes[criaturaId] ?? 0}'),
                ],
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar criatura por nombre',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
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
                final filteredCriaturas = _searchText.isEmpty
                    ? criaturas
                    : criaturas.where((criatura) =>
                        ((criatura['name'] ?? '').toString().toLowerCase().contains(_searchText))
                      ).toList();
                if (filteredCriaturas.isEmpty) {
                  return const Center(child: Text('No se encontraron criaturas.'));
                }
                return ListView.builder(
                  itemCount: filteredCriaturas.length,
                  itemBuilder: (context, index) {
                    final criatura = filteredCriaturas[index];
                    final criaturaId = criatura['id'] ?? criatura['name'];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(criatura['name'] ?? 'Sin nombre'),
                        subtitle: Text(criatura['description'] ?? 'Sin descripción'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.thumb_up, color: Colors.green),
                              onPressed: () => _likeCriatura(criaturaId),
                            ),
                            Text('${likes[criaturaId] ?? 0}'),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.thumb_down, color: Colors.red),
                              onPressed: () => _dislikeCriatura(criaturaId),
                            ),
                            Text('${dislikes[criaturaId] ?? 0}'),
                          ],
                        ),
                        onTap: () => _mostrarDetalleCriatura(context, criatura),
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
  }
}