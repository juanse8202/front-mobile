import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PresupuestosApi {
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

  // ==================== PRESUPUESTOS ====================

  /// Obtener todos los presupuestos
  static Future<List<dynamic>> fetchAllPresupuestos() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/presupuestos/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Error al cargar presupuestos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener presupuesto por ID
  static Future<Map<String, dynamic>> fetchPresupuestoById(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/presupuestos/$id/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Error al cargar presupuesto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Crear nuevo presupuesto
  static Future<Map<String, dynamic>> createPresupuesto(
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/presupuestos/'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception('Error al crear presupuesto: $errorBody');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Actualizar presupuesto existente
  static Future<Map<String, dynamic>> updatePresupuesto(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/presupuestos/$id/'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception('Error al actualizar presupuesto: $errorBody');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Eliminar presupuesto
  static Future<void> deletePresupuesto(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/presupuestos/$id/'),
        headers: headers,
      );

      if (response.statusCode != 204) {
        throw Exception(
          'Error al eliminar presupuesto: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== DATOS AUXILIARES ====================

  /// Obtener lista de clientes
  static Future<List<dynamic>> fetchClientesForPresupuesto() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/clientes/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Error al cargar clientes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener lista de vehículos
  static Future<List<dynamic>> fetchVehiculosForPresupuesto({
    String? clienteId,
  }) async {
    try {
      final headers = await _getHeaders();

      // Construir URL con filtro opcional de cliente
      String url = '$baseUrl/vehiculos/';
      if (clienteId != null) {
        url += '?cliente_id=$clienteId';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Error al cargar vehículos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener lista de items/servicios
  static Future<List<dynamic>> fetchItemsForPresupuesto() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/items/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Error al cargar items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== EXPORTACIÓN ====================

  /// Exportar presupuesto a PDF
  static Future<List<int>> exportPresupuestoPDF(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/presupuestos/$id/export_pdf/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Error al exportar PDF: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Exportar presupuesto a Excel
  static Future<List<int>> exportPresupuestoExcel(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/presupuestos/$id/export_excel/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Error al exportar Excel: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
