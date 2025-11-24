import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/asistencia_service.dart';

class MiAsistenciaPage extends StatefulWidget {
  const MiAsistenciaPage({super.key});

  @override
  State<MiAsistenciaPage> createState() => _MiAsistenciaPageState();
}

class _MiAsistenciaPageState extends State<MiAsistenciaPage> with SingleTickerProviderStateMixin {
  final AsistenciaService _asistenciaService = AsistenciaService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _ultimaMarcacion;
  bool _puedeMarcarEntrada = true;
  bool _puedeMarcarSalida = false;
  
  // Para historial
  late TabController _tabController;
  List<dynamic> _historial = [];
  bool _loadingHistorial = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _verificarEstadoMarcacion();
    _cargarHistorial();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _loadingHistorial = true;
    });

    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        setState(() {
          _loadingHistorial = false;
        });
        return;
      }

      final result = await _asistenciaService.getMiHistorial(token: token, limite: 30);

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        setState(() {
          _historial = data?['data'] as List<dynamic>? ?? [];
        });
      }
    } catch (e) {
      // Error silencioso para no interrumpir la experiencia
    } finally {
      setState(() {
        _loadingHistorial = false;
      });
    }
  }

  Future<void> _verificarEstadoMarcacion() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        setState(() {
          _error = 'No se encontró token de autenticación';
          _loading = false;
        });
        return;
      }

      // Usar el nuevo endpoint para obtener mi asistencia
      final result = await _asistenciaService.getMiAsistencia(token: token);

      if (result['success'] == true) {
        final asistenciaHoy = result['data'] as Map<String, dynamic>?;
        
        if (asistenciaHoy != null && asistenciaHoy['hora_entrada'] != null) {
          setState(() {
            _ultimaMarcacion = asistenciaHoy;
            _puedeMarcarEntrada = false; // Ya marcó entrada
            _puedeMarcarSalida = asistenciaHoy['hora_salida'] == null; // Solo puede marcar salida si no la ha marcado
          });
        } else {
          setState(() {
            _ultimaMarcacion = null;
            _puedeMarcarEntrada = true; // Puede marcar entrada
            _puedeMarcarSalida = false; // No puede marcar salida sin entrada
          });
        }
      } else {
        // Si hay error, permitir marcar entrada por defecto
        setState(() {
          _ultimaMarcacion = null;
          _puedeMarcarEntrada = true;
          _puedeMarcarSalida = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al verificar estado: $e';
        // En caso de error, permitir marcar entrada
        _puedeMarcarEntrada = true;
        _puedeMarcarSalida = false;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _marcarAsistencia(String tipo) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        setState(() {
          _error = 'No se encontró token de autenticación';
          _loading = false;
        });
        return;
      }

      final result = await _asistenciaService.marcarAsistencia(tipo, token: token);

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data?['mensaje'] ?? 'Asistencia marcada correctamente'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        // Recargar estado después de marcar
        await _verificarEstadoMarcacion();
        // Recargar historial también
        await _cargarHistorial();
      } else {
        setState(() {
          _error = result['message'] ?? 'Error al marcar asistencia';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_error!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String _formatearHora(String? hora) {
    if (hora == null) return '-';
    try {
      final time = hora.split(':');
      if (time.length >= 2) {
        return '${time[0]}:${time[1]}';
      }
      return hora;
    } catch (e) {
      return hora;
    }
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null) return '-';
    try {
      final date = DateTime.parse(fecha);
      final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
      final meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
      return '${dias[date.weekday - 1]}, ${date.day} de ${meses[date.month - 1]} de ${date.year}';
    } catch (e) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final fechaHoy = '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';
    // final esFinDeSemana = ahora.weekday >= 6; // COMENTADO TEMPORALMENTE PARA PRUEBAS

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Asistencia'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Marcar', icon: Icon(Icons.access_time)),
            Tab(text: 'Historial', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Marcar Asistencia
          _loading && _ultimaMarcacion == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Información del día actual
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            _formatearFecha(fechaHoy),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Mensaje de fin de semana - COMENTADO TEMPORALMENTE PARA PRUEBAS
                  // if (esFinDeSemana)
                  //   Card(
                  //     color: Colors.orange.shade50,
                  //     child: Padding(
                  //       padding: const EdgeInsets.all(16),
                  //       child: Row(
                  //         children: [
                  //           Icon(Icons.info_outline, color: Colors.orange.shade700),
                  //           const SizedBox(width: 12),
                  //           Expanded(
                  //             child: Text(
                  //               'Solo se puede marcar asistencia de lunes a viernes',
                  //               style: TextStyle(
                  //                 color: Colors.orange.shade700,
                  //                 fontWeight: FontWeight.w500,
                  //               ),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),

                  // if (esFinDeSemana) const SizedBox(height: 24),

                  // Estado de la última marcación
                  if (_ultimaMarcacion != null)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Última marcación:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text(
                                      'Entrada',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatearHora(_ultimaMarcacion!['hora_entrada']?.toString()),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.grey.shade300,
                                ),
                                Column(
                                  children: [
                                    const Text(
                                      'Salida',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatearHora(_ultimaMarcacion!['hora_salida']?.toString()),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (_ultimaMarcacion!['horas_trabajadas'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Horas trabajadas: ${_ultimaMarcacion!['horas_trabajadas']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_ultimaMarcacion!['horas_extras'] != null && _ultimaMarcacion!['horas_extras'] != '0:00:00')
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle,
                                      size: 16,
                                      color: Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Horas extras: ${_ultimaMarcacion!['horas_extras']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_ultimaMarcacion!['horas_faltantes'] != null && _ultimaMarcacion!['horas_faltantes'] != '0:00:00')
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.remove_circle,
                                      size: 16,
                                      color: Colors.red.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Horas faltantes: ${_ultimaMarcacion!['horas_faltantes']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  if (_ultimaMarcacion != null) const SizedBox(height: 24),

                  // Botones de marcación - Permitir todos los días para pruebas
                  // if (!esFinDeSemana) ...[
                  ...[
                    if (_puedeMarcarEntrada)
                      ElevatedButton.icon(
                        onPressed: _loading ? null : () => _marcarAsistencia('entrada'),
                        icon: const Icon(Icons.login, size: 24),
                        label: const Text(
                          'Marcar Entrada',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                    if (_puedeMarcarEntrada && _puedeMarcarSalida)
                      const SizedBox(height: 16),

                    if (_puedeMarcarSalida)
                      ElevatedButton.icon(
                        onPressed: _loading ? null : () => _marcarAsistencia('salida'),
                        icon: const Icon(Icons.logout, size: 24),
                        label: const Text(
                          'Marcar Salida',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],

                  // Mensaje de error
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          // Tab 2: Historial
          _buildHistorialTab(),
        ],
      ),
    );
  }

  Widget _buildHistorialTab() {
    if (_loadingHistorial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historial.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay historial de asistencias',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarHistorial,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _historial.length,
        itemBuilder: (context, index) {
          final asistencia = _historial[index];
          final fecha = asistencia['fecha'] as String?;
          final horaEntrada = asistencia['hora_entrada'] as String?;
          final horaSalida = asistencia['hora_salida'] as String?;
          final estado = asistencia['estado'] as String? ?? 'incompleto';
          
          Color estadoColor;
          String estadoLabel;
          switch (estado.toLowerCase()) {
            case 'completo':
              estadoColor = Colors.green;
              estadoLabel = 'Completo';
              break;
            case 'extra':
              estadoColor = Colors.blue;
              estadoLabel = 'Extra';
              break;
            default:
              estadoColor = Colors.orange;
              estadoLabel = 'Incompleto';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _formatearFecha(fecha),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: estadoColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: estadoColor, width: 1),
                        ),
                        child: Text(
                          estadoLabel,
                          style: TextStyle(
                            color: estadoColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Entrada',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatearHora(horaEntrada),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                      Column(
                        children: [
                          const Text(
                            'Salida',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatearHora(horaSalida),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (asistencia['horas_extras'] != null && asistencia['horas_extras'] != '0.00')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Horas extras: ${asistencia['horas_extras']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (asistencia['horas_faltantes'] != null && asistencia['horas_faltantes'] != '0.00')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove_circle, size: 16, color: Colors.red.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Horas faltantes: ${asistencia['horas_faltantes']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

