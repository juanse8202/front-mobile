import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReporteService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.0.3:8000/api';

  Map<String, String> _headers({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  /// Obtiene la lista de reportes estáticos disponibles
  Future<Map<String, dynamic>> obtenerReportesDisponibles({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/ia/reportes/disponibles/');
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'reportes': data['reportes'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': 'Error al obtener reportes: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Genera un reporte estático
  /// [tipoReporte]: Tipo de reporte (ordenes_estado, ordenes_pendientes, etc.)
  /// [formato]: Formato del archivo (PDF, XLSX)
  /// [fechaInicio]: Fecha inicio opcional para filtros
  /// [fechaFin]: Fecha fin opcional para filtros
  Future<Map<String, dynamic>> generarReporteEstatico({
    required String tipoReporte,
    required String formato,
    String? fechaInicio,
    String? fechaFin,
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/ia/reportes/generar_estatico/');
      
      final body = {
        'tipo_reporte': tipoReporte,
        'formato': formato,
      };
      
      if (fechaInicio != null) body['fecha_inicio'] = fechaInicio;
      if (fechaFin != null) body['fecha_fin'] = fechaFin;

      final response = await http.post(
        url,
        headers: _headers(token: token),
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'reporte': data['reporte'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Error al generar reporte',
          'errors': errorData['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Obtiene el historial de reportes del usuario
  Future<Map<String, dynamic>> obtenerHistorialReportes({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/ia/reportes/historial/');
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'reportes': data['reportes'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': 'Error al obtener historial: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Obtiene la URL de descarga de un reporte
  String obtenerUrlDescarga(int reporteId, String token) {
    return '$baseUrl/ia/reportes/$reporteId/descargar/?token=$token';
  }

  /// Descarga un reporte (retorna los bytes del archivo)
  Future<Map<String, dynamic>> descargarReporte({
    required int reporteId,
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/ia/reportes/$reporteId/descargar/');
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'bytes': response.bodyBytes,
          'contentType': response.headers['content-type'] ?? 'application/octet-stream',
        };
      } else {
        return {
          'success': false,
          'message': 'Error al descargar reporte: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Obtiene la lista de reportes del usuario (todos)
  Future<Map<String, dynamic>> obtenerReportes({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/ia/reportes/');
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        // Manejar tanto lista directa como objeto con resultados
        final reportes = data is List ? data : (data['results'] ?? data);
        return {
          'success': true,
          'reportes': reportes,
        };
      } else {
        return {
          'success': false,
          'message': 'Error al obtener reportes: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // ==================== REPORTES PERSONALIZADOS ====================

  /// Obtiene las entidades disponibles para reportes personalizados
  Future<Map<String, dynamic>> obtenerEntidadesDisponibles({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/ia/reportes/entidades/');
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'entidades': data['entidades'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': 'Error al obtener entidades: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Obtiene los campos disponibles para una entidad
  Future<Map<String, dynamic>> obtenerCamposEntidad({
    required String entidadId,
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/ia/reportes/entidades/$entidadId/campos/');
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'campos': data['campos'] ?? [],
          'filtros': data['filtros'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': 'Error al obtener campos: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Genera un reporte personalizado
  Future<Map<String, dynamic>> generarReportePersonalizado({
    required String nombre,
    required String entidad,
    required List<String> campos,
    required String formato,
    Map<String, dynamic>? filtros,
    List<String>? ordenamiento,
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/ia/reportes/generar-personalizado/');
      
      final body = {
        'nombre': nombre,
        'entidad': entidad,
        'campos': campos,
        'formato': formato,
      };
      
      if (filtros != null && filtros.isNotEmpty) body['filtros'] = filtros;
      if (ordenamiento != null && ordenamiento.isNotEmpty) body['ordenamiento'] = ordenamiento;

      final response = await http.post(
        url,
        headers: _headers(token: token),
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'reporte': data['reporte'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Error al generar reporte',
          'errors': errorData['errors'],
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
