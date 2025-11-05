import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FacturaService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.0.3:8000/api';

  Map<String, String> _headers({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // Obtener todas las facturas
  Future<Map<String, dynamic>> getFacturas({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/facturas-proveedor/');
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Error al obtener facturas: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener una factura por ID
  Future<Map<String, dynamic>> getFactura(int id, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/facturas-proveedor/$id/');
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Error al obtener factura: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener detalles de una factura
  Future<Map<String, dynamic>> getDetallesFactura(int facturaId, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/detalles-factura-proveedor/?factura=$facturaId');
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Error al obtener detalles: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener facturas por orden
  Future<Map<String, dynamic>> getFacturasPorOrden(int ordenId, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/facturas-proveedor/?orden=$ordenId');
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Error al obtener facturas: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Generar PDF de factura (devuelve URL o bytes)
  Future<Map<String, dynamic>> generarPdfFactura(int facturaId, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/facturas-proveedor/$facturaId/generar-pdf/');
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': response.bodyBytes,
          'contentType': response.headers['content-type']
        };
      } else {
        return {
          'success': false,
          'message': 'Error al generar PDF: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
