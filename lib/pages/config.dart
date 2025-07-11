import 'package:eldenringwiki/pages/acercade.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text("Tema Oscuro"),
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            Text(
              "A",
              style: TextStyle(fontSize: themeProvider.fontSize),
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
              }
              ),
            ),
          ],
        ),
      ),
    );
  }
}
