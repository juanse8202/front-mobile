import 'package:flutter/material.dart';
import '../api/citas_api.dart';

class CitasPage extends StatefulWidget {
  const CitasPage({super.key});

  @override
  State<CitasPage> createState() => _CitasPageState();
}

class _CitasPageState extends State<CitasPage> {
  List<dynamic> allCitas = [];
  List<dynamic> filteredCitas = [];
  bool loading = true;
  String? error;

  // Controllers para filtros
  final TextEditingController searchController = TextEditingController();
  bool showFilters = false;
  String selectedEstado = '';
  String selectedTipoCita = '';
  String? selectedClienteId;
  String? selectedVehiculoId;
  String? selectedEmpleadoId;
  DateTime? fechaDesde;
  DateTime? fechaHasta;

  // Datos para dropdowns
  List<dynamic> clientes = [];
  List<dynamic> vehiculos = [];
  List<dynamic> empleados = [];

  @override
  void initState() {
    super.initState();
    _loadAuxiliaryData();
    loadCitas();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> _loadAuxiliaryData() async {
    try {
      final [clientesData, vehiculosData, empleadosData] = await Future.wait([
        CitasApi.fetchClientes(),
        CitasApi.fetchVehiculos(),
        CitasApi.fetchEmpleados(),
      ]);

      setState(() {
        clientes = clientesData;
        vehiculos = vehiculosData;
        empleados = empleadosData;
      });
    } catch (e) {
      print('Error cargando datos auxiliares: $e');
    }
  }

  Future<void> loadCitas() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // Construir parámetros de filtros
      String? fechaDesdeStr;
      String? fechaHastaStr;
      
      if (fechaDesde != null) {
        fechaDesdeStr = '${fechaDesde!.year}-${fechaDesde!.month.toString().padLeft(2, '0')}-${fechaDesde!.day.toString().padLeft(2, '0')}';
      }
      if (fechaHasta != null) {
        fechaHastaStr = '${fechaHasta!.year}-${fechaHasta!.month.toString().padLeft(2, '0')}-${fechaHasta!.day.toString().padLeft(2, '0')}';
      }

      final data = await CitasApi.fetchAllCitas(
        estado: selectedEstado.isEmpty ? null : selectedEstado,
        tipoCita: selectedTipoCita.isEmpty ? null : selectedTipoCita,
        fechaDesde: fechaDesdeStr,
        fechaHasta: fechaHastaStr,
        clienteId: selectedClienteId,
        vehiculoId: selectedVehiculoId,
        empleadoId: selectedEmpleadoId,
        search: searchController.text.isEmpty ? null : searchController.text,
      );

      setState(() {
        allCitas = data;
        filteredCitas = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        loading = false;
      });
    }
  }

  void _applyFilters() {
    // Recargar citas con los filtros aplicados
    loadCitas();
  }

  void clearFilters() {
    setState(() {
      searchController.clear();
      selectedEstado = '';
      selectedTipoCita = '';
      selectedClienteId = null;
      selectedVehiculoId = null;
      selectedEmpleadoId = null;
      fechaDesde = null;
      fechaHasta = null;
    });
    loadCitas();
  }

  bool hasActiveFilters() {
    return searchController.text.isNotEmpty ||
        selectedEstado.isNotEmpty ||
        selectedTipoCita.isNotEmpty ||
        selectedClienteId != null ||
        selectedVehiculoId != null ||
        selectedEmpleadoId != null ||
        fechaDesde != null ||
        fechaHasta != null;
  }

  Future<void> handleDelete(int id) async {
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
        await CitasApi.deleteCita(id);
        loadCitas();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita eliminada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget buildEstadoBadge(String? estado) {
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

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateTimeStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Citas'), elevation: 2),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/cita-form',
          );
          if (result == true) {
            loadCitas();
          }
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por cliente, placa, descripción...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: showFilters
                            ? Colors.deepPurple.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: showFilters
                              ? Colors.deepPurple
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.filter_list,
                          color: showFilters
                              ? Colors.deepPurple
                              : Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            showFilters = !showFilters;
                          });
                        },
                      ),
                    ),
                    if (hasActiveFilters())
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: clearFilters,
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
                        // Estado
                        DropdownButtonFormField<String>(
                          value: selectedEstado.isEmpty ? null : selectedEstado,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: '', child: Text('Todos')),
                            DropdownMenuItem(
                              value: 'pendiente',
                              child: Text('Pendiente'),
                            ),
                            DropdownMenuItem(
                              value: 'confirmada',
                              child: Text('Confirmada'),
                            ),
                            DropdownMenuItem(
                              value: 'cancelada',
                              child: Text('Cancelada'),
                            ),
                            DropdownMenuItem(
                              value: 'completada',
                              child: Text('Completada'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedEstado = value ?? '';
                            });
                            _applyFilters();
                          },
                        ),
                        const SizedBox(height: 8),
                        // Tipo de Cita
                        DropdownButtonFormField<String>(
                          value: selectedTipoCita.isEmpty ? null : selectedTipoCita,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de Cita',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: '', child: Text('Todos')),
                            DropdownMenuItem(
                              value: 'reparacion',
                              child: Text('Reparación'),
                            ),
                            DropdownMenuItem(
                              value: 'mantenimiento',
                              child: Text('Mantenimiento'),
                            ),
                            DropdownMenuItem(
                              value: 'diagnostico',
                              child: Text('Diagnóstico'),
                            ),
                            DropdownMenuItem(
                              value: 'entrega',
                              child: Text('Entrega'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedTipoCita = value ?? '';
                            });
                            _applyFilters();
                          },
                        ),
                        const SizedBox(height: 8),
                        // Cliente
                        DropdownButtonFormField<String>(
                          value: selectedClienteId,
                          decoration: const InputDecoration(
                            labelText: 'Cliente',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todos los clientes'),
                            ),
                            ...clientes.map((c) {
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
                              selectedClienteId = value;
                            });
                            _applyFilters();
                          },
                        ),
                        const SizedBox(height: 8),
                        // Empleado
                        DropdownButtonFormField<String>(
                          value: selectedEmpleadoId,
                          decoration: const InputDecoration(
                            labelText: 'Empleado',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todos los empleados'),
                            ),
                            ...empleados.where((e) => e['estado'] == true).map((e) {
                              final nombre = '${e['nombre'] ?? ''} ${e['apellido'] ?? ''}'.trim();
                              return DropdownMenuItem(
                                value: e['id'].toString(),
                                child: Text(nombre),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedEmpleadoId = value;
                            });
                            _applyFilters();
                          },
                        ),
                        const SizedBox(height: 8),
                        // Vehículo
                        DropdownButtonFormField<String>(
                          value: selectedVehiculoId,
                          decoration: const InputDecoration(
                            labelText: 'Vehículo',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todos los vehículos'),
                            ),
                            ...vehiculos.map((v) {
                              final placa = v['numero_placa'] ?? 'N/A';
                              final marca = v['marca']?['nombre'] ?? '';
                              final modelo = v['modelo']?['nombre'] ?? '';
                              final display = '$placa - $marca $modelo'.trim();
                              return DropdownMenuItem(
                                value: v['id'].toString(),
                                child: Text(display),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedVehiculoId = value;
                            });
                            _applyFilters();
                          },
                        ),
                        const SizedBox(height: 8),
                        // Fechas
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
                                    setState(() {
                                      fechaDesde = date;
                                    });
                                    _applyFilters();
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Fecha Desde',
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
                                    setState(() {
                                      fechaHasta = date;
                                    });
                                    _applyFilters();
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Fecha Hasta',
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
          if (!loading && hasActiveFilters())
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade100,
              child: Text(
                'Mostrando ${filteredCitas.length} citas con filtros aplicados',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 64, color: Colors.red),
                            Text(error!),
                            ElevatedButton(
                              onPressed: loadCitas,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : filteredCitas.isEmpty
                        ? const Center(child: Text('No se encontraron citas'))
                        : RefreshIndicator(
                            onRefresh: loadCitas,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: filteredCitas.length,
                              itemBuilder: (context, i) {
                                final cita =
                                    filteredCitas[i] as Map<String, dynamic>;
                                final clienteInfo = cita['cliente_info'] ?? {};
                                final vehiculoInfo = cita['vehiculo_info'] ?? {};
                                final empleadoInfo = cita['empleado_info'] ?? {};
                                
                                return Card(
                                  color: Colors.yellow.shade400,
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: InkWell(
                                    onTap: () async {
                                      final result = await Navigator.pushNamed(
                                        context,
                                        '/cita-detalle',
                                        arguments: {'id': cita['id']},
                                      );
                                      if (result == true) {
                                        loadCitas();
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          'Cita #${cita['id']}',
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.black87,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        buildEstadoBadge(cita['estado']),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _getTipoCitaLabel(cita['tipo_cita']),
                                                      style: const TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.black54,
                                                  size: 20,
                                                ),
                                                onPressed: () =>
                                                    handleDelete(cita['id']),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                color: Colors.black87,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  _formatDateTime(cita['fecha_hora_inicio']),
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (clienteInfo.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.person,
                                                  color: Colors.black87,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    '${clienteInfo['nombre'] ?? ''} ${clienteInfo['apellido'] ?? ''}'.trim(),
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (vehiculoInfo.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.directions_car,
                                                  color: Colors.black87,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    vehiculoInfo['numero_placa'] ?? 'N/A',
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (empleadoInfo.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.work,
                                                  color: Colors.blue,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    '${empleadoInfo['nombre'] ?? ''} ${empleadoInfo['apellido'] ?? ''}'.trim(),
                                                    style: const TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
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
    );
  }
}

