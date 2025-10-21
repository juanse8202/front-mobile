import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OrdenTrabajoService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.0.3:8000/api';

  Map<String, String> _headers({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // ==================== ÓRDENES DE TRABAJO ====================
  
  /// Listar todas las órdenes de trabajo
  Future<List<dynamic>> fetchAll({String? token, String? estado, int? clienteId, int? vehiculoId}) async {
    final query = <String, String>{};
    if (estado != null && estado.isNotEmpty) query['estado'] = estado;
    if (clienteId != null) query['cliente_id'] = '$clienteId';
    if (vehiculoId != null) query['vehiculo_id'] = '$vehiculoId';
    
    final uri = Uri.parse('$baseUrl/ordenes/').replace(queryParameters: query.isEmpty ? null : query);
    
    // Debug: Imprimir la URL que se está llamando
    print('🌐 Llamando a: $uri');
    print('📊 Parámetros: estado=$estado, query=$query');
    
    final res = await http.get(uri, headers: _headers(token: token));
    
    print('📡 Respuesta: ${res.statusCode}');
    
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as List<dynamic>;
      print('📦 Órdenes obtenidas: ${data.length}');
      return data;
    }
    throw Exception('Error fetching órdenes de trabajo: ${res.statusCode} ${res.body}');
  }

  /// Obtener una orden de trabajo por ID (incluye detalles, notas, tareas, etc.)
  Future<Map<String, dynamic>> fetchById(int id, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$id/');
    final res = await http.get(uri, headers: _headers(token: token));
    
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error fetching orden de trabajo: ${res.statusCode} ${res.body}');
  }

  /// Crear una nueva orden de trabajo
  Future<Map<String, dynamic>> createOrden(Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/');
    print('📤 POST $uri');
    print('📦 Body: ${jsonEncode(body)}');
    
    final res = await http.post(uri, headers: _headers(token: token), body: jsonEncode(body));
    
    print('📡 Response status: ${res.statusCode}');
    print('📄 Response body: ${res.body}');
    
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    
    // Lanzar excepción si hay error
    throw Exception('Error creating orden: ${res.statusCode} - ${res.body}');
  }

  /// Actualizar una orden de trabajo
  Future<Map<String, dynamic>> updateOrden(int id, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$id/');
    final res = await http.patch(uri, headers: _headers(token: token), body: jsonEncode(body));
    
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error updating orden: ${res.statusCode} ${res.body}');
  }

  /// Eliminar una orden de trabajo
  Future<bool> deleteOrden(int id, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$id/');
    final res = await http.delete(uri, headers: _headers(token: token));
    if (res.statusCode == 204) return true;
    if (res.statusCode >= 200 && res.statusCode < 300) return true;
    return false;
  }

  // ==================== DETALLES DE ORDEN ====================

  /// Obtener detalles de una orden
  Future<List<dynamic>> fetchDetalles(int ordenId, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/detalles/');
    final res = await http.get(uri, headers: _headers(token: token));
    
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Error fetching detalles: ${res.statusCode} ${res.body}');
  }

  /// Crear un detalle en una orden
  Future<Map<String, dynamic>> createDetalle(int ordenId, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/detalles/');
    final res = await http.post(uri, headers: _headers(token: token), body: jsonEncode(body));
    return {'status': res.statusCode, 'body': res.body};
  }

  /// Actualizar un detalle
  Future<Map<String, dynamic>> updateDetalle(int ordenId, int detalleId, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/detalles/$detalleId/');
    final res = await http.put(uri, headers: _headers(token: token), body: jsonEncode(body));
    return {'status': res.statusCode, 'body': res.body};
  }

  /// Eliminar un detalle
  Future<bool> deleteDetalle(int ordenId, int detalleId, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/detalles/$detalleId/');
    final res = await http.delete(uri, headers: _headers(token: token));
    return res.statusCode == 204 || (res.statusCode >= 200 && res.statusCode < 300);
  }

  // ==================== NOTAS ====================

  /// Obtener notas de una orden
  Future<List<dynamic>> fetchNotas(int ordenId, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/notas/');
    final res = await http.get(uri, headers: _headers(token: token));
    
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Error fetching notas: ${res.statusCode} ${res.body}');
  }

  /// Crear una nota
  Future<Map<String, dynamic>> createNota(int ordenId, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/notas/');
    final res = await http.post(uri, headers: _headers(token: token), body: jsonEncode(body));
    return {'status': res.statusCode, 'body': res.body};
  }

  /// Eliminar una nota
  Future<bool> deleteNota(int ordenId, int notaId, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/notas/$notaId/');
    final res = await http.delete(uri, headers: _headers(token: token));
    return res.statusCode == 204 || (res.statusCode >= 200 && res.statusCode < 300);
  }

  // ==================== TAREAS ====================

  /// Obtener tareas de una orden
  Future<List<dynamic>> fetchTareas(int ordenId, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/tareas/');
    final res = await http.get(uri, headers: _headers(token: token));
    
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Error fetching tareas: ${res.statusCode} ${res.body}');
  }

  /// Crear una tarea
  Future<Map<String, dynamic>> createTarea(int ordenId, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/tareas/');
    final res = await http.post(uri, headers: _headers(token: token), body: jsonEncode(body));
    return {'status': res.statusCode, 'body': res.body};
  }

  /// Actualizar una tarea (ej: marcar como completada)
  Future<Map<String, dynamic>> updateTarea(int ordenId, int tareaId, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/tareas/$tareaId/');
    final res = await http.patch(uri, headers: _headers(token: token), body: jsonEncode(body));
    return {'status': res.statusCode, 'body': res.body};
  }

  /// Eliminar una tarea
  Future<bool> deleteTarea(int ordenId, int tareaId, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/tareas/$tareaId/');
    final res = await http.delete(uri, headers: _headers(token: token));
    return res.statusCode == 204 || (res.statusCode >= 200 && res.statusCode < 300);
  }

  // ==================== INVENTARIO DEL VEHÍCULO ====================

  /// Obtener inventario del vehículo
  Future<List<dynamic>> fetchInventario(int ordenId, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/inventario/');
    final res = await http.get(uri, headers: _headers(token: token));
    
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Error fetching inventario: ${res.statusCode} ${res.body}');
  }

  /// Actualizar inventario del vehículo
  Future<Map<String, dynamic>> updateInventario(int ordenId, int inventarioId, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/inventario/$inventarioId/');
    final res = await http.patch(uri, headers: _headers(token: token), body: jsonEncode(body));
    return {'status': res.statusCode, 'body': res.body};
  }

  // ==================== INSPECCIONES ====================

  /// Obtener inspecciones de una orden
  Future<List<dynamic>> fetchInspecciones(int ordenId, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/inspecciones/');
    final res = await http.get(uri, headers: _headers(token: token));
    
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Error fetching inspecciones: ${res.statusCode} ${res.body}');
  }

  /// Crear una inspección
  Future<Map<String, dynamic>> createInspeccion(int ordenId, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/inspecciones/');
    
    // Debug: imprimir datos que se envían
    print('🔍 Creando inspección en: $uri');
    print('📦 Datos enviados: ${jsonEncode(body)}');
    
    final res = await http.post(uri, headers: _headers(token: token), body: jsonEncode(body));
    
    print('📡 Respuesta: ${res.statusCode}');
    print('📄 Body: ${res.body}');
    
    return {'status': res.statusCode, 'body': res.body};
  }

  /// Actualizar una inspección
  Future<Map<String, dynamic>> updateInspeccion(int ordenId, int inspeccionId, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/inspecciones/$inspeccionId/');
    final res = await http.patch(uri, headers: _headers(token: token), body: jsonEncode(body));
    return {'status': res.statusCode, 'body': res.body};
  }

  /// Eliminar una inspección
  Future<bool> deleteInspeccion(int ordenId, int inspeccionId, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/inspecciones/$inspeccionId/');
    final res = await http.delete(uri, headers: _headers(token: token));
    return res.statusCode == 204 || (res.statusCode >= 200 && res.statusCode < 300);
  }

  // ==================== PRUEBAS DE RUTA ====================

  /// Obtener pruebas de ruta de una orden
  Future<List<dynamic>> fetchPruebasRuta(int ordenId, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/pruebas/');
    final res = await http.get(uri, headers: _headers(token: token));
    
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Error fetching pruebas de ruta: ${res.statusCode} ${res.body}');
  }

  /// Crear una prueba de ruta
  Future<Map<String, dynamic>> createPruebaRuta(int ordenId, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/pruebas/');
    
    // Debug: imprimir datos que se envían
    print('🔍 Creando prueba de ruta en: $uri');
    print('📦 Datos enviados: ${jsonEncode(body)}');
    
    final res = await http.post(uri, headers: _headers(token: token), body: jsonEncode(body));
    
    print('📡 Respuesta: ${res.statusCode}');
    print('📄 Body: ${res.body}');
    
    return {'status': res.statusCode, 'body': res.body};
  }

  /// Actualizar una prueba de ruta
  Future<Map<String, dynamic>> updatePruebaRuta(int ordenId, int pruebaId, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/pruebas/$pruebaId/');
    final res = await http.patch(uri, headers: _headers(token: token), body: jsonEncode(body));
    return {'status': res.statusCode, 'body': res.body};
  }

  /// Eliminar una prueba de ruta
  Future<bool> deletePruebaRuta(int ordenId, int pruebaId, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/pruebas/$pruebaId/');
    final res = await http.delete(uri, headers: _headers(token: token));
    return res.statusCode == 204 || (res.statusCode >= 200 && res.statusCode < 300);
  }

  // ==================== ASIGNACIONES DE TÉCNICOS ====================

  /// Obtener asignaciones de técnicos
  Future<List<dynamic>> fetchAsignaciones(int ordenId, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/asignaciones/');
    final res = await http.get(uri, headers: _headers(token: token));
    
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Error fetching asignaciones: ${res.statusCode} ${res.body}');
  }

  /// Crear una asignación de técnico
  Future<Map<String, dynamic>> createAsignacion(int ordenId, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/asignaciones/');
    final res = await http.post(uri, headers: _headers(token: token), body: jsonEncode(body));
    return {'status': res.statusCode, 'body': res.body};
  }

  /// Eliminar una asignación de técnico
  Future<bool> deleteAsignacion(int ordenId, int asignacionId, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/asignaciones/$asignacionId/');
    final res = await http.delete(uri, headers: _headers(token: token));
    return res.statusCode == 204 || (res.statusCode >= 200 && res.statusCode < 300);
  }

  // ==================== IMÁGENES ====================

  /// Obtener imágenes de una orden
  Future<List<dynamic>> fetchImagenes(int ordenId, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/imagenes/');
    final res = await http.get(uri, headers: _headers(token: token));
    
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Error fetching imágenes: ${res.statusCode} ${res.body}');
  }

  /// Crear una imagen (con URL)
  Future<Map<String, dynamic>> createImagen(int ordenId, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/imagenes/');
    final res = await http.post(uri, headers: _headers(token: token), body: jsonEncode(body));
    return {'status': res.statusCode, 'body': res.body};
  }

  /// Subir una imagen con archivo (multipart/form-data)
  Future<Map<String, dynamic>> uploadImagen(int ordenId, String filePath, {String? descripcion, String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/imagenes/');
    
    final request = http.MultipartRequest('POST', uri);
    
    // Agregar token si existe
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    // Agregar archivo
    request.files.add(await http.MultipartFile.fromPath('imagen_file', filePath));
    
    // Agregar descripción si existe
    if (descripcion != null && descripcion.isNotEmpty) {
      request.fields['descripcion'] = descripcion;
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    return {'status': response.statusCode, 'body': response.body};
  }

  /// Eliminar una imagen
  Future<bool> deleteImagen(int ordenId, int imagenId, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ordenes/$ordenId/imagenes/$imagenId/');
    final res = await http.delete(uri, headers: _headers(token: token));
    return res.statusCode == 204 || (res.statusCode >= 200 && res.statusCode < 300);
  }

  // ==================== EMPLEADOS ====================

  /// Obtener lista de empleados (para asignación de técnicos)
  Future<List<dynamic>> fetchEmpleados({String? token, String? search}) async {
    final query = <String, String>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    
    final empleadosUrl = '$baseUrl/empleados/';
    final uri = Uri.parse(empleadosUrl).replace(queryParameters: query.isEmpty ? null : query);
    
    final res = await http.get(uri, headers: _headers(token: token));
    
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Error fetching empleados: ${res.statusCode} ${res.body}');
  }

  // ==================== ITEMS ====================
  
  /// Obtener todos los items disponibles del catálogo
  Future<List<dynamic>> fetchItems({String? token, String? search}) async {
    final query = <String, String>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    
    final itemsUrl = '$baseUrl/items/';
    final uri = Uri.parse(itemsUrl).replace(queryParameters: query.isEmpty ? null : query);
    
    final res = await http.get(uri, headers: _headers(token: token));
    
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Error fetching items: ${res.statusCode} ${res.body}');
  }
}

