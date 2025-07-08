import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final service_busqueda = ServiceBusqueda();
  late Future<List<dynamic>> _jefesFuture;
  List<dynamic> _jefes = [];
  int _jefeActual = 0;

  @override
  void initState() {
    super.initState();
    _jefesFuture = service_busqueda.buscarjefes();
  }

  void _siguienteJefe() {
    setState(() {
      if (_jefes.isNotEmpty) {
        _jefeActual = (_jefeActual + 1) % _jefes.length;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: FutureBuilder<List<dynamic>>(
          future: _jefesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              // Guardar la lista de jefes solo una vez
              if (_jefes.isEmpty) {
                _jefes = snapshot.data!;
              }
              final jefe = _jefes[_jefeActual];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                        jefe['name'] ?? 'Sin nombre',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        jefe['description'] ?? 'Sin descripción',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return const Text('No se encontraron jefes.');
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _siguienteJefe,
        tooltip: 'Siguiente jefe',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class ServiceBusqueda {
  Future<List<dynamic>> buscarjefes() async {
    final response = await http.get(Uri.parse('https://eldenring.fanapis.com/api/bosses'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']; // La API devuelve los jefes en la propiedad 'data'
    } else {
      throw Exception('Error al cargar jefes');
    }
  }
}
