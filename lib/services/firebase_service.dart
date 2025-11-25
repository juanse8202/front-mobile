import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 🔥 Función para manejar mensajes en segundo plano (debe estar fuera de la clase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 Mensaje en segundo plano: ${message.messageId}');
  debugPrint('Título: ${message.notification?.title}');
  debugPrint('Cuerpo: ${message.notification?.body}');
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  
  // Callback para navegación
  Function(String route, {Map<String, dynamic>? arguments})? onNavigate;

  // 🔧 Inicializar Firebase y notificaciones
  Future<void> initialize() async {
    try {
      // 1️⃣ Solicitar permisos de notificación
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Permisos de notificación concedidos');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('⚠️ Permisos provisionales concedidos');
      } else {
        debugPrint('❌ Permisos de notificación denegados');
        return;
      }

      // 2️⃣ Configurar notificaciones locales
      await _initializeLocalNotifications();

      // 3️⃣ Obtener token FCM con reintentos
      int maxRetries = 3;
      for (int i = 0; i < maxRetries; i++) {
        try {
          _fcmToken = await _messaging.getToken();
          if (_fcmToken != null) {
            debugPrint('🔑 FCM Token obtenido: $_fcmToken');
            break;
          } else {
            debugPrint('⚠️ Token FCM es null, reintentando... (${i + 1}/$maxRetries)');
            await Future.delayed(Duration(seconds: 2));
          }
        } catch (e) {
          debugPrint('❌ Error obteniendo token (intento ${i + 1}/$maxRetries): $e');
          if (i == maxRetries - 1) {
            debugPrint('⚠️ No se pudo obtener token FCM después de $maxRetries intentos');
            debugPrint('   Esto puede deberse a:');
            debugPrint('   - Falta de Google Play Services');
            debugPrint('   - Problemas de conectividad');
            debugPrint('   - Restricciones del dispositivo');
          } else {
            await Future.delayed(Duration(seconds: 2));
          }
        }
      }

      // 4️⃣ Configurar listeners
      _setupMessageHandlers();

      // 5️⃣ Configurar handler de mensajes en segundo plano
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // 6️⃣ Enviar token al backend (si el usuario está logueado)
      await _sendTokenToBackend();
    } catch (e) {
      debugPrint('❌ Error inicializando Firebase: $e');
    }
  }

  // 🔔 Inicializar notificaciones locales (para mostrar cuando la app está abierta)
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('📱 Notificación tocada: ${response.payload}');
        // Manejar navegación según el payload
        if (response.payload != null) {
          _handleNotificationNavigation(response.payload!);
        }
      },
    );

    // Crear canal de notificación para Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // ID
      'Notificaciones importantes', // Nombre
      description: 'Canal para notificaciones importantes de SmartSales',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // 📨 Configurar listeners de mensajes
  void _setupMessageHandlers() {
    // Cuando la app está en PRIMER PLANO
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Mensaje recibido en primer plano');
      debugPrint('Título: ${message.notification?.title}');
      debugPrint('Cuerpo: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      // Mostrar notificación local
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // Cuando el usuario toca la notificación y la app estaba en SEGUNDO PLANO
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📬 Notificación tocada (app en segundo plano)');
      debugPrint('Data: ${message.data}');
      _handleNotificationNavigation(jsonEncode(message.data));
    });

    // Verificar si la app se abrió desde una notificación
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📭 App abierta desde notificación');
        debugPrint('Data: ${message.data}');
        _handleNotificationNavigation(jsonEncode(message.data));
      }
    });
  }

  // 🧭 Manejar navegación desde notificaciones
  void _handleNotificationNavigation(String payload) {
    try {
      final data = jsonDecode(payload);
      final type = data['tipo'] ?? data['type']; // Soportar ambos campos
      
      debugPrint('🧭 Manejando navegación de notificación tipo: $type');
      debugPrint('📊 Data completa: $data');
      
      if (type == 'cita') {
        final citaId = data['cita_id'];
        
        debugPrint('📅 Nueva cita detectada con ID: $citaId');
        
        // Navegar a la página de citas
        if (onNavigate != null) {
          debugPrint('✅ Usando callback de navegación');
          // Convertir citaId a int si es String
          final id = citaId is String ? int.tryParse(citaId) ?? citaId : citaId;
          onNavigate!('/mis-citas', arguments: {
            'openDetailFor': id,
          });
        } else {
          debugPrint('⚠️ Callback de navegación no disponible, guardando para después');
          _pendingNotificationData = {
            'tipo': type,
            'cita_id': citaId,
          };
        }
      } else if (type == 'orden_finalizada') {
        final ordenId = data['orden_id'];
        
        debugPrint('🔧 Orden finalizada detectada: $ordenId');
        
        // Navegar a mis órdenes
        if (onNavigate != null) {
          debugPrint('✅ Navegando a mis órdenes');
          // Convertir ordenId a int si es String
          final id = ordenId is String ? int.tryParse(ordenId) ?? ordenId : ordenId;
          onNavigate!('/mis-ordenes', arguments: {
            'openDetailFor': id,
          });
        } else {
          debugPrint('⚠️ Callback de navegación no disponible, guardando para después');
          _pendingNotificationData = {
            'tipo': type,
            'orden_id': ordenId,
          };
        }
      }
    } catch (e) {
      debugPrint('❌ Error manejando navegación: $e');
    }
  }

  // Datos de notificación pendiente
  Map<String, dynamic>? _pendingNotificationData;
  Map<String, dynamic>? get pendingNotificationData => _pendingNotificationData;
  
  void clearPendingNotification() {
    _pendingNotificationData = null;
  }

  // 🔔 Mostrar notificación local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'Notificaciones importantes',
      channelDescription: 'Canal para notificaciones importantes de SmartSales',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'SmartSales',
      message.notification?.body ?? '',
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  // 📤 Enviar token al backend
  Future<void> _sendTokenToBackend() async {
    debugPrint('🔄 Intentando enviar token FCM al backend...');
    
    if (_fcmToken == null) {
      debugPrint('⚠️ No hay token FCM para enviar');
      return;
    }

    debugPrint('🔑 Token FCM disponible: ${_fcmToken!.substring(0, 30)}...');

    try {
      // Verificar si el usuario está logueado
      String? token = await _storage.read(key: 'access_token');
      if (token == null) {
        debugPrint('⚠️ Usuario no logueado, no se envía token FCM');
        return;
      }

      debugPrint('✅ Token de autenticación encontrado');

      // Obtener la URL base desde .env
      String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.0.3:8000';
      // Asegurarse de que termine con /api
      if (!baseUrl.contains('/api')) {
        if (baseUrl.endsWith('/')) {
          baseUrl = '${baseUrl}api';
        } else {
          baseUrl = '$baseUrl/api';
        }
      }
      // Eliminar barra final si existe
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }
      final url = Uri.parse('$baseUrl/device-token/register/');
      
      debugPrint('📍 Enviando a: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'token': _fcmToken,
          'platform': 'android',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Token FCM registrado exitosamente');
      } else if (response.statusCode == 400) {
        // El backend ahora maneja tokens duplicados automáticamente
        final responseBody = jsonDecode(response.body);
        if (responseBody['errors']?['token']?.toString().contains('already exists') == true) {
          debugPrint('⚠️ Token ya existe, pero el backend lo reasignó correctamente');
        } else {
          debugPrint('❌ Error validación: ${response.body}');
        }
      } else {
        debugPrint('❌ Error enviando token: ${response.statusCode}');
        debugPrint('Respuesta: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error enviando token al backend: $e');
    }
  }

  // 🔄 Actualizar token cuando cambia
  void onTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('🔄 Token FCM actualizado: $newToken');
      _sendTokenToBackend();
    });
  }

  // 🚀 Llamar después del login
  Future<void> registerTokenAfterLogin() async {
    await _sendTokenToBackend();
  }

  // 🚪 Eliminar token al hacer logout
  Future<void> unregisterToken() async {
    if (_fcmToken == null) return;

    try {
      String? token = await _storage.read(key: 'access_token');
      if (token == null) return;

      // Obtener la URL base desde .env
      String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.0.3:8000';
      // Asegurarse de que termine con /api
      if (!baseUrl.contains('/api')) {
        if (baseUrl.endsWith('/')) {
          baseUrl = '${baseUrl}api';
        } else {
          baseUrl = '$baseUrl/api';
        }
      }
      // Eliminar barra final si existe
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }
      final url = Uri.parse('$baseUrl/device-token/unregister/');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'token': _fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Token FCM eliminado del backend');
      }
    } catch (e) {
      debugPrint('❌ Error eliminando token: $e');
    }
  }
}
