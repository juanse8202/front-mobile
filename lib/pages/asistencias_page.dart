import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/asistencia_service.dart';
import '../services/empleado_service.dart';

class AsistenciasPage extends StatefulWidget {
  const AsistenciasPage({super.key});

  @override
  State<AsistenciasPage> createState() => _AsistenciasPageState();
}

class _AsistenciasPageState extends State<AsistenciasPage> {
  final AsistenciaService _asistenciaService = AsistenciaService();
  final EmpleadoService _empleadoService = EmpleadoService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  bool _loading = false;
  String? _error;
  String? _userRole;
  
  // Para admin (reporte)
  List<dynamic> _asistencias = [];
  List<dynamic> _empleados = [];
  String _fechaFiltro = '';
  String? _empleadoFiltro;
  String? _estadoFiltro;

  @override
  void initState() {
    super.initState();
    _cargarRolYVerificar();
  }

  Future<void> _cargarRolYVerificar() async {
    final role = await _storage.read(key: 'user_role');
    setState(() {
      _userRole = role?.toLowerCase();
    });
    
    // Esta página es solo para admin (reporte)
    if (_userRole == 'admin' || _userRole == 'administrador') {
      _cargarDatosAdmin();
    }
  }

  Future<void> _cargarDatosAdmin() async {
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

      // Cargar empleados
      final empleadosRes = await _empleadoService.getEmpleados();
      if (empleadosRes['success']) {
        setState(() {
          _empleados = empleadosRes['data'] ?? [];
        });
      }

      // Cargar asistencias
      // Si no hay fecha filtro, no enviar fecha para obtener todas las asistencias
      final fecha = _fechaFiltro.isEmpty ? null : _fechaFiltro;
      
      final asistenciasRes = await _asistenciaService.getAsistencias(
        token: token,
        fecha: fecha,
        empleadoId: _empleadoFiltro,
        estado: _estadoFiltro,
      );

      if (asistenciasRes['success']) {
        final data = asistenciasRes['data'];
        print('[ASISTENCIAS PAGE] Datos recibidos: $data');
        print('[ASISTENCIAS PAGE] Tipo: ${data.runtimeType}');
        print('[ASISTENCIAS PAGE] Cantidad: ${data is List ? data.length : 'No es lista'}');
        
        setState(() {
          _asistencias = data is List ? data : [];
        });
        
        if (_asistencias.isEmpty) {
          print('[ASISTENCIAS PAGE] ⚠️ Lista de asistencias está vacía');
        } else {
          print('[ASISTENCIAS PAGE] ✅ Se cargaron ${_asistencias.length} asistencias');
        }
      } else {
        final errorMsg = asistenciasRes['message'] ?? 'Error al cargar asistencias';
        print('[ASISTENCIAS PAGE] ❌ Error: $errorMsg');
        setState(() {
          _error = errorMsg;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
      });
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

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'completo':
        return Colors.green;
      case 'incompleto':
        return Colors.red;
      case 'extra':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoLabel(String estado) {
    switch (estado.toLowerCase()) {
      case 'completo':
        return 'Completo';
      case 'incompleto':
        return 'Incompleto';
      case 'extra':
        return 'Extra';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Esta página es solo para admin (reporte)
    if (_userRole == 'admin' || _userRole == 'administrador') {
      return _buildVistaAdmin();
    }

    // Si no es admin, redirigir o mostrar mensaje
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Esta sección es solo para administradores.\nLos empleados deben usar "Mi Asistencia".'),
      ),
    );
  }

  Widget _buildVistaAdmin() {
    final fechaHoy = DateTime.now().toIso8601String().split('T')[0];
    if (_fechaFiltro.isEmpty) {
      _fechaFiltro = fechaHoy;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Asistencias'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filtros
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Fecha (opcional)',
                      hintText: 'YYYY-MM-DD o dejar vacío para todas',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                      helperText: 'Dejar vacío para ver todas las asistencias',
                    ),
                    controller: TextEditingController(text: _fechaFiltro),
                    onChanged: (value) {
                      setState(() {
                        _fechaFiltro = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Empleado',
                      border: OutlineInputBorder(),
                    ),
                    value: _empleadoFiltro,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ..._empleados.map((emp) => DropdownMenuItem(
                        value: emp['id'].toString(),
                        child: Text('${emp['nombre']} ${emp['apellido']}'),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _empleadoFiltro = value;
                      });
                      _cargarDatosAdmin();
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                    ),
                    value: _estadoFiltro,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(value: 'completo', child: Text('Completo')),
                      DropdownMenuItem(value: 'incompleto', child: Text('Incompleto')),
                      DropdownMenuItem(value: 'extra', child: Text('Extra')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _estadoFiltro = value;
                      });
                      _cargarDatosAdmin();
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _cargarDatosAdmin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Filtrar'),
                  ),
                ],
              ),
            ),
          ),

          // Lista de asistencias
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _asistencias.isEmpty
                    ? const Center(child: Text('No hay asistencias registradas'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _asistencias.length,
                        itemBuilder: (context, index) {
                          final asistencia = _asistencias[index];
                          final empleado = asistencia['empleado'];
                          final nombreEmpleado = empleado != null
                              ? '${empleado['nombre']} ${empleado['apellido']}'
                              : asistencia['nombre_empleado'] ?? 'N/A';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                nombreEmpleado,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16),
                                      const SizedBox(width: 4),
                                      Text(asistencia['fecha'] ?? '-'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.login, size: 16, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text('Entrada: ${_formatearHora(asistencia['hora_entrada'])}'),
                                    ],
                                  ),
                                  if (asistencia['hora_salida'] != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.logout, size: 16, color: Colors.orange),
                                        const SizedBox(width: 4),
                                        Text('Salida: ${_formatearHora(asistencia['hora_salida'])}'),
                                      ],
                                    ),
                                    if (asistencia['horas_trabajadas'] != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, size: 16, color: Colors.blue),
                                          const SizedBox(width: 4),
                                          Text('Trabajadas: ${asistencia['horas_trabajadas'].toStringAsFixed(2)} hrs'),
                                        ],
                                      ),
                                    ],
                                  ],
                                  if (asistencia['horas_extras'] != null && asistencia['horas_extras'] > 0) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.add_circle, size: 16, color: Colors.blue),
                                        const SizedBox(width: 4),
                                        Text('Extras: ${asistencia['horas_extras'].toStringAsFixed(2)} hrs'),
                                      ],
                                    ),
                                  ],
                                  if (asistencia['horas_faltantes'] > 0) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.remove_circle, size: 16, color: Colors.red),
                                        const SizedBox(width: 4),
                                        Text('Faltantes: ${asistencia['horas_faltantes'].toStringAsFixed(2)} hrs'),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Chip(
                                label: Text(_getEstadoLabel(asistencia['estado'])),
                                backgroundColor: _getEstadoColor(asistencia['estado']).withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: _getEstadoColor(asistencia['estado']),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

}
