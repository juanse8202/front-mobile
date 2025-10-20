import 'package:flutter/material.dart';
import '../api/presupuestos_api.dart';

class PresupuestosPage extends StatefulWidget {
  const PresupuestosPage({super.key});

  @override
  State<PresupuestosPage> createState() => _PresupuestosPageState();
}

class _PresupuestosPageState extends State<PresupuestosPage> {
  List<dynamic> allPresupuestos = [];
  List<dynamic> filteredPresupuestos = [];
  bool loading = true;
  String? error;

  final TextEditingController searchController = TextEditingController();
  bool showFilters = false;
  String selectedEstado = '';
  final TextEditingController clienteController = TextEditingController();
  final TextEditingController vehiculoController = TextEditingController();
  DateTime? fechaDesde;
  DateTime? fechaHasta;

  @override
  void initState() {
    super.initState();
    loadPresupuestos();
    searchController.addListener(applyFilters);
    clienteController.addListener(applyFilters);
    vehiculoController.addListener(applyFilters);
  }

  @override
  void dispose() {
    searchController.dispose();
    clienteController.dispose();
    vehiculoController.dispose();
    super.dispose();
  }

  Future<void> loadPresupuestos() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await PresupuestosApi.fetchAllPresupuestos();
      setState(() {
        allPresupuestos = data;
        filteredPresupuestos = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        loading = false;
      });
    }
  }

  void applyFilters() {
    setState(() {
      List<dynamic> filtered = List.from(allPresupuestos);

      final searchTerm = searchController.text.toLowerCase();
      if (searchTerm.isNotEmpty) {
        filtered = filtered.where((p) {
          final numero = (p['numero'] ?? '').toString().toLowerCase();
          final id = (p['id'] ?? '').toString();
          final cliente = (p['cliente_nombre'] ?? '').toString().toLowerCase();
          final placa = (p['vehiculo']?['placa'] ?? '')
              .toString()
              .toLowerCase();
          final marca = (p['vehiculo']?['marca'] ?? '')
              .toString()
              .toLowerCase();
          final modelo = (p['vehiculo']?['modelo'] ?? '')
              .toString()
              .toLowerCase();

          return numero.contains(searchTerm) ||
              id.contains(searchTerm) ||
              cliente.contains(searchTerm) ||
              placa.contains(searchTerm) ||
              marca.contains(searchTerm) ||
              modelo.contains(searchTerm);
        }).toList();
      }

      if (selectedEstado.isNotEmpty) {
        filtered = filtered.where((p) {
          final estado = (p['estado'] ?? '').toString().toLowerCase();
          return estado == selectedEstado.toLowerCase();
        }).toList();
      }

      final clienteTerm = clienteController.text.toLowerCase();
      if (clienteTerm.isNotEmpty) {
        filtered = filtered.where((p) {
          final cliente = (p['cliente_nombre'] ?? '').toString().toLowerCase();
          return cliente.contains(clienteTerm);
        }).toList();
      }

      final vehiculoTerm = vehiculoController.text.toLowerCase();
      if (vehiculoTerm.isNotEmpty) {
        filtered = filtered.where((p) {
          final placa = (p['vehiculo']?['placa'] ?? '')
              .toString()
              .toLowerCase();
          final marca = (p['vehiculo']?['marca'] ?? '')
              .toString()
              .toLowerCase();
          final modelo = (p['vehiculo']?['modelo'] ?? '')
              .toString()
              .toLowerCase();

          return placa.contains(vehiculoTerm) ||
              marca.contains(vehiculoTerm) ||
              modelo.contains(vehiculoTerm);
        }).toList();
      }

      if (fechaDesde != null) {
        filtered = filtered.where((p) {
          final fechaStr = p['fecha_inicio'] ?? p['fecha_creacion'];
          if (fechaStr == null) return false;
          try {
            final fecha = DateTime.parse(fechaStr.toString());
            return fecha.isAfter(fechaDesde!) ||
                fecha.isAtSameMomentAs(fechaDesde!);
          } catch (e) {
            return false;
          }
        }).toList();
      }

      if (fechaHasta != null) {
        filtered = filtered.where((p) {
          final fechaStr = p['fecha_inicio'] ?? p['fecha_creacion'];
          if (fechaStr == null) return false;
          try {
            final fecha = DateTime.parse(fechaStr.toString());
            return fecha.isBefore(fechaHasta!) ||
                fecha.isAtSameMomentAs(fechaHasta!);
          } catch (e) {
            return false;
          }
        }).toList();
      }

      filteredPresupuestos = filtered;
    });
  }

  void clearFilters() {
    setState(() {
      searchController.clear();
      selectedEstado = '';
      clienteController.clear();
      vehiculoController.clear();
      fechaDesde = null;
      fechaHasta = null;
      filteredPresupuestos = List.from(allPresupuestos);
    });
  }

  bool hasActiveFilters() {
    return searchController.text.isNotEmpty ||
        selectedEstado.isNotEmpty ||
        clienteController.text.isNotEmpty ||
        vehiculoController.text.isNotEmpty ||
        fechaDesde != null ||
        fechaHasta != null;
  }

  Future<void> handleDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Está seguro de que desea eliminar este presupuesto?',
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
        await PresupuestosApi.deletePresupuesto(id);
        loadPresupuestos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Presupuesto eliminado'),
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

  String fmtNum(dynamic v) {
    try {
      if (v == null) return '-';
      final numVal = (v is num) ? v.toDouble() : double.parse(v.toString());
      return numVal.toStringAsFixed(2);
    } catch (e) {
      return v.toString();
    }
  }

  Widget buildStatusBadge(String? estado) {
    final estadoLower = (estado ?? 'pendiente').toLowerCase();
    Color bgColor;
    Color textColor;
    String label;

    switch (estadoLower) {
      case 'aprobado':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = 'Aprobado';
        break;
      case 'rechazado':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = 'Rechazado';
        break;
      case 'cancelado':
        bgColor = Colors.grey.shade300;
        textColor = Colors.grey.shade800;
        label = 'Cancelado';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presupuestos'), elevation: 2),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/presupuesto-form',
          );
          if (result == true) {
            loadPresupuestos();
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
                          hintText: 'Buscar...',
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
                              value: 'aprobado',
                              child: Text('Aprobado'),
                            ),
                            DropdownMenuItem(
                              value: 'rechazado',
                              child: Text('Rechazado'),
                            ),
                            DropdownMenuItem(
                              value: 'cancelado',
                              child: Text('Cancelado'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedEstado = value ?? '';
                            });
                            applyFilters();
                          },
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: clienteController,
                          decoration: const InputDecoration(
                            labelText: 'Cliente',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: vehiculoController,
                          decoration: const InputDecoration(
                            labelText: 'Vehículo',
                            border: OutlineInputBorder(),
                          ),
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
                                    setState(() {
                                      fechaDesde = date;
                                    });
                                    applyFilters();
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
                                    setState(() {
                                      fechaHasta = date;
                                    });
                                    applyFilters();
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
          if (!loading && filteredPresupuestos.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade100,
              child: Text(
                'Mostrando ${filteredPresupuestos.length} de ${allPresupuestos.length}',
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
                          onPressed: loadPresupuestos,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : filteredPresupuestos.isEmpty
                ? const Center(child: Text('No se encontraron presupuestos'))
                : RefreshIndicator(
                    onRefresh: loadPresupuestos,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredPresupuestos.length,
                      itemBuilder: (context, i) {
                        final p =
                            filteredPresupuestos[i] as Map<String, dynamic>;
                        return Card(
                          color: Colors.deepPurple.shade600,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: InkWell(
                            onTap: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                '/presupuesto-detalle',
                                arguments: {'id': p['id']},
                              );
                              if (result == true) {
                                loadPresupuestos();
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
                                                  '#${p['id']}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                buildStatusBadge(p['estado']),
                                              ],
                                            ),
                                            Text(
                                              p['diagnostico'] ??
                                                  'Sin diagnóstico',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.orangeAccent.shade700,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Bs. ${fmtNum(p['total'])}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.white70,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                handleDelete(p['id']),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        color: Colors.white70,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          p['cliente_nombre'] ?? 'Sin cliente',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.directions_car,
                                        color: Colors.white70,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${p['vehiculo']?['placa'] ?? 'N/A'} - ${p['vehiculo']?['marca'] ?? ''} ${p['vehiculo']?['modelo'] ?? ''}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
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
    );
  }
}
