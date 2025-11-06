import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/cita_cliente_service.dart';
import 'nueva_cita_page.dart';

class MisCitasPage extends StatefulWidget {
  const MisCitasPage({super.key});

  @override
  State<MisCitasPage> createState() => _MisCitasPageState();
}

class _MisCitasPageState extends State<MisCitasPage> {
  final CitaClienteService _service = CitaClienteService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _searchCtrl = TextEditingController();
  
  String? token;
  bool loading = true;
  String? error;
  List<dynamic> citas = [];
  Map<int, String> origenMap = {}; // Map para rastrear origen de citas
  bool _initialized = false;
  
  // Filtros
  bool showFilters = false;
  String? filtroEstado;
  String? filtroTipoCita;
  DateTime? fechaDesde;
  DateTime? fechaHasta;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_initialized) return;
      await _loadToken();
      _initialized = true;
    });
  }

  Future<void> _loadToken() async {
    final storedToken = await _storage.read(key: 'access_token');
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['token'] is String) {
      token = args['token'] as String;
    } else if (storedToken != null) {
      token = storedToken;
    }
    if (token != null) {
      await _loadCitas();
    } else {
      setState(() {
        loading = false;
        error = 'No se encontró token de autenticación';
      });
    }
  }

  Future<void> _loadCitas() async {
    setState(() {
      loading = true;
      error = null;
    });
    
    try {
      final data = await _service.fetchAll(
        token: token,
        estado: filtroEstado,
        tipoCita: filtroTipoCita,
        fechaDesde: fechaDesde?.toIso8601String().split('T')[0],
        fechaHasta: fechaHasta?.toIso8601String().split('T')[0],
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );
      
      // Ordenar por fecha_creacion desc (más recientes primero)
      final sorted = List<dynamic>.from(data);
      sorted.sort((a, b) {
        final aDate = a['fecha_creacion'] ?? a['fecha_hora_inicio'] ?? '';
        final bDate = b['fecha_creacion'] ?? b['fecha_hora_inicio'] ?? '';
        if (aDate == '' || bDate == '') return 0;
        try {
          return DateTime.parse(bDate.toString()).compareTo(DateTime.parse(aDate.toString()));
        } catch (_) {
          return 0;
        }
      });
      
      // Actualizar mapa de origen
      final updated = Map<int, String>.from(origenMap);
      for (final cita in sorted) {
        final id = cita['id'] as int?;
        if (id != null && !updated.containsKey(id)) {
          // Heurística: si llega pendiente por primera vez, asumimos propuesta por empleado
          updated[id] = cita['estado'] == 'pendiente' ? 'empleado' : 'cliente';
        }
      }
      
      setState(() {
        citas = sorted;
        origenMap = updated;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  String _getOrigen(int citaId) {
    return origenMap[citaId] ?? 'cliente';
  }

  Widget _buildEstadoBadge(String? estado) {
    final estadoLower = (estado ?? '').toLowerCase();
    Color bgColor;
    Color textColor;
    String label;

    switch (estadoLower) {
      case 'confirmada':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = 'Confirmada';
        break;
      case 'pendiente':
        bgColor = Colors.yellow.shade100;
        textColor = Colors.yellow.shade900;
        label = 'Pendiente';
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
      default:
        bgColor = Colors.grey.shade300;
        textColor = Colors.grey.shade800;
        label = estado ?? 'Desconocido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  String _formatFecha(String? fechaStr) {
    if (fechaStr == null || fechaStr.isEmpty) return '-';
    try {
      final fecha = DateTime.parse(fechaStr);
      return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fechaStr;
    }
  }

  String _getTipoCitaLabel(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'reparacion':
        return 'Reparación';
      case 'mantenimiento':
        return 'Mantenimiento';
      case 'diagnostico':
        return 'Diagnóstico';
      default:
        return tipo ?? '-';
    }
  }

  Future<void> _handleConfirmar(int id) async {
    try {
      await _service.confirmar(id, token: token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita confirmada'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadCitas();
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

  Future<void> _handleCancelar(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: const Text('¿Estás seguro de cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.cancelar(id, token: token);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita cancelada'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadCitas();
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

  void _showDetalleCita(Map<String, dynamic> cita) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detalles de la Cita'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleRow('Estado', _buildEstadoBadge(cita['estado'])),
              const SizedBox(height: 8),
              _buildDetalleRow('Tipo', Text(_getTipoCitaLabel(cita['tipo_cita']))),
              const SizedBox(height: 8),
              _buildDetalleRow('Fecha Inicio', Text(_formatFecha(cita['fecha_hora_inicio']))),
              const SizedBox(height: 8),
              _buildDetalleRow('Fecha Fin', Text(_formatFecha(cita['fecha_hora_fin']))),
              const SizedBox(height: 8),
              _buildDetalleRow('Vehículo', Text(cita['vehiculo_info']?['numero_placa'] ?? '-')),
              const SizedBox(height: 8),
              _buildDetalleRow('Empleado', Text(
                '${cita['empleado_info']?['nombre'] ?? ''} ${cita['empleado_info']?['apellido'] ?? ''}'.trim()
              )),
              if (cita['descripcion'] != null && cita['descripcion'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetalleRow('Descripción', Text(cita['descripcion'])),
              ],
              if (cita['nota'] != null && cita['nota'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetalleRow('Nota', Text(cita['nota'])),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleRow(String label, Widget value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: value),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Buscar por placa, empleado, descripción...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        onChanged: (_) => _loadCitas(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        color: showFilters ? Colors.deepPurple : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => showFilters = !showFilters);
                      },
                    ),
                  ],
                ),
                if (showFilters) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: filtroEstado,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Todos')),
                            DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                            DropdownMenuItem(value: 'confirmada', child: Text('Confirmada')),
                            DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
                            DropdownMenuItem(value: 'completada', child: Text('Completada')),
                          ],
                          onChanged: (value) {
                            setState(() => filtroEstado = value);
                            _loadCitas();
                          },
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: filtroTipoCita,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de Cita',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Todos')),
                            DropdownMenuItem(value: 'reparacion', child: Text('Reparación')),
                            DropdownMenuItem(value: 'mantenimiento', child: Text('Mantenimiento')),
                            DropdownMenuItem(value: 'diagnostico', child: Text('Diagnóstico')),
                          ],
                          onChanged: (value) {
                            setState(() => filtroTipoCita = value);
                            _loadCitas();
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: fechaDesde ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (date != null) {
                                    setState(() => fechaDesde = date);
                                    _loadCitas();
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Desde',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    fechaDesde != null
                                        ? '${fechaDesde!.day}/${fechaDesde!.month}/${fechaDesde!.year}'
                                        : 'Seleccionar',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: fechaHasta ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (date != null) {
                                    setState(() => fechaHasta = date);
                                    _loadCitas();
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Hasta',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    fechaHasta != null
                                        ? '${fechaHasta!.day}/${fechaHasta!.month}/${fechaHasta!.year}'
                                        : 'Seleccionar',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Lista de citas
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Error: $error', textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadCitas,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : citas.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_busy, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No hay citas registradas'),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCitas,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: citas.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final cita = citas[index] as Map<String, dynamic>;
                                final origen = _getOrigen(cita['id'] as int);
                                final estado = cita['estado'] as String? ?? '';
                                final esEmpleado = origen == 'empleado';
                                final esCliente = origen == 'cliente';
                                final puedeConfirmar = esEmpleado && estado == 'pendiente';
                                final puedeCancelar = esEmpleado && estado == 'pendiente';
                                final puedeReprogramar = esCliente && estado != 'cancelada' && estado != 'completada';

                                return Card(
                                  color: esEmpleado ? Colors.yellow.shade50 : Colors.white,
                                  elevation: 2,
                                  child: InkWell(
                                    onTap: () => _showDetalleCita(cita),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          'Cita #${cita['id']}',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        _buildEstadoBadge(estado),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _formatFecha(cita['fecha_hora_inicio']),
                                                      style: TextStyle(
                                                        color: Colors.grey.shade700,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.visibility),
                                                onPressed: () => _showDetalleCita(cita),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.directions_car, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                cita['vehiculo_info']?['numero_placa'] ?? '-',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                              const SizedBox(width: 16),
                                              const Icon(Icons.person, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  '${cita['empleado_info']?['nombre'] ?? ''} ${cita['empleado_info']?['apellido'] ?? ''}'.trim(),
                                                  style: const TextStyle(fontSize: 14),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              if (puedeConfirmar)
                                                FilledButton.icon(
                                                  onPressed: () => _handleConfirmar(cita['id'] as int),
                                                  icon: const Icon(Icons.check, size: 16),
                                                  label: const Text('Confirmar'),
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: Colors.green,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  ),
                                                ),
                                              if (puedeCancelar)
                                                FilledButton.icon(
                                                  onPressed: () => _handleCancelar(cita['id'] as int),
                                                  icon: const Icon(Icons.cancel, size: 16),
                                                  label: const Text('Cancelar'),
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  ),
                                                ),
                                              if (puedeReprogramar)
                                                FilledButton.icon(
                                                  onPressed: () async {
                                                    final result = await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (ctx) => NuevaCitaPage(
                                                          token: token,
                                                          mode: 'edit',
                                                          initialCita: cita,
                                                        ),
                                                      ),
                                                    );
                                                    if (result == true) {
                                                      await _loadCitas();
                                                    }
                                                  },
                                                  icon: const Icon(Icons.edit, size: 16),
                                                  label: const Text('Reprogramar'),
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: Colors.blue,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => NuevaCitaPage(token: token),
            ),
          );
          if (result == true) {
            await _loadCitas();
          }
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}


