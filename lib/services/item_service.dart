import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ItemService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.0.3:8000/api';

  Map<String, String> _headers({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // Obtener todos los items
  Future<Map<String, dynamic>> getItems({String? token, String? search}) async {
    try {
      var url = Uri.parse('$baseUrl/items/');
      if (search != null && search.isNotEmpty) {
        url = Uri.parse('$baseUrl/items/?search=$search');
      }
      
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Error al obtener items: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener un item por ID
  Future<Map<String, dynamic>> getItem(int id, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/items/$id/');
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Error al obtener item: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener items por categoría/tipo
  Future<Map<String, dynamic>> getItemsPorTipo(String tipo, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/items/?tipo=$tipo');
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Error al obtener items: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
