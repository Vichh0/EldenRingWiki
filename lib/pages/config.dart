import 'package:eldenringwiki/pages/acercade.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool excluirDerrotados = false;
  bool ocultarLikesDislikes = false;
  bool buscarSoloFavoritos = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      excluirDerrotados = prefs.getBool('excluirDerrotados') ?? false;
      ocultarLikesDislikes = prefs.getBool('ocultarLikesDislikes') ?? false;
      buscarSoloFavoritos = prefs.getBool('buscarSoloFavoritos') ?? false;
    });
  }

  Future<void> _savePrefsExcluir(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('excluirDerrotados', value);
  }

  Future<void> _savePrefsOcultar(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ocultarLikesDislikes', value);
  }

  Future<void> _savePrefsBuscarFavoritos(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('buscarSoloFavoritos', value);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Preferencias",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text("Excluir jefes derrotados"),
                      value: excluirDerrotados,
                      onChanged: (value) {
                        setState(() {
                          excluirDerrotados = value ?? false;
                        });
                        _savePrefsExcluir(value ?? false);
                      },
                    ),
                    CheckboxListTile(
                      title: const Text("Ocultar likes y dislikes"),
                      value: ocultarLikesDislikes,
                      onChanged: (value) {
                        setState(() {
                          ocultarLikesDislikes = value ?? false;
                        });
                        _savePrefsOcultar(value ?? false);
                      },
                    ),
                    CheckboxListTile(
                      title: const Text("Buscar solo favoritos"),
                      value: buscarSoloFavoritos,
                      onChanged: (value) {
                        setState(() {
                          buscarSoloFavoritos = value ?? false;
                        });
                        _savePrefsBuscarFavoritos(value ?? false);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text("Tema Oscuro"),
                      value: themeProvider.isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Tamaño de Fuente: ${themeProvider.fontSize.toStringAsFixed(0)}",
                      style: TextStyle(fontSize: themeProvider.fontSize),
                    ),
                    Slider(
                      min: 12,
                      max: 30,
                      value: themeProvider.fontSize,
                      onChanged: (value) => themeProvider.setFontSize(value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.blue),
                title: const Text("Acerca de"),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => AcercaDePage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
