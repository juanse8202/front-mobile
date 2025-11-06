import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/citas_api.dart';

class CitaFormPage extends StatefulWidget {
  const CitaFormPage({super.key});

  @override
  State<CitaFormPage> createState() => _CitaFormPageState();
}

class _CitaFormPageState extends State<CitaFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _saving = false;
  String? _error;

  // Datos auxiliares
  List<dynamic> _clientes = [];
  List<dynamic> _vehiculos = [];
  List<dynamic> _vehiculosFiltrados = [];
  List<dynamic> _empleados = [];

  // Variables del formulario
  String? _clienteId;
  String? _vehiculoId;
  String? _empleadoId;
  DateTime? _fechaDia;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  String _tipoCita = 'reparacion';
  String _estado = 'pendiente';
  final TextEditingController _notaController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  // Variables para edición
  int? _citaId;
  bool get _isEditing => _citaId != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['id'] != null) {
      _citaId = args['id'] as int;
      _loadCita(_citaId!);
    } else if (args != null && args['selectedDate'] != null) {
      // Si viene una fecha pre-seleccionada
      final selectedDate = args['selectedDate'] as DateTime;
      setState(() {
        _fechaDia = selectedDate;
        final now = DateTime.now();
        if (selectedDate.year == now.year &&
            selectedDate.month == now.month &&
            selectedDate.day == now.day) {
          // Si es hoy, usar hora actual + 1
          final horaSiguiente = now.hour + 1;
          _horaInicio = TimeOfDay(hour: horaSiguiente > 23 ? 23 : horaSiguiente, minute: 0);
        } else {
          _horaInicio = const TimeOfDay(hour: 9, minute: 0);
        }
        _horaFin = TimeOfDay(
          hour: _horaInicio!.hour,
          minute: _horaInicio!.minute + 30 >= 60
              ? (_horaInicio!.minute + 30 - 60)
              : (_horaInicio!.minute + 30),
        );
      });
    }
  }

  @override
  void dispose() {
    _notaController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        CitasApi.fetchClientes(),
        CitasApi.fetchVehiculos(),
        CitasApi.fetchEmpleados(),
      ]);

      setState(() {
        _clientes = results[0];
        _vehiculos = results[1];
        _empleados = results[2].where((e) => e['estado'] == true).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadCita(int id) async {
    setState(() => _loading = true);
    try {
      final cita = await CitasApi.fetchCitaById(id);
      
      final fechaInicio = DateTime.parse(cita['fecha_hora_inicio']);
      final fechaFin = DateTime.parse(cita['fecha_hora_fin']);
      
      setState(() {
        _clienteId = cita['cliente']?.toString() ?? cita['cliente_info']?['id']?.toString();
        _vehiculoId = cita['vehiculo']?.toString() ?? cita['vehiculo_info']?['id']?.toString();
        _empleadoId = cita['empleado']?.toString() ?? cita['empleado_info']?['id']?.toString();
        _fechaDia = fechaInicio;
        _horaInicio = TimeOfDay(hour: fechaInicio.hour, minute: fechaInicio.minute);
        _horaFin = TimeOfDay(hour: fechaFin.hour, minute: fechaFin.minute);
        _tipoCita = cita['tipo_cita'] ?? 'reparacion';
        _estado = cita['estado'] ?? 'pendiente';
        _notaController.text = cita['nota'] ?? '';
        _descripcionController.text = cita['descripcion'] ?? '';
        _loading = false;
      });
      
      // Filtrar vehículos después de cargar
      if (_clienteId != null) {
        _filtrarVehiculos(_clienteId!);
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar la cita: $e';
        _loading = false;
      });
    }
  }

  void _filtrarVehiculos(String clienteId) {
    final clienteIdInt = int.tryParse(clienteId);
    if (clienteIdInt == null) {
      setState(() {
        _vehiculosFiltrados = [];
        _vehiculoId = null;
      });
      return;
    }

    setState(() {
      _vehiculosFiltrados = _vehiculos.where((v) {
        // Verificar si el vehículo pertenece al cliente
        if (v['cliente'] != null) {
          if (v['cliente'] is int) {
            return v['cliente'] == clienteIdInt;
          }
          if (v['cliente'] is Map) {
            return v['cliente']?['id'] == clienteIdInt;
          }
          if (v['cliente'] is String) {
            return int.tryParse(v['cliente']) == clienteIdInt;
          }
        }
        if (v['cliente_info'] != null && v['cliente_info']?['id'] == clienteIdInt) {
          return true;
        }
        return false;
      }).toList();
      
      // Si solo hay un vehículo, seleccionarlo automáticamente
      if (_vehiculosFiltrados.length == 1 && _vehiculoId == null) {
        _vehiculoId = _vehiculosFiltrados[0]['id'].toString();
      }
      
      // Si el vehículo actual no está en la lista filtrada, limpiarlo
      if (_vehiculoId != null) {
        final vehiculoActual = _vehiculosFiltrados.firstWhere(
          (v) => v['id'].toString() == _vehiculoId,
          orElse: () => {},
        );
        if (vehiculoActual.isEmpty) {
          _vehiculoId = null;
        }
      }
    });
  }

  Future<void> _selectFecha() async {
    final now = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaDia ?? now,
      firstDate: _isEditing ? DateTime(2020) : now,
      lastDate: DateTime(2030),
    );
    
    if (fecha != null) {
      setState(() {
        _fechaDia = fecha;
        // Si es hoy y no hay hora, ajustar hora
        if (fecha.year == now.year &&
            fecha.month == now.month &&
            fecha.day == now.day &&
            _horaInicio == null) {
          final horaSiguiente = now.hour + 1;
          _horaInicio = TimeOfDay(hour: horaSiguiente > 23 ? 23 : horaSiguiente, minute: 0);
          _horaFin = TimeOfDay(
            hour: _horaInicio!.hour,
            minute: _horaInicio!.minute + 30 >= 60
                ? (_horaInicio!.minute + 30 - 60)
                : (_horaInicio!.minute + 30),
          );
        } else if (_horaInicio == null) {
          _horaInicio = const TimeOfDay(hour: 9, minute: 0);
          _horaFin = const TimeOfDay(hour: 9, minute: 30);
        }
      });
    }
  }

  Future<void> _selectHoraInicio() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaInicio ?? const TimeOfDay(hour: 9, minute: 0),
    );
    
    if (hora != null) {
      setState(() {
        _horaInicio = hora;
        // Ajustar hora fin automáticamente (30 min después)
        final horaFinMinutes = hora.hour * 60 + hora.minute + 30;
        _horaFin = TimeOfDay(
          hour: (horaFinMinutes ~/ 60) % 24,
          minute: horaFinMinutes % 60,
        );
      });
    }
  }

  Future<void> _selectHoraFin() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaFin ?? const TimeOfDay(hour: 9, minute: 30),
    );
    
    if (hora != null) {
      // Validar que la hora fin sea posterior a la hora inicio
      if (_horaInicio != null) {
        final inicioMinutos = _horaInicio!.hour * 60 + _horaInicio!.minute;
        final finMinutos = hora.hour * 60 + hora.minute;
        
        if (finMinutos <= inicioMinutos) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('La hora de fin debe ser posterior a la hora de inicio'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        // Validar que no exceda 2 horas
        final duracionHoras = (finMinutos - inicioMinutos) / 60.0;
        if (duracionHoras > 2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('La duración máxima es de 2 horas'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
      
      setState(() {
        _horaFin = hora;
      });
    }
  }

  String _getDuracion() {
    if (_horaInicio == null || _horaFin == null) return '';
    final inicioMinutos = _horaInicio!.hour * 60 + _horaInicio!.minute;
    final finMinutos = _horaFin!.hour * 60 + _horaFin!.minute;
    final duracionMinutos = finMinutos - inicioMinutos;
    final duracionHoras = duracionMinutos / 60.0;
    return '${duracionMinutos} minutos (${duracionHoras.toStringAsFixed(1)} horas)';
  }

  Future<void> _saveCita() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fechaDia == null || _horaInicio == null || _horaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos de fecha y hora'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar que no sea fecha pasada (solo para nuevas citas)
    if (!_isEditing) {
      final fechaHoraCompleta = DateTime(
        _fechaDia!.year,
        _fechaDia!.month,
        _fechaDia!.day,
        _horaInicio!.hour,
        _horaInicio!.minute,
      );
      
      if (fechaHoraCompleta.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pueden agendar citas en el pasado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      // Construir fecha_hora_inicio y fecha_hora_fin
      final fechaHoraInicio = DateTime(
        _fechaDia!.year,
        _fechaDia!.month,
        _fechaDia!.day,
        _horaInicio!.hour,
        _horaInicio!.minute,
      );
      
      final fechaHoraFin = DateTime(
        _fechaDia!.year,
        _fechaDia!.month,
        _fechaDia!.day,
        _horaFin!.hour,
        _horaFin!.minute,
      );

      final data = {
        'cliente': int.parse(_clienteId!),
        if (_vehiculoId != null) 'vehiculo': int.parse(_vehiculoId!),
        if (_empleadoId != null && _empleadoId!.isNotEmpty) 'empleado': int.parse(_empleadoId!),
        'fecha_hora_inicio': fechaHoraInicio.toIso8601String(),
        'fecha_hora_fin': fechaHoraFin.toIso8601String(),
        'tipo_cita': _tipoCita,
        'estado': _estado,
        'descripcion': _descripcionController.text,
        'nota': _notaController.text,
      };

      if (_isEditing) {
        await CitasApi.updateCita(_citaId!, data);
      } else {
        await CitasApi.createCita(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Cita actualizada' : 'Cita creada'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Editar Cita' : 'Nueva Cita')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Editar Cita' : 'Nueva Cita')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!),
              ElevatedButton(
                onPressed: () {
                  if (_isEditing) {
                    _loadCita(_citaId!);
                  } else {
                    _loadInitialData();
                  }
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Cita' : 'Nueva Cita'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cliente
            DropdownButtonFormField<String>(
              value: _clienteId,
              decoration: const InputDecoration(
                labelText: 'Cliente *',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Seleccionar cliente')),
                ..._clientes.map((c) {
                  final nombre = '${c['nombre'] ?? ''} ${c['apellido'] ?? ''}'.trim();
                  final display = nombre.isNotEmpty ? '$nombre - ${c['nit'] ?? ''}' : (c['nit'] ?? '');
                  return DropdownMenuItem(
                    value: c['id'].toString(),
                    child: Text(display),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _clienteId = value;
                  _vehiculoId = null;
                });
                if (value != null) {
                  _filtrarVehiculos(value);
                } else {
                  setState(() {
                    _vehiculosFiltrados = [];
                  });
                }
              },
              validator: (value) => value == null ? 'Seleccione un cliente' : null,
            ),
            const SizedBox(height: 16),
            
            // Vehículo (solo si hay cliente seleccionado)
            if (_clienteId != null)
              DropdownButtonFormField<String>(
                value: _vehiculoId,
                decoration: const InputDecoration(
                  labelText: 'Vehículo (Opcional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Sin vehículo')),
                  ..._vehiculosFiltrados.map((v) {
                    final placa = v['numero_placa'] ?? 'Sin placa';
                    final marca = v['marca']?['nombre'] ?? v['marca_nombre'] ?? '';
                    final modelo = v['modelo']?['nombre'] ?? v['modelo_nombre'] ?? '';
                    final display = '$marca $modelo'.trim();
                    return DropdownMenuItem(
                      value: v['id'].toString(),
                      child: Text(display.isEmpty ? placa : '$display - $placa'),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _vehiculoId = value;
                  });
                },
              ),
            if (_clienteId != null) const SizedBox(height: 16),
            
            // Fecha y horas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fecha y Horario de la Cita *',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Fecha
                  InkWell(
                    onTap: _selectFecha,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Día de la cita',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _fechaDia != null
                            ? DateFormat('dd/MM/yyyy').format(_fechaDia!)
                            : 'Seleccionar fecha',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Horas
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectHoraInicio,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Hora inicio',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.access_time),
                            ),
                            child: Text(
                              _horaInicio != null
                                  ? _horaInicio!.format(context)
                                  : 'Seleccionar',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _selectHoraFin,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Hora fin',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.access_time),
                            ),
                            child: Text(
                              _horaFin != null
                                  ? _horaFin!.format(context)
                                  : 'Seleccionar',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Duración
                  if (_horaInicio != null && _horaFin != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Duración: ${_getDuracion()}',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Tipo de cita
            DropdownButtonFormField<String>(
              value: _tipoCita,
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
                setState(() {
                  _tipoCita = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Empleado
            DropdownButtonFormField<String>(
              value: _empleadoId,
              decoration: const InputDecoration(
                labelText: 'Empleado Asignado (Opcional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Seleccionar empleado (opcional)')),
                ..._empleados.map((e) {
                  final nombre = '${e['nombre'] ?? ''} ${e['apellido'] ?? ''}'.trim();
                  return DropdownMenuItem(
                    value: e['id'].toString(),
                    child: Text(nombre),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _empleadoId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Estado
            DropdownButtonFormField<String>(
              value: _estado,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                DropdownMenuItem(value: 'confirmada', child: Text('Confirmada')),
                DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
                DropdownMenuItem(value: 'completada', child: Text('Completada')),
              ],
              onChanged: (value) {
                setState(() {
                  _estado = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Descripción
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Nota
            TextFormField(
              controller: _notaController,
              decoration: const InputDecoration(
                labelText: 'Nota *',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La nota es requerida';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveCita,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow.shade400,
                      foregroundColor: Colors.black87,
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'Guardar Cambios' : 'Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

