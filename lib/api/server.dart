import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = "http://192.168.0.6:8000/api"; // Cambia a tu IP local

  // 🔹 Login → devuelve access y refresh
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/auth/token/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al iniciar sesión: ${response.body}");
    }
  }

  // 🔹 Obtener perfil
  Future<Map<String, dynamic>> getProfile(String token) async {
    final url = Uri.parse("$baseUrl/auth/me/");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener perfil: ${response.body}");
    }
  }

  // 🔹 Cambiar contraseña
  Future<Map<String, dynamic>> changePassword(
      String token, String oldPassword, String newPassword) async {
    final url = Uri.parse("$baseUrl/change-password/");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "old_password": oldPassword,
        "new_password": newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al cambiar contraseña: ${response.body}");
    }
  }

  // 🔹 Registrar usuario
  Future<Map<String, dynamic>> register(
      String username, String email, String password, String password2) async {
    final url = Uri.parse("$baseUrl/register/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
        "password2": password2,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al registrarse: ${response.body}");
    }
  }
}
