import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReconocimientoService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? "http://192.168.0.3:8000/api";

  String _shortBody(String body, [int max = 400]) {
    if (body.length <= max) return body;
    return '${body.substring(0, max)}... (truncated)';
  }

  String _userMessageForSnippet(String snippet, int status) {
    final lower = snippet.toLowerCase();
    if (lower.contains('<!doctype') || lower.contains('<html')) {
      return 'El servidor devolvió HTML (posible redirect a página de login o error). Verifica BASE_URL y token. HTTP $status.';
    }
    return 'HTTP $status: $snippet';
  }

  /// 🔹 Escanear placa vehicular enviando imagen en base64
  /// Envía una imagen al backend para reconocimiento de placa
  /// [imagePath] - Ruta del archivo de imagen
  /// [token] - Token de autenticación
  /// [cameraId] - Identificador de la cámara (por defecto "mobile-camera")
  Future<Map<String, dynamic>> scanPlate(
    String imagePath, 
    String token, 
    {String cameraId = "mobile-camera"}
  ) async {
    try {
      final url = Uri.parse("$baseUrl/ia/alpr/");
      
      // Leer imagen y convertir a base64
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Enviar como JSON con base64
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'image_base64': base64Image,
          'camera_id': cameraId,
        }),
      );
      
      final contentType = response.headers['content-type'] ?? '';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (contentType.contains('application/json')) {
          try {
            final data = jsonDecode(response.body);
            return {"success": true, "data": data};
          } catch (e) {
            final snippet = _shortBody(response.body);
            print('ReconocimientoService POST $url - 2xx pero no JSON. status=${response.statusCode} body="$snippet"');
            return {"success": false, "message": _userMessageForSnippet(snippet, response.statusCode)};
          }
        } else {
          final snippet = _shortBody(response.body);
          print('ReconocimientoService POST $url - 2xx no-json. status=${response.statusCode} body="$snippet"');
          return {"success": false, "message": _userMessageForSnippet(snippet, response.statusCode)};
        }
      } else {
        if (contentType.contains('application/json')) {
          try {
            final data = jsonDecode(response.body);
            final msg = data["detail"] ?? data["message"] ?? data.toString();
            return {"success": false, "message": msg, "errors": data};
          } catch (_) {
            final snippet = _shortBody(response.body);
            print('ReconocimientoService POST $url - error no-json. status=${response.statusCode} body="$snippet"');
            return {"success": false, "message": _userMessageForSnippet(snippet, response.statusCode)};
          }
        } else {
          final snippet = response.body.isNotEmpty ? _shortBody(response.body) : 'No hay body';
          print('ReconocimientoService POST $url - error no-json. status=${response.statusCode} body="$snippet"');
          return {"success": false, "message": _userMessageForSnippet(snippet, response.statusCode)};
        }
      }
    } catch (e) {
      return {"success": false, "message": "Error al conectar: ${e.toString()}"};
    }
  }
}
