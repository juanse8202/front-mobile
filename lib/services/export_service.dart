import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

class ExportService {
  static const storage = FlutterSecureStorage();
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://192.168.0.3:8000/api';

  /// Obtener token de autenticación
  static Future<String?> _getToken() async {
    return await storage.read(key: 'access_token');
  }

  /// Descarga un pago en formato PDF y retorna los bytes
  static Future<List<int>> descargarPagoPDF(int pagoId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        debugPrint('❌ No hay token de autenticación');
        throw Exception('No autenticado');
      }

      final url = Uri.parse('$baseUrl/pagos/$pagoId/export/pdf/');
      
      debugPrint('📥 Descargando PDF del pago #$pagoId...');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ PDF descargado correctamente');
        return response.bodyBytes;
      } else {
        debugPrint('❌ Error al descargar PDF: ${response.statusCode}');
        debugPrint('Respuesta: ${response.body}');
        throw Exception('Error al descargar PDF: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en descargarPagoPDF: $e');
      rethrow;
    }
  }

  /// Descarga un pago en formato Excel y retorna los bytes
  static Future<List<int>> descargarPagoExcel(int pagoId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        debugPrint('❌ No hay token de autenticación');
        throw Exception('No autenticado');
      }

      final url = Uri.parse('$baseUrl/pagos/$pagoId/export/excel/');
      
      debugPrint('📥 Descargando Excel del pago #$pagoId...');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Excel descargado correctamente');
        return response.bodyBytes;
      } else {
        debugPrint('❌ Error al descargar Excel: ${response.statusCode}');
        debugPrint('Respuesta: ${response.body}');
        throw Exception('Error al descargar Excel: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en descargarPagoExcel: $e');
      rethrow;
    }
  }
}
