import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PresupuestoService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.0.3:8000/api';

  Map<String, String> _headers({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<List<dynamic>> fetchAll({String? token}) async {
    final url = Uri.parse('\$baseUrl/presupuestos/');
    final res = await http.get(url, headers: _headers(token: token));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Error fetching presupuestos: \\$res');
  }

  Future<Map<String, dynamic>> fetchById(int id, {String? token}) async {
    final url = Uri.parse('\$baseUrl/presupuestos/\$id/');
    final res = await http.get(url, headers: _headers(token: token));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error fetching presupuesto: \\$res');
  }

  Future<Map<String, dynamic>> createPresupuesto(Map<String, dynamic> body, {String? token}) async {
    final url = Uri.parse('\$baseUrl/presupuestos/');
    final res = await http.post(url, headers: _headers(token: token), body: jsonEncode(body));
    return {'status': res.statusCode, 'body': res.body};
  }

  Future<List<dynamic>> fetchDetalles(int presupuestoId, {String? token}) async {
    final url = Uri.parse('\$baseUrl/detalles-presupuesto/?presupuesto_id=\$presupuestoId');
    final res = await http.get(url, headers: _headers(token: token));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Error fetching detalles');
  }

  Future<Map<String, dynamic>> createDetalle(Map<String, dynamic> body, {String? token}) async {
    final url = Uri.parse('\$baseUrl/detalles-presupuesto/');
    final res = await http.post(url, headers: _headers(token: token), body: jsonEncode(body));
    return {'status': res.statusCode, 'body': res.body};
  }
}
