import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BitacoraService {
  static const String baseUrl = 'http://192.168.0.3:8000/api';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> getBitacoras({
    String? search,
    String? ipAddress,
    String? modulo,
    String? accion,
    String? usuario,
  }) async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        return {
          'success': false,
          'message': 'No se encontró token de autenticación',
        };
      }

      // Construir query parameters
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (ipAddress != null && ipAddress.isNotEmpty) {
        queryParams['ip_address'] = ipAddress;
      }
      if (modulo != null && modulo.isNotEmpty) {
        queryParams['modulo'] = modulo;
      }
      if (accion != null && accion.isNotEmpty) {
        queryParams['accion'] = accion;
      }
      if (usuario != null && usuario.isNotEmpty) {
        queryParams['usuario'] = usuario;
      }

      final uri = Uri.parse('$baseUrl/bitacora/').replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'data': data is List ? data : [],
        };
      } else {
        return {
          'success': false,
          'message': 'Error al obtener bitácoras: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getBitacoraById(int id) async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        return {
          'success': false,
          'message': 'No se encontró token de autenticación',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/bitacora/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Error al obtener bitácora: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
}
