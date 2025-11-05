import 'package:flutter/material.dart';
import '../services/empleado_service.dart';
import '../services/cargo_service.dart';
import '../services/area_service.dart';

class EmpleadosPage extends StatefulWidget {
  const EmpleadosPage({super.key});

  @override
  State<EmpleadosPage> createState() => _EmpleadosPageState();
}

class _EmpleadosPageState extends State<EmpleadosPage> {
  final EmpleadoService _empleadoService = EmpleadoService();
  final CargoService _cargoService = CargoService();
  final AreaService _areaService = AreaService();
  List<dynamic> empleados = [];
  List<dynamic> cargos = [];
  List<dynamic> areas = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadEmpleados();
    await _loadCargos();
    await _loadAreas();
  }

  Future<void> _loadEmpleados() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await _empleadoService.getEmpleados();

    if (response['success']) {
      setState(() {
        empleados = response['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = response['message'];
        isLoading = false;
      });
    }
  }

  Future<void> _loadCargos() async {
    final response = await _cargoService.getCargos();
    if (response['success']) {
      setState(() {
        cargos = response['data'];
      });
    }
  }

  Future<void> _loadAreas() async {
    final response = await _areaService.getAreas();
    if (response['success']) {
      setState(() {
        areas = response['data'];
      });
    }
  }

  // 🔹 Mostrar diálogo para crear/editar empleado
  Future<void> _showEmpleadoDialog({Map<String, dynamic>? empleado}) async {
    final nombreController = TextEditingController(text: empleado?['nombre'] ?? '');
    final apellidoController = TextEditingController(text: empleado?['apellido'] ?? '');
    final ciController = TextEditingController(text: empleado?['ci'] ?? '');
    final telefonoController = TextEditingController(text: empleado?['telefono'] ?? '');
    final direccionController = TextEditingController(text: empleado?['direccion'] ?? '');
    final sueldoController = TextEditingController(
      text: empleado?['sueldo']?.toString() ?? '',
    );
    
    int? selectedCargoId = empleado?['cargo'];
    int? selectedAreaId = empleado?['area'];
    String? selectedSexo = empleado?['sexo'];
    
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(empleado == null ? 'Crear Empleado' : 'Editar Empleado'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El nombre es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: apellidoController,
                        decoration: const InputDecoration(
                          labelText: 'Apellido',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El apellido es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: ciController,
                        decoration: const InputDecoration(
                          labelText: 'CI',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        enabled: empleado == null, // No editable si ya existe
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El CI es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedCargoId,
                        decoration: const InputDecoration(
                          labelText: 'Cargo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.work),
                        ),
                        items: cargos.map<DropdownMenuItem<int>>((cargo) {
                          return DropdownMenuItem<int>(
                            value: cargo['id'],
                            child: Text(cargo['nombre']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedCargoId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Debe seleccionar un cargo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: sueldoController,
                        decoration: const InputDecoration(
                          labelText: 'Sueldo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El sueldo es requerido';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Sueldo inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: direccionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedSexo,
                        decoration: const InputDecoration(
                          labelText: 'Sexo (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.wc),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'M', child: Text('Masculino')),
                          DropdownMenuItem(value: 'F', child: Text('Femenino')),
                          DropdownMenuItem(value: 'O', child: Text('Otro')),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedSexo = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedAreaId,
                        decoration: const InputDecoration(
                          labelText: 'Área (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        items: areas.map<DropdownMenuItem<int>>((area) {
                          return DropdownMenuItem<int>(
                            value: area['id'],
                            child: Text(area['nombre']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedAreaId = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final data = {
                        'nombre': nombreController.text,
                        'apellido': apellidoController.text,
                        'ci': ciController.text,
                        'cargo': selectedCargoId,
                        'sueldo': sueldoController.text,
                        'telefono': telefonoController.text,
                        'direccion': direccionController.text,
                        'estado': true,
                      };

                      if (selectedSexo != null) {
                        data['sexo'] = selectedSexo;
                      }
                      
                      if (selectedAreaId != null) {
                        data['area'] = selectedAreaId;
                      }

                      final response = empleado == null
                          ? await _empleadoService.createEmpleado(data)
                          : await _empleadoService.updateEmpleado(empleado['id'], data);

                      if (!mounted) return;
                      Navigator.pop(context);

                      if (response['success']) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(empleado == null
                                ? 'Empleado creado exitosamente'
                                : 'Empleado actualizado exitosamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadEmpleados();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(response['message'] ?? 'Error al guardar empleado'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(empleado == null ? 'Crear' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🔹 Confirmar eliminación de empleado
  Future<void> _confirmDelete(Map<String, dynamic> empleado) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Está seguro de eliminar el empleado "${empleado['nombre']} ${empleado['apellido']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                final response = await _empleadoService.deleteEmpleado(empleado['id']);

                if (!mounted) return;

                if (response['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Empleado eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadEmpleados();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response['message'] ?? 'Error al eliminar empleado'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empleados'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadEmpleados,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : empleados.isEmpty
                  ? const Center(child: Text('No hay empleados disponibles'))
                  : RefreshIndicator(
                      onRefresh: _loadEmpleados,
                      child: ListView.builder(
                        itemCount: empleados.length,
                        itemBuilder: (context, index) {
                          final empleado = empleados[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal,
                                child: Icon(
                                  Icons.badge,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                '${empleado['nombre'] ?? ''} ${empleado['apellido'] ?? ''}'.trim(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('CI: ${empleado['ci'] ?? 'N/A'}'),
                                  if (empleado['cargo_nombre'] != null)
                                    Text(
                                      'Cargo: ${empleado['cargo_nombre']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.teal,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Botón editar
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEmpleadoDialog(empleado: empleado),
                                  ),
                                  // Botón eliminar
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmDelete(empleado),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEmpleadoDialog(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
