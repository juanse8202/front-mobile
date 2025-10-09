import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? "http://192.168.0.3:8000/api";

  // 🔹 Headers con o sin token
  Map<String, String> _headers({String? token}) {
    final headers = {"Content-Type": "application/json"};
    if (token != null) headers["Authorization"] = "Bearer $token";
    return headers;
  }

  // 🔹 POST genérico con manejo de errores
  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> body,
      {String? token}) async {
    try {
      final url = Uri.parse("$baseUrl/$endpoint");
      final response = await http.post(url, headers: _headers(token: token), body: jsonEncode(body));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["detail"] ?? "Error en $endpoint"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // 🔹 GET genérico con manejo de errores
  Future<Map<String, dynamic>> _get(String endpoint, {String? token}) async {
    try {
      final url = Uri.parse("$baseUrl/$endpoint");
      final response = await http.get(url, headers: _headers(token: token));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["detail"] ?? "Error en $endpoint"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // 🔹 Login
  Future<Map<String, dynamic>> login(String username, String password) {
    return _post("auth/token/", {"username": username, "password": password});
  }

  // 🔹 Registrar usuario
  Future<Map<String, dynamic>> register(
      String username, String email, String password, String password2) {
    return _post("register/", {
      "username": username,
      "email": email,
      "password": password,
      "password2": password2
    });
  }

  // 🔹 Obtener perfil
  Future<Map<String, dynamic>> getProfile(String token) {
    return _get("auth/me/", token: token);
  }

  // 🔹 Cambiar contraseña
  Future<Map<String, dynamic>> changePassword(
      String token, String oldPassword, String newPassword) {
    return _post(
      "change-password/",
      {"old_password": oldPassword, "new_password": newPassword},
      token: token,
    );
  }

  // 🔹 Actualizar perfil (nuevo método)
  Future<Map<String, dynamic>> updateProfile(
      String token, String firstName, String lastName, String email) {
    return _post(
      "update-profile/",
      {
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
      },
      token: token,
    );
  }
}
