import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AsistenciaService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.0.3:8000/api';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Headers con Authorization JWT - NO cookies, NO CSRF
  // IMPORTANTE: Accept: application/json evita que Django redirija al login
  Map<String, String> _headers({required String token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Obtener token desde secure storage si no se proporciona
  Future<String?> _getToken({String? token}) async {
    if (token != null && token.isNotEmpty) {
      return token;
    }
    return await _storage.read(key: 'access_token');
  }

  // Marcar entrada o salida
  Future<Map<String, dynamic>> marcarAsistencia(String tipo, {String? token}) async {
    try {
      // Obtener token (del parámetro o de secure storage)
      final authToken = await _getToken(token: token);
      if (authToken == null || authToken.isEmpty) {
        return {
          'success': false,
          'message': 'No se encontró token de autenticación'
        };
      }

      final url = Uri.parse('$baseUrl/asistencia/marcar/');
      final response = await http.post(
        url,
        headers: _headers(token: authToken),
        body: json.encode({'tipo': tipo}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout al marcar asistencia');
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = json.decode(response.body);
          return {'success': true, 'data': data};
        } catch (e) {
          return {
            'success': false,
            'message': 'Error al procesar respuesta del servidor'
          };
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          String errorMessage = 'Error al marcar asistencia';
          if (errorData is Map<String, dynamic>) {
            errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
          }
          return {
            'success': false,
            'message': errorMessage,
            'errors': errorData
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error al marcar asistencia: ${response.statusCode}'
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener todas las asistencias (para admin)
  Future<Map<String, dynamic>> getAsistencias({
    String? token,
    String? fecha,
    String? empleadoId,
    String? estado,
  }) async {
    try {
      // Obtener token (del parámetro o de secure storage)
      final authToken = await _getToken(token: token);
      if (authToken == null || authToken.isEmpty) {
        return {
          'success': false,
          'message': 'No se encontró token de autenticación'
        };
      }

      final queryParams = <String, String>{};
      if (fecha != null && fecha.isNotEmpty) {
        queryParams['fecha'] = fecha;
      }
      if (empleadoId != null && empleadoId.isNotEmpty) {
        queryParams['empleado_id'] = empleadoId;
      }
      if (estado != null && estado.isNotEmpty) {
        queryParams['estado'] = estado;
      }

      final uri = Uri.parse('$baseUrl/asistencias/')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      print('[ASISTENCIAS SERVICE] URL: $uri');
      final response = await http.get(uri, headers: _headers(token: authToken));
      print('[ASISTENCIAS SERVICE] Status: ${response.statusCode}');
      print('[ASISTENCIAS SERVICE] Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = json.decode(response.body);
          print('[ASISTENCIAS SERVICE] Data type: ${data.runtimeType}');
          
          List<dynamic> asistenciasList = [];
          
          if (data is List) {
            asistenciasList = data;
            print('[ASISTENCIAS SERVICE] Es lista directa, cantidad: ${asistenciasList.length}');
          } else if (data is Map<String, dynamic>) {
            if (data.containsKey('results')) {
              asistenciasList = data['results'] ?? [];
              print('[ASISTENCIAS SERVICE] Tiene results, cantidad: ${asistenciasList.length}');
            } else if (data.containsKey('count')) {
              // Si tiene count pero no results, puede ser que results esté vacío
              asistenciasList = data['results'] ?? [];
              print('[ASISTENCIAS SERVICE] Tiene count: ${data['count']}, results: ${asistenciasList.length}');
            } else {
              // Si es un objeto pero no tiene results, intentar usar el objeto completo como lista
              print('[ASISTENCIAS SERVICE] No tiene results, intentando como lista');
              asistenciasList = [];
            }
          }
          
          return {
            'success': true,
            'data': asistenciasList
          };
        } catch (e) {
          print('[ASISTENCIAS SERVICE] Error al parsear JSON: $e');
          return {
            'success': false,
            'message': 'Error al procesar respuesta del servidor: $e'
          };
        }
      } else {
        print('[ASISTENCIAS SERVICE] Error HTTP: ${response.statusCode}');
        print('[ASISTENCIAS SERVICE] Error body: ${response.body}');
        return {
          'success': false,
          'message': 'Error al obtener asistencias: ${response.statusCode}',
          'error_body': response.body
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener reporte mensual (para admin)
  Future<Map<String, dynamic>> getReporteMensual(int anio, int mes, {String? token}) async {
    try {
      // Obtener token (del parámetro o de secure storage)
      final authToken = await _getToken(token: token);
      if (authToken == null || authToken.isEmpty) {
        return {
          'success': false,
          'message': 'No se encontró token de autenticación'
        };
      }

      final uri = Uri.parse('$baseUrl/asistencia/reporte-mensual/')
          .replace(queryParameters: {
        'año': anio.toString(),
        'mes': mes.toString(),
      });
      final response = await http.get(uri, headers: _headers(token: authToken));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = json.decode(response.body);
          return {'success': true, 'data': data};
        } catch (e) {
          return {
            'success': false,
            'message': 'Error al procesar respuesta del servidor'
          };
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          String errorMessage = 'Error al obtener reporte: ${response.statusCode}';
          if (errorData is Map<String, dynamic>) {
            errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
          }
          return {
            'success': false,
            'message': errorMessage
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error al obtener reporte: ${response.statusCode}'
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener mi asistencia del día actual (para empleado)
  Future<Map<String, dynamic>> getMiAsistencia({String? token}) async {
    try {
      // Obtener token (del parámetro o de secure storage)
      final authToken = await _getToken(token: token);
      if (authToken == null || authToken.isEmpty) {
        return {
          'success': false,
          'message': 'No se encontró token de autenticación'
        };
      }

      final uri = Uri.parse('$baseUrl/asistencia/mi-asistencia/');
      final response = await http.get(uri, headers: _headers(token: authToken));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = json.decode(response.body);
          return {'success': true, 'data': data};
        } catch (e) {
          return {
            'success': false,
            'message': 'Error al procesar respuesta del servidor'
          };
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          String errorMessage = 'Error al obtener asistencia: ${response.statusCode}';
          if (errorData is Map<String, dynamic>) {
            errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
          }
          return {
            'success': false,
            'message': errorMessage
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error al obtener asistencia: ${response.statusCode}'
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener historial de asistencias (para empleado)
  Future<Map<String, dynamic>> getMiHistorial({
    String? token,
    String? fechaDesde,
    String? fechaHasta,
    int? limite,
  }) async {
    try {
      // Obtener token (del parámetro o de secure storage)
      final authToken = await _getToken(token: token);
      if (authToken == null || authToken.isEmpty) {
        return {
          'success': false,
          'message': 'No se encontró token de autenticación'
        };
      }

      final queryParams = <String, String>{};
      if (fechaDesde != null && fechaDesde.isNotEmpty) {
        queryParams['fecha_desde'] = fechaDesde;
      }
      if (fechaHasta != null && fechaHasta.isNotEmpty) {
        queryParams['fecha_hasta'] = fechaHasta;
      }
      if (limite != null) {
        queryParams['limite'] = limite.toString();
      }

      final uri = Uri.parse('$baseUrl/asistencia/mi-historial/')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final response = await http.get(uri, headers: _headers(token: authToken));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = json.decode(response.body);
          return {'success': true, 'data': data};
        } catch (e) {
          return {
            'success': false,
            'message': 'Error al procesar respuesta del servidor'
          };
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          String errorMessage = 'Error al obtener historial: ${response.statusCode}';
          if (errorData is Map<String, dynamic>) {
            errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
          }
          return {
            'success': false,
            'message': errorMessage
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error al obtener historial: ${response.statusCode}'
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}

