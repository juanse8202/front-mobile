import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ClienteService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.0.3:8000/api';

  Map<String, String> _headers({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<List<dynamic>> fetchAll({String? token, String? search}) async {
    final query = <String, String>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    final uri = Uri.parse('$baseUrl/clientes/').replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: _headers(token: token));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Error fetching clientes: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> createCliente(Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/clientes/');
    final res = await http.post(uri, headers: _headers(token: token), body: jsonEncode(body));
    return {'status': res.statusCode, 'body': res.body};
  }

  Future<Map<String, dynamic>> updateCliente(int id, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/clientes/$id/');
    final res = await http.put(uri, headers: _headers(token: token), body: jsonEncode(body));
    return {'status': res.statusCode, 'body': res.body};
  }

  Future<Map<String, dynamic>> deleteCliente(int id, {String? token}) async {
    final uri = Uri.parse('$baseUrl/clientes/$id/');
    final res = await http.delete(uri, headers: _headers(token: token));
    return {'status': res.statusCode, 'body': res.body};
  }

  Future<dynamic> getCliente(int id, {String? token}) async {
    final uri = Uri.parse('$baseUrl/clientes/$id/');
    final res = await http.get(uri, headers: _headers(token: token));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw Exception('Error fetching cliente: ${res.statusCode}');
  }
}




