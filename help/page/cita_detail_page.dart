import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../api/citas_api.dart';

class CitaDetailPage extends StatefulWidget {
  const CitaDetailPage({super.key});

  @override
  State<CitaDetailPage> createState() => _CitaDetailPageState();
}

class _CitaDetailPageState extends State<CitaDetailPage> {
  int? _citaId;
  Map<String, dynamic>? _cita;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['id'] != null) {
      _citaId = args['id'] as int;
      _loadCita();
    }
  }

  Future<void> _loadCita() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await CitasApi.fetchCitaById(_citaId!);
      setState(() {
        _cita = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar la cita: $e';
        _loading = false;
      });
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Está seguro de que desea eliminar esta cita?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CitasApi.deleteCita(_citaId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita eliminada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleWhatsApp() async {
    if (_cita == null) return;

    final clienteInfo = _cita!['cliente_info'] ?? {};
    final telefono = clienteInfo['telefono'];

    if (telefono == null || telefono.toString().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El cliente no tiene un número de teléfono registrado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Formatear teléfono
    String phone = telefono.toString().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!phone.startsWith('591')) {
      phone = '591$phone';
    }

    // Generar mensaje
    final nombreCliente = '${clienteInfo['nombre'] ?? ''} ${clienteInfo['apellido'] ?? ''}'.trim();
    final fechaInicio = DateTime.parse(_cita!['fecha_hora_inicio']);
    final fechaFormateada = _formatDateForWhatsApp(fechaInicio);
    final observaciones = _cita!['nota'] ?? _cita!['descripcion'] ?? 'Sin observaciones';
    
    final mensaje = 'Hola *$nombreCliente*, queremos recordarte que tienes una cita en AUTOFIX el día $fechaFormateada. Te estaremos esperando, hasta pronto 🤚🏻 - Observaciones: $observaciones';
    final mensajeEncoded = Uri.encodeComponent(mensaje);
    
    final whatsappUrl = 'whatsapp://send?phone=$phone&text=$mensajeEncoded';
    final uri = Uri.parse(whatsappUrl);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Intentar con https si no se puede abrir la app
        final webUrl = 'https://wa.me/$phone?text=$mensajeEncoded';
        final webUri = Uri.parse(webUrl);
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.platformDefault);
        } else {
          throw 'No se pudo abrir WhatsApp';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDateForWhatsApp(DateTime date) {
    final weekdays = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'];
    final months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    
    final weekday = weekdays[date.weekday % 7];
    final day = date.day;
    final month = months[date.month - 1];
    final hours = date.hour;
    final minutes = date.minute;
    
    final ampm = hours >= 12 ? 'PM' : 'AM';
    final hours12 = hours % 12 == 0 ? 12 : hours % 12;
    final minutesStr = minutes.toString().padLeft(2, '0');
    
    return '$weekday, $day de $month a las $hours12:$minutesStr $ampm';
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy, HH:mm', 'es_ES').format(date);
  }

  Widget _buildEstadoBadge(String? estado) {
    final estadoLower = (estado ?? 'pendiente').toLowerCase();
    Color bgColor;
    Color textColor;
    String label;

    switch (estadoLower) {
      case 'confirmada':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = 'Confirmada';
        break;
      case 'cancelada':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = 'Cancelada';
        break;
      case 'completada':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        label = 'Completada';
        break;
      case 'pendiente':
      default:
        bgColor = Colors.yellow.shade100;
        textColor = Colors.yellow.shade900;
        label = 'Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getTipoCitaLabel(String? tipo) {
    switch (tipo) {
      case 'reparacion':
        return 'Reparación';
      case 'mantenimiento':
        return 'Mantenimiento';
      case 'diagnostico':
        return 'Diagnóstico';
      case 'entrega':
        return 'Entrega';
      default:
        return tipo ?? 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de Cita')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _cita == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de Cita')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              Text(_error ?? 'Error desconocido'),
              ElevatedButton(
                onPressed: _loadCita,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final clienteInfo = _cita!['cliente_info'] ?? {};
    final vehiculoInfo = _cita!['vehiculo_info'] ?? {};
    final empleadoInfo = _cita!['empleado_info'] ?? {};
    
    final fechaInicio = DateTime.parse(_cita!['fecha_hora_inicio']);
    final fechaFin = _cita!['fecha_hora_fin'] != null
        ? DateTime.parse(_cita!['fecha_hora_fin'])
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Cita'),
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con nombre y empleado
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${clienteInfo['nombre'] ?? 'Cliente'} ${clienteInfo['apellido'] ?? ''}'.trim(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '📅 ${_formatDateTime(fechaInicio)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade300,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (fechaFin != null)
                                    Text(
                                      ' - ${DateFormat('HH:mm').format(fechaFin)}',
                                      style: TextStyle(
                                        color: Colors.grey.shade300,
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (empleadoInfo['nombre'] != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade400, width: 2),
                                ),
                                child: Column(
                                  children: [
                                    const Text('👤', style: TextStyle(fontSize: 20)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Empleado',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      () {
                                        final nombre = empleadoInfo['nombre']?.toString() ?? '';
                                        final apellido = empleadoInfo['apellido']?.toString() ?? '';
                                        final nombreCorto = nombre.length > 10 ? nombre.substring(0, 10) : nombre;
                                        final apellidoCorto = apellido.length > 8 ? apellido.substring(0, 8) : apellido;
                                        return '$nombreCorto $apellidoCorto'.trim();
                                      }(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Información en cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Cliente',
                          '👤',
                          Colors.blue,
                          [
                            '${clienteInfo['nombre'] ?? ''} ${clienteInfo['apellido'] ?? ''}'.trim(),
                            if (clienteInfo['telefono'] != null)
                              '📞 ${clienteInfo['telefono']}',
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade600),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('ℹ️', style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Información',
                                    style: TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _getTipoCitaLabel(_cita!['tipo_cita']),
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              _buildEstadoBadge(_cita!['estado']),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  if (vehiculoInfo['numero_placa'] != null)
                    _buildInfoCard(
                      'Vehículo',
                      '🚗',
                      Colors.yellow,
                      [
                        '${vehiculoInfo['marca'] ?? ''} ${vehiculoInfo['modelo'] ?? ''}'.trim(),
                        'Placa: ${vehiculoInfo['numero_placa']}',
                        if (vehiculoInfo['color'] != null)
                          'Color: ${vehiculoInfo['color']}',
                      ],
                    ),
                  
                  if (empleadoInfo['nombre'] != null)
                    _buildInfoCard(
                      'Empleado Asignado',
                      '⚙️',
                      Colors.green,
                      [
                        '${empleadoInfo['nombre']} ${empleadoInfo['apellido'] ?? ''}'.trim(),
                        if (empleadoInfo['telefono'] != null)
                          '📞 ${empleadoInfo['telefono']}',
                        if (empleadoInfo['ci'] != null)
                          '🪪 CI: ${empleadoInfo['ci']}',
                      ],
                    )
                  else
                    _buildInfoCard(
                      'Empleado Asignado',
                      '⚙️',
                      Colors.green,
                      ['Sin empleado asignado'],
                    ),
                  
                  if (_cita!['descripcion'] != null && _cita!['descripcion'].toString().isNotEmpty)
                    _buildInfoCard(
                      'Descripción',
                      '📝',
                      Colors.cyan,
                      [_cita!['descripcion'].toString()],
                    ),
                  
                  if (_cita!['nota'] != null && _cita!['nota'].toString().isNotEmpty)
                    _buildInfoCard(
                      'Nota',
                      '📌',
                      Colors.orange,
                      [_cita!['nota'].toString()],
                    ),
                ],
              ),
            ),
          ),
          
          // Botones de acción
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón WhatsApp
                if (clienteInfo['telefono'] != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleWhatsApp,
                      icon: const Icon(Icons.chat, color: Colors.white),
                      label: const Text('Notificar por WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (clienteInfo['telefono'] != null) const SizedBox(height: 8),
                // Botones Editar y Eliminar
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/cita-form',
                            arguments: {'id': _citaId},
                          );
                          if (result == true) {
                            _loadCita();
                          }
                        },
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text('Editar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleDelete,
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: const Text('Eliminar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String icon, Color color, List<String> content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade700.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade600),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...content.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: item.contains('Container') || item.contains('Widget')
                    ? Container() // Si es un widget (badge), renderizarlo directamente
                    : Text(
                        item,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
              )),
        ],
      ),
    );
  }
}

