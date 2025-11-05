import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RolService {
  final String baseUrl = 'http://192.168.0.3:8000/api';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Singleton para mantener caché de roles
  static final RolService _instance = RolService._internal();
  factory RolService() => _instance;
  RolService._internal();

  List<dynamic>? _rolesCache;

  Future<Map<String, dynamic>> getRoles() async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse('$baseUrl/groupsAux/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _rolesCache = json.decode(response.body);
        return {
          'success': true,
          'data': _rolesCache,
        };
      } else {
        return {
          'success': false,
          'message': 'Error al obtener roles: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Método para obtener roles desde caché o hacer petición
  Future<List<dynamic>> getRolesForDropdown() async {
    if (_rolesCache != null && _rolesCache!.isNotEmpty) {
      return _rolesCache!;
    }
    final response = await getRoles();
    return response['success'] ? response['data'] : [];
  }

  Future<Map<String, dynamic>> getRol(int id) async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse('$baseUrl/groupsAux/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Error al obtener rol: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  Future<Map<String, dynamic>> createRol(Map<String, dynamic> data) async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await http.post(
        Uri.parse('$baseUrl/groupsAux/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Error al crear rol: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateRol(int id, Map<String, dynamic> data) async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await http.put(
        Uri.parse('$baseUrl/groupsAux/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Error al actualizar rol: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteRol(int id) async {
    try {
      final token = await _storage.read(key: 'access_token');
      final response = await http.delete(
        Uri.parse('$baseUrl/groupsAux/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        return {
          'success': true,
          'message': 'Rol eliminado correctamente',
        };
      } else {
        return {
          'success': false,
          'message': 'Error al eliminar rol: ${response.statusCode}',
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
