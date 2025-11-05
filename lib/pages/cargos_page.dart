import 'package:flutter/material.dart';
import '../services/cargo_service.dart';

class CargosPage extends StatefulWidget {
  const CargosPage({super.key});

  @override
  State<CargosPage> createState() => _CargosPageState();
}

class _CargosPageState extends State<CargosPage> {
  final CargoService _cargoService = CargoService();
  List<dynamic> cargos = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCargos();
  }

  Future<void> _loadCargos() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await _cargoService.getCargos();

    if (response['success']) {
      setState(() {
        cargos = response['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = response['message'];
        isLoading = false;
      });
    }
  }

  // 🔹 Mostrar diálogo para crear/editar cargo
  Future<void> _showCargoDialog({Map<String, dynamic>? cargo}) async {
    final nombreController = TextEditingController(
      text: cargo?['nombre_cargo'] ?? cargo?['nombre'] ?? '',
    );
    final descripcionController = TextEditingController(
      text: cargo?['descripcion'] ?? '',
    );
    final sueldoController = TextEditingController(
      text: cargo?['sueldo']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(cargo == null ? 'Crear Cargo' : 'Editar Cargo'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Cargo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El nombre es requerido';
                      }
                      if (value.length < 3) {
                        return 'Mínimo 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La descripción es requerida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
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
                    'descripcion': descripcionController.text,
                    'sueldo': sueldoController.text,
                  };

                  final response = cargo == null
                      ? await _cargoService.createCargo(data)
                      : await _cargoService.updateCargo(cargo['id'], data);

                  if (!mounted) return;
                  Navigator.pop(context);

                  if (response['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(cargo == null
                            ? 'Cargo creado exitosamente'
                            : 'Cargo actualizado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadCargos();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response['message'] ?? 'Error al guardar cargo'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(cargo == null ? 'Crear' : 'Guardar'),
            ),
          ],
        );
      },
    );
  }

  // 🔹 Confirmar eliminación de cargo
  Future<void> _confirmDelete(Map<String, dynamic> cargo) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Está seguro de eliminar el cargo "${cargo['nombre_cargo'] ?? cargo['nombre']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                final response = await _cargoService.deleteCargo(cargo['id']);

                if (!mounted) return;

                if (response['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cargo eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadCargos();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response['message'] ?? 'Error al eliminar cargo'),
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
        title: const Text('Cargos'),
        backgroundColor: Colors.orange,
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
                        onPressed: _loadCargos,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : cargos.isEmpty
                  ? const Center(child: Text('No hay cargos disponibles'))
                  : RefreshIndicator(
                      onRefresh: _loadCargos,
                      child: ListView.builder(
                        itemCount: cargos.length,
                        itemBuilder: (context, index) {
                          final cargo = cargos[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Icon(
                                  Icons.work,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                cargo['nombre_cargo'] ?? cargo['nombre'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (cargo['descripcion'] != null)
                                    Text(cargo['descripcion']),
                                  if (cargo['sueldo'] != null)
                                    Text(
                                      'Sueldo: Bs ${cargo['sueldo']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
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
                                    onPressed: () => _showCargoDialog(cargo: cargo),
                                  ),
                                  // Botón eliminar
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmDelete(cargo),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCargoDialog(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}
