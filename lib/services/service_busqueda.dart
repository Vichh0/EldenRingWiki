import 'package:http/http.dart';

class ServiceBusqueda {
  final String _baseUrljefes = 'https://eldenring.fanapis.com/api/bosses';

  Future<String> buscarjefes() async {
    final url = Uri.parse(_baseUrljefes);
    final response = await get(url);
    
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Error al buscar: ${response.statusCode}');
    }
  }
}