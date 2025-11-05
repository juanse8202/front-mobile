import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PagoService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.0.3:8000/api';

  Map<String, String> _headers({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // Obtener pagos de una orden
  Future<Map<String, dynamic>> getPagosOrden(int ordenId, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/pagos/?orden=$ordenId');
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Error al obtener pagos: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Crear un pago manual
  Future<Map<String, dynamic>> crearPagoManual(
      Map<String, dynamic> pagoData, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/pagos/');
      final response = await http.post(
        url,
        headers: _headers(token: token),
        body: jsonEncode(pagoData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': 'Error al crear pago',
          'errors': errorData
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Iniciar pago con Stripe (crear Payment Intent)
  Future<Map<String, dynamic>> iniciarPagoStripe(
      int ordenId, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/pagos/create-payment-intent/');
      final response = await http.post(
        url,
        headers: _headers(token: token),
        body: jsonEncode({'orden_trabajo_id': ordenId}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorData = response.body.isNotEmpty 
            ? jsonDecode(response.body) 
            : {'error': 'Error desconocido'};
        return {
          'success': false,
          'message': errorData['error'] ?? 'Error al iniciar pago: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Verificar pago con Stripe
  Future<Map<String, dynamic>> verificarPagoStripe(
      String paymentIntentId, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/pagos/verify-payment/');
      final response = await http.post(
        url,
        headers: _headers(token: token),
        body: jsonEncode({'payment_intent_id': paymentIntentId}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorData = response.body.isNotEmpty 
            ? jsonDecode(response.body) 
            : {'error': 'Error desconocido'};
        return {
          'success': false,
          'message': errorData['error'] ?? 'Error al verificar pago: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Confirmar pago con Stripe
  Future<Map<String, dynamic>> confirmarPagoStripe(
      String paymentIntentId, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/pagos/confirmar-pago-stripe/');
      final response = await http.post(
        url,
        headers: _headers(token: token),
        body: jsonEncode({'payment_intent_id': paymentIntentId}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Error al confirmar pago: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Confirmar pago automáticamente con Stripe (modo prueba)
  Future<Map<String, dynamic>> confirmarPagoStripeAutomatico(
      String paymentIntentId, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/pagos/confirm-payment-auto/');
      final response = await http.post(
        url,
        headers: _headers(token: token),
        body: jsonEncode({'payment_intent_id': paymentIntentId}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorData = response.body.isNotEmpty 
            ? jsonDecode(response.body) 
            : {'error': 'Error desconocido'};
        return {
          'success': false,
          'message': errorData['error'] ?? 'Error al confirmar pago: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Confirmar pago con Stripe usando datos de tarjeta
  Future<Map<String, dynamic>> confirmarPagoStripeConTarjeta(
      String paymentIntentId, {
        required String cardNumber,
        required String expMonth,
        required String expYear,
        required String cvc,
        String? token
      }) async {
    try {
      final url = Uri.parse('$baseUrl/pagos/confirm-payment-with-card/');
      print('🌐 URL completa: $url');
      print('📤 Enviando datos: payment_intent_id=$paymentIntentId, card=...${cardNumber.substring(cardNumber.length - 4)}');
      
      final response = await http.post(
        url,
        headers: _headers(token: token),
        body: jsonEncode({
          'payment_intent_id': paymentIntentId,
          'card_number': cardNumber,
          'exp_month': expMonth,
          'exp_year': expYear,
          'cvc': cvc,
        }),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response Body (primeros 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        // Verificar si la respuesta es HTML (error 404 o similar)
        if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
          return {
            'success': false,
            'message': 'Endpoint no encontrado (404). Verifica que el backend esté corriendo y la URL sea correcta.'
          };
        }
        
        final errorData = response.body.isNotEmpty 
            ? jsonDecode(response.body) 
            : {'error': 'Error desconocido'};
        return {
          'success': false,
          'message': errorData['error'] ?? 'Error al confirmar pago: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Exception completa: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener historial de pagos del cliente
  Future<Map<String, dynamic>> getHistorialPagos({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl/pagos/');
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Error al obtener historial: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
