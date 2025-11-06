import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/cita_service.dart';
import '../services/cliente_service.dart';
import '../services/vehiculo_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class CitasCalendarioPage extends StatefulWidget {
  const CitasCalendarioPage({super.key});

  @override
  State<CitasCalendarioPage> createState() => _CitasCalendarioPageState();
}

class _CitasCalendarioPageState extends State<CitasCalendarioPage> {
  final CitaService _citaService = CitaService();
  final ClienteService _clienteService = ClienteService();
  final VehiculoService _vehiculoService = VehiculoService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  List<dynamic> citas = [];
  List<dynamic> clientes = [];
  List<dynamic> vehiculos = [];
  bool loading = true;
  String? token;
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _citasPorDia = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    initializeDateFormatting('es_ES', null);
    _loadData();
  }

  Future<void> _loadData() async {
    token = await _storage.read(key: 'access_token');
    await Future.wait([
      _cargarCitas(),
      _cargarClientes(),
      _cargarVehiculos(),
    ]);
  }

  Future<void> _cargarCitas() async {
    setState(() => loading = true);
    try {
      final result = await _citaService.getCitas(token: token);
      if (result['success']) {
        setState(() {
          citas = result['data'] as List<dynamic>;
          _organizarCitasPorDia();
          loading = false;
        });
      } else {
        setState(() => loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Error al cargar citas')),
          );
        }
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _cargarClientes() async {
    try {
      final result = await _clienteService.fetchAll(token: token);
      setState(() {
        clientes = result;
      });
    } catch (e) {
      print('Error al cargar clientes: $e');
    }
  }

  Future<void> _cargarVehiculos() async {
    try {
      final result = await _vehiculoService.fetchAll(token: token);
      setState(() {
        vehiculos = result;
      });
    } catch (e) {
      print('Error al cargar vehículos: $e');
    }
  }

  void _organizarCitasPorDia() {
    _citasPorDia.clear();
    for (var cita in citas) {
      try {
        final fechaInicio = DateTime.parse(cita['fecha_hora_inicio']);
        final fecha = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
        
        if (_citasPorDia[fecha] == null) {
          _citasPorDia[fecha] = [];
        }
        _citasPorDia[fecha]!.add(cita);
      } catch (e) {
        print('Error al parsear fecha: $e');
      }
    }
  }

  List<dynamic> _getCitasDelDia(DateTime dia) {
    final fecha = DateTime(dia.year, dia.month, dia.day);
    return _citasPorDia[fecha] ?? [];
  }

  Color _getColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmada':
        return Colors.blue;
      case 'completada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTipoLabel(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'reparacion':
        return 'Reparación';
      case 'mantenimiento':
        return 'Mantenimiento';
      case 'diagnostico':
        return 'Diagnóstico';
      case 'entrega':
        return 'Entrega';
      default:
        return tipo;
    }
  }

  Future<void> _mostrarDialogoCita({Map<String, dynamic>? cita}) async {
    final esEdicion = cita != null;
    
    int? clienteSeleccionado = cita?['cliente'];
    int? vehiculoSeleccionado = cita?['vehiculo'];
    String tipoCita = cita?['tipo_cita'] ?? 'reparacion';
    String estado = cita?['estado'] ?? 'pendiente';
    
    final fechaController = TextEditingController(
      text: cita != null && cita['fecha_hora_inicio'] != null
          ? DateFormat('dd/MM/yyyy').format(DateTime.parse(cita['fecha_hora_inicio']))
          : DateFormat('dd/MM/yyyy').format(_selectedDay ?? DateTime.now()),
    );
    final horaInicioController = TextEditingController(
      text: cita != null && cita['fecha_hora_inicio'] != null
          ? DateFormat('HH:mm').format(DateTime.parse(cita['fecha_hora_inicio']))
          : '09:00',
    );
    final horaFinController = TextEditingController(
      text: cita != null && cita['fecha_hora_fin'] != null
          ? DateFormat('HH:mm').format(DateTime.parse(cita['fecha_hora_fin']))
          : '10:00',
    );
    final descripcionController = TextEditingController(text: cita?['descripcion'] ?? '');
    final notaController = TextEditingController(text: cita?['nota'] ?? '');

    DateTime? fechaSeleccionada;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(esEdicion ? 'Editar Cita' : 'Nueva Cita'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cliente
                DropdownButtonFormField<int>(
                  value: clienteSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Cliente *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: clientes.map<DropdownMenuItem<int>>((cliente) {
                    final nombre = '${cliente['nombre']} ${cliente['apellido']}'.trim();
                    return DropdownMenuItem<int>(
                      value: cliente['id'] as int,
                      child: Text(nombre),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      clienteSeleccionado = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Vehículo
                DropdownButtonFormField<int?>(
                  value: vehiculoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Vehículo (Opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Sin vehículo'),
                    ),
                    ...vehiculos.map((vehiculo) {
                      final placa = vehiculo['placa'] ?? 'Sin placa';
                      final marca = vehiculo['marca'] ?? '';
                      return DropdownMenuItem(
                        value: vehiculo['id'],
                        child: Text('$placa - $marca'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      vehiculoSeleccionado = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Fecha
                TextField(
                  controller: fechaController,
                  decoration: const InputDecoration(
                    labelText: 'Fecha de la Cita *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      initialDate: _selectedDay ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (fecha != null) {
                      fechaSeleccionada = fecha;
                      fechaController.text = DateFormat('dd/MM/yyyy').format(fecha);
                    }
                  },
                ),
                const SizedBox(height: 12),
                
                // Horas
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: horaInicioController,
                        decoration: const InputDecoration(
                          labelText: 'Hora inicio',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final hora = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: 9, minute: 0),
                          );
                          if (hora != null) {
                            horaInicioController.text = 
                              '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: horaFinController,
                        decoration: const InputDecoration(
                          labelText: 'Hora fin',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final hora = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: 10, minute: 0),
                          );
                          if (hora != null) {
                            horaFinController.text = 
                              '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Tipo de cita
                DropdownButtonFormField<String>(
                  value: tipoCita,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Cita',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'reparacion', child: Text('Reparación')),
                    DropdownMenuItem(value: 'mantenimiento', child: Text('Mantenimiento')),
                    DropdownMenuItem(value: 'diagnostico', child: Text('Diagnóstico')),
                    DropdownMenuItem(value: 'entrega', child: Text('Entrega')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      tipoCita = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Estado
                if (esEdicion)
                  DropdownButtonFormField<String>(
                    value: estado,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                      DropdownMenuItem(value: 'confirmada', child: Text('Confirmada')),
                      DropdownMenuItem(value: 'completada', child: Text('Completada')),
                      DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        estado = value!;
                      });
                    },
                  ),
                if (esEdicion) const SizedBox(height: 12),
                
                // Descripción
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                
                // Nota
                TextField(
                  controller: notaController,
                  decoration: const InputDecoration(
                    labelText: 'Nota',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (clienteSeleccionado == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Debe seleccionar un cliente')),
                  );
                  return;
                }

                try {
                  // Parsear fecha y horas
                  DateTime fecha = fechaSeleccionada ?? 
                    (cita != null && cita['fecha_hora_inicio'] != null
                      ? DateTime.parse(cita['fecha_hora_inicio'])
                      : _selectedDay ?? DateTime.now());
                  
                  final horaInicioParts = horaInicioController.text.split(':');
                  final horaFinParts = horaFinController.text.split(':');
                  
                  final fechaHoraInicio = DateTime(
                    fecha.year,
                    fecha.month,
                    fecha.day,
                    int.parse(horaInicioParts[0]),
                    int.parse(horaInicioParts[1]),
                  );
                  
                  final fechaHoraFin = DateTime(
                    fecha.year,
                    fecha.month,
                    fecha.day,
                    int.parse(horaFinParts[0]),
                    int.parse(horaFinParts[1]),
                  );

                  final body = {
                    'cliente': clienteSeleccionado,
                    'vehiculo': vehiculoSeleccionado,
                    'fecha_hora_inicio': fechaHoraInicio.toIso8601String(),
                    'fecha_hora_fin': fechaHoraFin.toIso8601String(),
                    'tipo_cita': tipoCita,
                    'estado': estado,
                    'descripcion': descripcionController.text.trim(),
                    'nota': notaController.text.trim(),
                  };

                  final response = esEdicion
                      ? await _citaService.actualizarCita(cita['id'], body, token: token)
                      : await _citaService.crearCita(body, token: token);

                  if (response['success']) {
                    Navigator.pop(ctx, true);
                  } else {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(response['message'] ?? 'Error')),
                      );
                    }
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: Text(esEdicion ? 'Guardar' : 'Crear Cita'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _cargarCitas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(esEdicion ? 'Cita actualizada' : 'Cita creada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _eliminarCita(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar esta cita?'),
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
      final response = await _citaService.cancelarCita(id, token: token);
      if (response['success']) {
        await _cargarCitas();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita eliminada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Error')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Calendario de Citas'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getCitasDelDia,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
                const Divider(),
                Expanded(
                  child: _buildListaCitas(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => _mostrarDialogoCita(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListaCitas() {
    final citasDelDia = _getCitasDelDia(_selectedDay ?? DateTime.now());
    
    if (citasDelDia.isEmpty) {
      return Center(
        child: Text(
          'No hay citas para ${DateFormat('dd/MM/yyyy').format(_selectedDay ?? DateTime.now())}',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: citasDelDia.length,
      itemBuilder: (context, index) {
        final cita = citasDelDia[index];
        final fechaInicio = DateTime.parse(cita['fecha_hora_inicio']);
        final fechaFin = DateTime.parse(cita['fecha_hora_fin']);
        final horaInicio = DateFormat('HH:mm').format(fechaInicio);
        final horaFin = DateFormat('HH:mm').format(fechaFin);
        final estado = cita['estado'] ?? 'pendiente';
        final tipo = cita['tipo_cita'] ?? 'reparacion';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColorEstado(estado),
              child: const Icon(Icons.event, color: Colors.white),
            ),
            title: Text(
              '$horaInicio - $horaFin',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tipo: ${_getTipoLabel(tipo)}'),
                Text('Estado: ${estado[0].toUpperCase()}${estado.substring(1)}'),
                if (cita['descripcion'] != null && cita['descripcion'].isNotEmpty)
                  Text('Desc: ${cita['descripcion']}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'editar') {
                  _mostrarDialogoCita(cita: cita);
                } else if (value == 'eliminar') {
                  _eliminarCita(cita['id']);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
