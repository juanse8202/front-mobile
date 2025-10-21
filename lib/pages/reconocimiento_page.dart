import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/reconocimiento_service.dart';
import 'package:image_picker/image_picker.dart';

class ReconocimientoPage extends StatefulWidget {
  const ReconocimientoPage({super.key});

  @override
  State<ReconocimientoPage> createState() => _ReconocimientoPageState();
}

class _ReconocimientoPageState extends State<ReconocimientoPage> {
  final _storage = const FlutterSecureStorage();
  final _reconocimientoService = ReconocimientoService();
  final _picker = ImagePicker();

  File? _selectedImage;
  bool _isProcessing = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  /// 🔹 Solicitar permisos de cámara y galería
  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.photos.request();
  }

  /// 🔹 Capturar foto con la cámara
  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
          _result = null;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al capturar foto: ${e.toString()}';
      });
    }
  }

  /// 🔹 Seleccionar imagen de la galería
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _result = null;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al seleccionar imagen: ${e.toString()}';
      });
    }
  }

  /// 🔹 Procesar imagen para reconocimiento
  Future<void> _processImage() async {
    if (_selectedImage == null) {
      setState(() {
        _error = 'Por favor selecciona una imagen o captura una foto.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        setState(() {
          _error = 'No hay sesión activa. Por favor inicia sesión.';
          _isProcessing = false;
        });
        return;
      }

      final response = await _reconocimientoService.scanPlate(
        _selectedImage!.path,
        token,
        cameraId: 'mobile-camera',
      );

      if (response['success']) {
        setState(() {
          _result = response['data'];
          _isProcessing = false;
        });

        // Feedback visual
        if (_result?['match'] == true) {
          _showFeedback(Colors.green, '✅ VEHÍCULO REGISTRADO');
        } else {
          _showFeedback(Colors.red, '❌ VEHÍCULO NO REGISTRADO');
        }
      } else {
        setState(() {
          _error = response['message'] ?? 'Error al procesar la imagen';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  /// 🔹 Mostrar feedback visual con SnackBar
  void _showFeedback(Color color, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 🔹 Limpiar todo
  void _clearAll() {
    setState(() {
      _selectedImage = null;
      _result = null;
      _error = null;
    });
  }

  /// 🔹 Navegar a detalles de orden
  void _navigateToOrden(int ordenId) {
    Navigator.pushNamed(
      context,
      '/orden-detalles',
      arguments: ordenId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reconocimiento de Placas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔹 Título
            const Text(
              'Captura o selecciona una imagen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 Botones de captura
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _capturePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 🔹 Vista previa de imagen
            if (_selectedImage != null)
              Container(
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (_selectedImage != null) const SizedBox(height: 16),

            // 🔹 Botones de acción
            if (_selectedImage != null)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Reconocer Placa',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _clearAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Limpiar',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // 🔹 Errores
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // 🔹 Resultados
            if (_result != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  /// 🔹 Construir tarjeta de resultados
  Widget _buildResultCard() {
    final bool isMatch = _result?['match'] == true;
    final vehiculo = _result?['vehiculo'];
    final ordenesPendientes = _result?['ordenes_pendientes'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMatch ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: isMatch ? Colors.green : Colors.red,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Estado del reconocimiento
          Row(
            children: [
              Icon(
                isMatch ? Icons.check_circle : Icons.cancel,
                color: isMatch ? Colors.green : Colors.red,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isMatch ? '✅ VEHÍCULO REGISTRADO' : '❌ VEHÍCULO NO REGISTRADO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isMatch ? Colors.green.shade900 : Colors.red.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 🔹 Información básica
          _buildInfoRow('Placa detectada:', _result?['plate'] ?? 'No detectada'),
          _buildInfoRow(
            'Confianza:',
            '${((_result?['score'] ?? 0) * 100).toStringAsFixed(1)}%',
          ),
          _buildInfoRow('Estado:', _result?['status'] ?? 'N/A'),

          // 🔹 Información del vehículo
          if (vehiculo != null) ...[
            const Divider(height: 24, thickness: 1),
            const Text(
              '🚗 Información del Vehículo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Marca:', vehiculo['marca']?['nombre'] ?? 'N/A'),
                  _buildInfoRow('Modelo:', vehiculo['modelo']?['nombre'] ?? 'N/A'),
                  _buildInfoRow('Color:', vehiculo['color'] ?? 'N/A'),
                  _buildInfoRow(
                    'Cliente:',
                    '${vehiculo['cliente']?['nombre'] ?? 'N/A'} ${vehiculo['cliente']?['apellido'] ?? ''}',
                  ),
                ],
              ),
            ),
          ],

          // 🔹 Órdenes de trabajo pendientes
          if (ordenesPendientes.isNotEmpty) ...[
            const Divider(height: 24, thickness: 1),
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Órdenes de Trabajo Pendientes (${ordenesPendientes.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...ordenesPendientes.map((orden) => _buildOrdenCard(orden)),
          ],

          // 🔹 Mensaje cuando no hay órdenes
          if (isMatch && ordenesPendientes.isEmpty) ...[
            const Divider(height: 24, thickness: 1),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Este vehículo no tiene órdenes de trabajo pendientes.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🔹 Construir fila de información
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Construir tarjeta de orden de trabajo
  Widget _buildOrdenCard(dynamic orden) {
    final int ordenId = orden['id'] ?? 0;
    final String estado = orden['estado'] ?? 'pendiente';
    final String fallo = orden['fallo_requerimiento'] ?? 'No especificado';
    final double total = (orden['total'] ?? 0).toDouble();
    final String fechaCreacion = orden['fecha_creacion'] ?? '';

    // Formatear fecha
    String fechaFormateada = 'N/A';
    try {
      final fecha = DateTime.parse(fechaCreacion);
      fechaFormateada = '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      // Si falla el parseo, dejar "N/A"
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToOrden(ordenId),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con ID y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orden #$ordenId',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        fechaFormateada,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: estado == 'pendiente'
                          ? Colors.yellow.shade100
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      estado == 'pendiente' ? 'PENDIENTE' : 'EN PROCESO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: estado == 'pendiente'
                            ? Colors.yellow.shade900
                            : Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Fallo/Requerimiento
              Text(
                'Fallo/Requerimiento: $fallo',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Total y botón
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: Bs. ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Row(
                    children: [
                      Text(
                        'Ver detalles',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: Colors.blue, size: 16),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
