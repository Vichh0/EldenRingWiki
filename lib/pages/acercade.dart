import 'package:flutter/material.dart';

class AcercaDePage extends StatefulWidget {
  @override
  _AcercaDePageState createState() => _AcercaDePageState();
}

class _AcercaDePageState extends State<AcercaDePage> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Acerca de'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
        Card(
          elevation: 4,
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
          'Aplicacion EldenRing Wiki\n Desarrollada por:\n Vicente Castillo - Oscar Montecinos',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
            ),
          ),
        ),
        Card(
          elevation: 4,
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
          'Una aplicacion para ayuda a los jugadores de Elden Ring a buscar los jefes y criaturas del juego, encontarndo la informacion, imajen, dropeos, etc. Dandole a los usuarios la capacidad de registrar sus victorias y derrotas a la vez de dar like o dislike.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}