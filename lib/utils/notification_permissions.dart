import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class NotificationPermissions {
  /// Solicitar permisos de notificación (Android 13+)
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    // Verificar si ya tiene permiso
    final status = await Permission.notification.status;
    
    if (status.isGranted) {
      debugPrint('✅ Permiso de notificaciones ya concedido');
      return true;
    }
    
    if (status.isDenied) {
      // Mostrar diálogo explicativo antes de solicitar
      final shouldRequest = await _showPermissionDialog(context);
      
      if (!shouldRequest) {
        debugPrint('❌ Usuario rechazó solicitud de permiso');
        return false;
      }
      
      // Solicitar permiso
      final result = await Permission.notification.request();
      
      if (result.isGranted) {
        debugPrint('✅ Permiso de notificaciones concedido');
        return true;
      } else if (result.isPermanentlyDenied) {
        debugPrint('⚠️ Permiso permanentemente denegado');
        await _showSettingsDialog(context);
        return false;
      } else {
        debugPrint('❌ Permiso de notificaciones denegado');
        return false;
      }
    }
    
    if (status.isPermanentlyDenied) {
      debugPrint('⚠️ Permiso permanentemente denegado, abriendo configuración');
      await _showSettingsDialog(context);
      return false;
    }
    
    return false;
  }
  
  /// Mostrar diálogo explicativo
  static Future<bool> _showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.blue),
            SizedBox(width: 10),
            Text('Recibir notificaciones'),
          ],
        ),
        content: const Text(
          'Para mantenerte al día con tus citas y órdenes de trabajo, '
          'necesitamos tu permiso para enviarte notificaciones.\n\n'
          '¿Deseas activar las notificaciones?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, gracias'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Activar'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// Mostrar diálogo para ir a configuración
  static Future<void> _showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings, color: Colors.orange),
            SizedBox(width: 10),
            Text('Permiso requerido'),
          ],
        ),
        content: const Text(
          'Las notificaciones están desactivadas. Para recibirlas, '
          'debes activarlas en la configuración de la aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Ir a Configuración'),
          ),
        ],
      ),
    );
  }
}
