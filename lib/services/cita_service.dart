import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CitaService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.0.3:8000/api';

  Map<String, String> _headers({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // Obtener todas las citas del cliente
  Future<Map<String, dynamic>> getCitas({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/citas/');
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Error al obtener citas: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener una cita específica
  Future<Map<String, dynamic>> getCita(int id, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/citas/$id/');
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Error al obtener cita: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Crear una nueva cita
  Future<Map<String, dynamic>> crearCita(
      Map<String, dynamic> citaData, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/citas/');
      final response = await http.post(
        url,
        headers: _headers(token: token),
        body: jsonEncode(citaData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': 'Error al crear cita',
          'errors': errorData
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Actualizar una cita
  Future<Map<String, dynamic>> actualizarCita(
      int id, Map<String, dynamic> citaData, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/citas/$id/');
      final response = await http.put(
        url,
        headers: _headers(token: token),
        body: jsonEncode(citaData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Error al actualizar cita: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Cancelar una cita
  Future<Map<String, dynamic>> cancelarCita(int id, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/citas/$id/');
      final response = await http.delete(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': 'Cita cancelada exitosamente'};
      } else {
        return {
          'success': false,
          'message': 'Error al cancelar cita: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
