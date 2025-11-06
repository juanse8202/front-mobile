import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatbotService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? "http://192.168.0.3:8000/api";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Envía un mensaje al chatbot de Gemini
  Future<Map<String, dynamic>> sendMessage(String message) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      print('🤖 Enviando mensaje al chatbot: $message');
      print('🔑 Token: ${token != null ? "Presente" : "No disponible"}');
      print('🌐 URL: $baseUrl/ia/chatbot/');

      final response = await http.post(
        Uri.parse('$baseUrl/ia/chatbot/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': message}),
      );

      print('📊 Status Code: ${response.statusCode}');
      print('✅ Respuesta del chatbot: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'response': data['response'] ?? data['message'] ?? 'Sin respuesta',
        };
      } else if (response.statusCode == 403) {
        throw ChatbotException(
          'Acceso denegado. Verifica la configuración del backend.',
          response.statusCode,
        );
      } else if (response.statusCode == 503) {
        throw ChatbotException(
          'El servicio de chatbot no está disponible en este momento.',
          response.statusCode,
        );
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw ChatbotException(
          errorData['error'] ?? 'Mensaje inválido. Por favor intenta de nuevo.',
          response.statusCode,
        );
      } else if (response.statusCode == 500) {
        final errorData = jsonDecode(response.body);
        throw ChatbotException(
          errorData['error'] ?? 'Error del servidor. Por favor contacta al administrador.',
          response.statusCode,
        );
      } else if (response.statusCode == 401) {
        throw ChatbotException(
          'Sesión expirada. Por favor inicia sesión nuevamente.',
          response.statusCode,
        );
      } else {
        throw ChatbotException(
          'Error al comunicarse con el chatbot. Por favor intenta de nuevo.',
          response.statusCode,
        );
      }
    } catch (e) {
      print('❌ Error completo: $e');
      
      if (e is ChatbotException) {
        rethrow;
      }
      
      throw ChatbotException(
        'Error de conexión. Verifica tu internet e intenta de nuevo.',
        0,
      );
    }
  }
}

/// Excepción personalizada para errores del chatbot
class ChatbotException implements Exception {
  final String message;
  final int statusCode;

  ChatbotException(this.message, this.statusCode);

  @override
  String toString() => message;
}
