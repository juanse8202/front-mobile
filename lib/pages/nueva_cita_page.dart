import 'package:flutter/material.dart';
import '../services/cita_cliente_service.dart';

class NuevaCitaPage extends StatefulWidget {
  final String? token;
  final String mode; // 'create' or 'edit'
  final Map<String, dynamic>? initialCita;

  const NuevaCitaPage({
    super.key,
    this.token,
    this.mode = 'create',
    this.initialCita,
  });

  @override
  State<NuevaCitaPage> createState() => _NuevaCitaPageState();
}

class _NuevaCitaPageState extends State<NuevaCitaPage> {
  final _formKey = GlobalKey<FormState>();
  final CitaClienteService _citaService = CitaClienteService();

  // Form fields
  int? empleadoId;
  int? vehiculoId;
  DateTime? fechaDia;
  TimeOfDay? horaInicio;
  TimeOfDay? horaFin;
  String tipoCita = 'reparacion';
  final TextEditingController notaCtrl = TextEditingController();

  // Data
  List<dynamic> empleados = [];
  List<dynamic> vehiculos = [];
  List<dynamic> horariosOcupados = [];
  bool loading = false;
  bool loadingCalendario = false;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    setState(() => loading = true);
    try {
      final [empleadosData, vehiculosData] = await Future.wait([
        _citaService.fetchEmpleados(token: widget.token),
        _citaService.fetchVehiculosCliente(token: widget.token),
      ]);

      setState(() {
        empleados = empleadosData;
        vehiculos = vehiculosData;
      });

      // Pre-fill si está en modo edición
      if (widget.mode == 'edit' && widget.initialCita != null) {
        final cita = widget.initialCita!;
        final inicioStr = cita['fecha_hora_inicio'] as String?;
        final finStr = cita['fecha_hora_fin'] as String?;

        if (inicioStr != null) {
          final inicio = DateTime.parse(inicioStr);
          setState(() {
            fechaDia = DateTime(inicio.year, inicio.month, inicio.day);
            horaInicio = TimeOfDay(hour: inicio.hour, minute: inicio.minute);
          });
        }

        if (finStr != null) {
          final fin = DateTime.parse(finStr);
          setState(() {
            horaFin = TimeOfDay(hour: fin.hour, minute: fin.minute);
          });
        }

        final empId = cita['empleado'] is Map
            ? cita['empleado']['id'] as int?
            : cita['empleado'] as int?;
        final vehId = cita['vehiculo'] is Map
            ? cita['vehiculo']['id'] as int?
            : cita['vehiculo'] as int?;

        setState(() {
          empleadoId = empId;
          vehiculoId = vehId;
          tipoCita = cita['tipo_cita'] as String? ?? 'reparacion';
          notaCtrl.text = cita['nota'] as String? ?? cita['descripcion'] as String? ?? '';
        });
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _loadCalendario() async {
    if (empleadoId == null || fechaDia == null) {
      setState(() => horariosOcupados = []);
      return;
    }

    setState(() => loadingCalendario = true);
    try {
      final diaStr = '${fechaDia!.year}-${fechaDia!.month.toString().padLeft(2, '0')}-${fechaDia!.day.toString().padLeft(2, '0')}';
      final calendario = await _citaService.fetchCalendarioEmpleado(
        empleadoId!,
        token: widget.token,
        dia: diaStr,
      );

      final horarios = calendario['horarios_ocupados'] as List? ?? [];
      
      // Filtrar por solapamiento con el día seleccionado
      final dayStart = DateTime(fechaDia!.year, fechaDia!.month, fechaDia!.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final horariosDelDia = horarios.where((horario) {
        try {
          final inicio = DateTime.parse(horario['fecha_hora_inicio'] as String);
          final fin = DateTime.parse(horario['fecha_hora_fin'] as String);
          return inicio.isBefore(dayEnd) && fin.isAfter(dayStart);
        } catch (_) {
          return false;
        }
      }).toList();

      setState(() => horariosOcupados = horariosDelDia);
    } catch (_) {
      setState(() => horariosOcupados = []);
    } finally {
      setState(() => loadingCalendario = false);
    }
  }

  bool _isHorarioOcupado(TimeOfDay hora) {
    if (horariosOcupados.isEmpty || fechaDia == null) return false;

    final fechaHora = DateTime(
      fechaDia!.year,
      fechaDia!.month,
      fechaDia!.day,
      hora.hour,
      hora.minute,
    );

    return horariosOcupados.any((horario) {
      try {
        final inicio = DateTime.parse(horario['fecha_hora_inicio'] as String);
        final fin = DateTime.parse(horario['fecha_hora_fin'] as String);
        return fechaHora.isAfter(inicio.subtract(const Duration(minutes: 1))) &&
            fechaHora.isBefore(fin);
      } catch (_) {
        return false;
      }
    });
  }

  void _onHoraInicioChanged(TimeOfDay? nuevaHora) {
    if (nuevaHora == null) return;
    
    setState(() {
      horaInicio = nuevaHora;
      // Auto-ajustar hora fin a +30 minutos
      final nuevaHoraFin = TimeOfDay(
        hour: (nuevaHora.hour + (nuevaHora.minute + 30) ~/ 60) % 24,
        minute: (nuevaHora.minute + 30) % 60,
      );
      horaFin = nuevaHoraFin;
    });
  }

  void _onHoraFinChanged(TimeOfDay? nuevaHora) {
    if (nuevaHora == null || horaInicio == null) return;
    
    final inicio = horaInicio!.hour * 60 + horaInicio!.minute;
    final fin = nuevaHora.hour * 60 + nuevaHora.minute;
    final diferencia = fin - inicio;

    if (diferencia <= 0) {
      // Si es menor o igual, ajustar a +30 minutos
      final nuevaHoraFin = TimeOfDay(
        hour: (horaInicio!.hour + (horaInicio!.minute + 30) ~/ 60) % 24,
        minute: (horaInicio!.minute + 30) % 60,
      );
      setState(() => horaFin = nuevaHoraFin);
    } else if (diferencia > 120) {
      // Máximo 2 horas
      final nuevaHoraFin = TimeOfDay(
        hour: (horaInicio!.hour + 2) % 24,
        minute: horaInicio!.minute,
      );
      setState(() => horaFin = nuevaHoraFin);
    } else {
      setState(() => horaFin = nuevaHora);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (empleadoId == null || vehiculoId == null || fechaDia == null || horaInicio == null || horaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos requeridos')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final fechaHoraInicio = DateTime(
        fechaDia!.year,
        fechaDia!.month,
        fechaDia!.day,
        horaInicio!.hour,
        horaInicio!.minute,
      );
      final fechaHoraFin = DateTime(
        fechaDia!.year,
        fechaDia!.month,
        fechaDia!.day,
        horaFin!.hour,
        horaFin!.minute,
      );

      if (widget.mode == 'edit' && widget.initialCita != null) {
        // Reprogramar
        await _citaService.reprogramar(
          id: widget.initialCita!['id'] as int,
          token: widget.token,
          fechaHoraInicio: fechaHoraInicio.toIso8601String(),
          fechaHoraFin: fechaHoraFin.toIso8601String(),
          descripcion: notaCtrl.text.trim().isEmpty ? null : notaCtrl.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita reprogramada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Crear
        await _citaService.create(
          token: widget.token,
          empleado: empleadoId!,
          vehiculo: vehiculoId!,
          fechaHoraInicio: fechaHoraInicio.toIso8601String(),
          fechaHoraFin: fechaHoraFin.toIso8601String(),
          tipoCita: tipoCita,
          descripcion: notaCtrl.text.trim().isEmpty ? null : notaCtrl.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita creada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() => loading = false);
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

  Future<void> _handleCancelarCita() async {
    if (widget.mode != 'edit' || widget.initialCita == null) return;

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
        await _citaService.cancelar(widget.initialCita!['id'] as int, token: widget.token);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita cancelada'),
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.mode == 'edit';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Reprogramar Cita' : 'Nueva Cita'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $error'),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Volver'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Empleado (solo creación)
                        if (!isEdit) ...[
                          DropdownButtonFormField<int>(
                            value: empleadoId,
                            decoration: const InputDecoration(
                              labelText: 'Empleado *',
                              border: OutlineInputBorder(),
                            ),
                            items: empleados.map((emp) {
                              final nombre = '${emp['nombre'] ?? ''} ${emp['apellido'] ?? ''}'.trim();
                              return DropdownMenuItem<int>(
                                value: emp['id'] as int?,
                                child: Text(nombre.isEmpty ? 'ID: ${emp['id']}' : nombre),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => empleadoId = value);
                              if (fechaDia != null) _loadCalendario();
                            },
                            validator: (value) => value == null ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Vehículo (solo creación)
                        if (!isEdit) ...[
                          DropdownButtonFormField<int>(
                            value: vehiculoId,
                            decoration: const InputDecoration(
                              labelText: 'Vehículo *',
                              border: OutlineInputBorder(),
                            ),
                            items: vehiculos.map((veh) {
                              final placa = veh['numero_placa'] ?? 'N/A';
                              return DropdownMenuItem<int>(
                                value: veh['id'] as int?,
                                child: Text(placa),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => vehiculoId = value),
                            validator: (value) => value == null ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Tipo de cita (solo creación)
                        if (!isEdit) ...[
                          DropdownButtonFormField<String>(
                            value: tipoCita,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Cita *',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'reparacion', child: Text('Reparación')),
                              DropdownMenuItem(value: 'mantenimiento', child: Text('Mantenimiento')),
                              DropdownMenuItem(value: 'diagnostico', child: Text('Diagnóstico')),
                            ],
                            onChanged: (value) => setState(() => tipoCita = value ?? 'reparacion'),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Fecha
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: fechaDia ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() {
                                fechaDia = date;
                                // Si no hay hora, establecer default
                                if (horaInicio == null) {
                                  final now = DateTime.now();
                                  if (date.year == now.year &&
                                      date.month == now.month &&
                                      date.day == now.day) {
                                    // Hoy: próxima hora
                                    horaInicio = TimeOfDay(
                                      hour: (now.hour + 1) % 24,
                                      minute: 0,
                                    );
                                  } else {
                                    // Futuro: 9:00
                                    horaInicio = const TimeOfDay(hour: 9, minute: 0);
                                  }
                                  horaFin = TimeOfDay(
                                    hour: (horaInicio!.hour + (horaInicio!.minute + 30) ~/ 60) % 24,
                                    minute: (horaInicio!.minute + 30) % 60,
                                  );
                                }
                              });
                              if (empleadoId != null) _loadCalendario();
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fecha *',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              fechaDia != null
                                  ? '${fechaDia!.day.toString().padLeft(2, '0')}/${fechaDia!.month.toString().padLeft(2, '0')}/${fechaDia!.year}'
                                  : 'Seleccionar fecha',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Hora inicio
                        InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: horaInicio ?? const TimeOfDay(hour: 9, minute: 0),
                            );
                            if (time != null) {
                              _onHoraInicioChanged(time);
                              if (fechaDia != null && empleadoId != null) _loadCalendario();
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Hora Inicio *',
                              border: const OutlineInputBorder(),
                              suffixIcon: _isHorarioOcupado(horaInicio ?? const TimeOfDay(hour: 0, minute: 0))
                                  ? const Icon(Icons.warning, color: Colors.orange)
                                  : null,
                            ),
                            child: Text(
                              horaInicio != null
                                  ? horaInicio!.format(context)
                                  : 'Seleccionar hora',
                            ),
                          ),
                        ),
                        if (_isHorarioOcupado(horaInicio ?? const TimeOfDay(hour: 0, minute: 0)))
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 12),
                            child: Text(
                              '⚠ Este horario está ocupado',
                              style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Hora fin
                        InkWell(
                          onTap: () async {
                            if (horaInicio == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Primero selecciona la hora de inicio')),
                              );
                              return;
                            }
                            final time = await showTimePicker(
                              context: context,
                              initialTime: horaFin ??
                                  TimeOfDay(
                                    hour: (horaInicio!.hour + (horaInicio!.minute + 30) ~/ 60) % 24,
                                    minute: (horaInicio!.minute + 30) % 60,
                                  ),
                            );
                            if (time != null) {
                              _onHoraFinChanged(time);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Hora Fin *',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              horaFin != null
                                  ? horaFin!.format(context)
                                  : 'Seleccionar hora',
                            ),
                          ),
                        ),
                        if (loadingCalendario)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: LinearProgressIndicator(),
                          ),
                        const SizedBox(height: 16),

                        // Horarios ocupados
                        if (horariosOcupados.isNotEmpty && fechaDia != null && empleadoId != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Horarios ocupados:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: horariosOcupados.map((horario) {
                                    try {
                                      final inicio = DateTime.parse(horario['fecha_hora_inicio'] as String);
                                      final fin = DateTime.parse(horario['fecha_hora_fin'] as String);
                                      return Chip(
                                        label: Text(
                                          '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')} - ${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        backgroundColor: Colors.orange.shade100,
                                      );
                                    } catch (_) {
                                      return const SizedBox.shrink();
                                    }
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Nota (solo creación)
                        if (!isEdit) ...[
                          TextField(
                            controller: notaCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nota',
                              border: OutlineInputBorder(),
                              hintText: 'Descripción adicional (opcional)',
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Botones
                        Row(
                          children: [
                            if (isEdit) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: loading ? null : _handleCancelarCita,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                  child: const Text('Cancelar Cita'),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: FilledButton(
                                onPressed: loading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(isEdit ? 'Reprogramar' : 'Crear Cita'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  @override
  void dispose() {
    notaCtrl.dispose();
    super.dispose();
  }
}

