import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CitasApi {
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'http://192.168.0.3:8000/api';
  static const storage = FlutterSecureStorage();

  // Obtener token de autenticación
  static Future<String?> _getToken() async {
    return await storage.read(key: 'access_token');
  }

  // Headers con autenticación
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== CITAS ====================

  /// Obtener todas las citas con filtros opcionales
  static Future<List<dynamic>> fetchAllCitas({
    String? estado,
    String? tipoCita,
    String? fechaDesde,
    String? fechaHasta,
    String? clienteId,
    String? vehiculoId,
    String? empleadoId,
    String? search,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // Construir query parameters
      final queryParams = <String, String>{};
      if (estado != null && estado.isNotEmpty) queryParams['estado'] = estado;
      if (tipoCita != null && tipoCita.isNotEmpty) queryParams['tipo_cita'] = tipoCita;
      if (fechaDesde != null && fechaDesde.isNotEmpty) queryParams['fecha_desde'] = fechaDesde;
      if (fechaHasta != null && fechaHasta.isNotEmpty) queryParams['fecha_hasta'] = fechaHasta;
      if (clienteId != null && clienteId.isNotEmpty) queryParams['cliente_id'] = clienteId;
      if (vehiculoId != null && vehiculoId.isNotEmpty) queryParams['vehiculo_id'] = vehiculoId;
      if (empleadoId != null && empleadoId.isNotEmpty) queryParams['empleado_id'] = empleadoId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      
      final uri = Uri.parse('$baseUrl/citas/').replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      
      print('🌐 Llamando a: $uri');
      
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        // Si es una lista, devolverla directamente
        if (data is List) {
          return data;
        }
        // Si tiene results (paginación), devolver results
        if (data is Map && data.containsKey('results')) {
          return data['results'] as List<dynamic>;
        }
        return [];
      } else {
        throw Exception('Error al cargar citas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener una cita por ID
  static Future<Map<String, dynamic>> fetchCitaById(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/citas/$id/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Error al cargar cita: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Crear nueva cita
  static Future<Map<String, dynamic>> createCita(
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/citas/'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception('Error al crear cita: $errorBody');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Actualizar cita existente
  static Future<Map<String, dynamic>> updateCita(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/citas/$id/'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception('Error al actualizar cita: $errorBody');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Eliminar cita
  static Future<void> deleteCita(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/citas/$id/'),
        headers: headers,
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception(
          'Error al eliminar cita: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== DATOS AUXILIARES ====================

  /// Obtener lista de clientes
  static Future<List<dynamic>> fetchClientes() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/clientes/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data is List) return data;
        if (data is Map && data.containsKey('results')) {
          return data['results'] as List<dynamic>;
        }
        return [];
      } else {
        throw Exception('Error al cargar clientes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener lista de vehículos
  static Future<List<dynamic>> fetchVehiculos({String? clienteId}) async {
    try {
      final headers = await _getHeaders();

      String url = '$baseUrl/vehiculos/';
      final queryParams = <String, String>{};
      if (clienteId != null && clienteId.isNotEmpty) {
        queryParams['cliente_id'] = clienteId;
      }
      
      final uri = Uri.parse(url).replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data is List) return data;
        if (data is Map && data.containsKey('results')) {
          return data['results'] as List<dynamic>;
        }
        return [];
      } else {
        throw Exception('Error al cargar vehículos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener lista de empleados
  static Future<List<dynamic>> fetchEmpleados() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/empleados/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data is List) return data;
        if (data is Map && data.containsKey('results')) {
          return data['results'] as List<dynamic>;
        }
        return [];
      } else {
        throw Exception('Error al cargar empleados: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}

