import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CitaClienteService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.0.3:8000/api';

  Map<String, String> _headers({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  /// Obtener todas las citas del cliente con filtros opcionales
  Future<List<dynamic>> fetchAll({
    String? token,
    String? estado,
    String? tipoCita,
    String? fechaDesde,
    String? fechaHasta,
    int? vehiculoId,
    String? search,
  }) async {
    final query = <String, String>{};
    if (estado != null && estado.isNotEmpty) query['estado'] = estado;
    if (tipoCita != null && tipoCita.isNotEmpty) query['tipo_cita'] = tipoCita;
    if (fechaDesde != null && fechaDesde.isNotEmpty) query['fecha_desde'] = fechaDesde;
    if (fechaHasta != null && fechaHasta.isNotEmpty) query['fecha_hasta'] = fechaHasta;
    if (vehiculoId != null) query['vehiculo_id'] = '$vehiculoId';
    if (search != null && search.isNotEmpty) query['search'] = search;

    final uri = Uri.parse('$baseUrl/citas-cliente/')
        .replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: _headers(token: token));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      return data is List ? data : (data['results'] as List? ?? []);
    }
    throw Exception('Error fetching citas: ${res.statusCode} ${res.body}');
  }

  /// Crear una nueva cita
  Future<Map<String, dynamic>> create({
    required String? token,
    required int empleado,
    required int vehiculo,
    required String fechaHoraInicio,
    required String fechaHoraFin,
    required String tipoCita,
    String? descripcion,
  }) async {
    final body = {
      'empleado': empleado,
      'vehiculo': vehiculo,
      'fecha_hora_inicio': fechaHoraInicio,
      'fecha_hora_fin': fechaHoraFin,
      'tipo_cita': tipoCita,
      if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
    };

    final uri = Uri.parse('$baseUrl/citas-cliente/');
    final res = await http.post(
      uri,
      headers: _headers(token: token),
      body: jsonEncode(body),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    // Manejo de errores
    try {
      final errorData = jsonDecode(res.body) as Map<String, dynamic>;
      final errores = <String>[];
      errorData.forEach((key, value) {
        if (value is List) {
          errores.add('$key: ${value.join(", ")}');
        } else {
          errores.add('$key: $value');
        }
      });
      throw Exception(errores.join('. '));
    } catch (_) {
      throw Exception('Error al crear la cita: ${res.statusCode} ${res.body}');
    }
  }

  /// Confirmar cita (propuesta por empleado)
  Future<Map<String, dynamic>> confirmar(int id, {String? token}) async {
    final uri = Uri.parse('$baseUrl/citas-cliente/$id/confirmar/');
    final res = await http.post(uri, headers: _headers(token: token));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error al confirmar la cita: ${res.statusCode} ${res.body}');
  }

  /// Cancelar cita
  Future<Map<String, dynamic>> cancelar(int id, {String? token}) async {
    final uri = Uri.parse('$baseUrl/citas-cliente/$id/cancelar/');
    final res = await http.post(uri, headers: _headers(token: token));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error al cancelar la cita: ${res.statusCode} ${res.body}');
  }

  /// Reprogramar cita
  Future<Map<String, dynamic>> reprogramar({
    required int id,
    required String? token,
    required String fechaHoraInicio,
    required String fechaHoraFin,
    String? estado,
    int? vehiculo,
    String? descripcion,
    String? nota,
  }) async {
    final body = <String, dynamic>{
      'fecha_hora_inicio': fechaHoraInicio,
      'fecha_hora_fin': fechaHoraFin,
      if (estado != null && estado.isNotEmpty) 'estado': estado,
      if (vehiculo != null) 'vehiculo': vehiculo,
      if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
      if (nota != null && nota.isNotEmpty) 'nota': nota,
    };

    final uri = Uri.parse('$baseUrl/citas-cliente/$id/reprogramar/');
    final res = await http.post(
      uri,
      headers: _headers(token: token),
      body: jsonEncode(body),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    // Manejo de errores
    try {
      final errorData = jsonDecode(res.body) as Map<String, dynamic>;
      final msg = errorData['detail'] ??
          errorData['fecha_hora_inicio'] ??
          errorData['fecha_hora_fin'] ??
          'Error al reprogramar la cita';
      throw Exception(msg is List ? msg.first : msg.toString());
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al reprogramar la cita: ${res.statusCode} ${res.body}');
    }
  }

  /// Obtener calendario de un empleado (horarios ocupados)
  Future<Map<String, dynamic>> fetchCalendarioEmpleado(
    int empleadoId, {
    String? token,
    String? dia,
  }) async {
    final query = <String, String>{};
    if (dia != null && dia.isNotEmpty) query['dia'] = dia;

    final uri = Uri.parse('$baseUrl/citas-cliente/empleado/$empleadoId/calendario/')
        .replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: _headers(token: token));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error al obtener calendario: ${res.statusCode} ${res.body}');
  }

  /// Obtener ID del cliente autenticado
  Future<int?> getClienteId({String? token}) async {
    final uri = Uri.parse('$baseUrl/citas-cliente/mi-cliente-id/');
    final res = await http.get(uri, headers: _headers(token: token));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['cliente_id'] as int?;
    }
    return null;
  }

  /// Obtener vehículos del cliente autenticado
  Future<List<dynamic>> fetchVehiculosCliente({String? token}) async {
    try {
      final clienteId = await getClienteId(token: token);
      if (clienteId == null) return [];

      final uri = Uri.parse('$baseUrl/vehiculos/')
          .replace(queryParameters: {'cliente_id': '$clienteId'});
      final res = await http.get(uri, headers: _headers(token: token));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        return data is List ? data : (data['results'] as List? ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Obtener lista de empleados
  Future<List<dynamic>> fetchEmpleados({String? token}) async {
    final uri = Uri.parse('$baseUrl/empleados/');
    final res = await http.get(uri, headers: _headers(token: token));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      final empleados = data is List ? data : (data['results'] as List? ?? []);
      // Filtrar solo empleados activos
      return empleados.where((e) => e['estado'] != false).toList();
    }
    throw Exception('Error al obtener empleados: ${res.statusCode} ${res.body}');
  }
}


