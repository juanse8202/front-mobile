import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VehiculoService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.0.3:8000/api';

  Map<String, String> _headers({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // Listar vehículos con filtros y búsqueda
  Future<List<dynamic>> fetchAll({String? token, String? search, int? clienteId, int? marcaId, int? modeloId}) async {
    final query = <String, String>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (clienteId != null) query['cliente_id'] = '$clienteId';
    if (marcaId != null) query['marca_id'] = '$marcaId';
    if (modeloId != null) query['modelo_id'] = '$modeloId';
    final uri = Uri.parse('$baseUrl/vehiculos/').replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: _headers(token: token));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Error fetching vehículos: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>> fetchById(int id, {String? token}) async {
    final uri = Uri.parse('$baseUrl/vehiculos/$id/');
    final res = await http.get(uri, headers: _headers(token: token));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error fetching vehículo: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>> createVehiculo(Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/vehiculos/');
    final res = await http.post(uri, headers: _headers(token: token), body: jsonEncode(body));
    return {'status': res.statusCode, 'body': res.body};
  }

  Future<Map<String, dynamic>> updateVehiculo(int id, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/vehiculos/$id/');
    final res = await http.put(uri, headers: _headers(token: token), body: jsonEncode(body));
    return {'status': res.statusCode, 'body': res.body};
  }

  Future<bool> deleteVehiculo(int id, {String? token}) async {
    final uri = Uri.parse('$baseUrl/vehiculos/$id/');
    final res = await http.delete(uri, headers: _headers(token: token));
    if (res.statusCode == 204) return true;
    if (res.statusCode >= 200 && res.statusCode < 300) return true;
    return false;
  }

  Future<List<dynamic>> fetchMarcas({String? token}) async {
    final uri = Uri.parse('$baseUrl/vehiculos/marcas/');
    final res = await http.get(uri, headers: _headers(token: token));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Error fetching marcas');
  }

  Future<List<dynamic>> fetchModelos({int? marcaId, String? token}) async {
    final query = <String, String>{};
    if (marcaId != null) query['marca_id'] = '$marcaId';
    final uri = Uri.parse('$baseUrl/vehiculos/modelos/').replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: _headers(token: token));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Error fetching modelos');
  }
}


