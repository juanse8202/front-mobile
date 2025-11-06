import 'package:flutter/material.dart';
import '../services/rol_service.dart';

class RolesPage extends StatefulWidget {
  const RolesPage({super.key});

  @override
  State<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends State<RolesPage> {
  final RolService _rolService = RolService();
  List<dynamic> roles = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await _rolService.getRoles();

    if (response['success']) {
      setState(() {
        roles = response['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = response['message'];
        isLoading = false;
      });
    }
  }

  // 🔹 Mostrar diálogo para crear/editar rol
  Future<void> _showRolDialog({Map<String, dynamic>? rol}) async {
    final nameController = TextEditingController(text: rol?['name'] ?? '');
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(rol == null ? 'Crear Rol' : 'Editar Rol'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Rol',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es requerido';
                }
                if (value.length < 3) {
                  return 'El nombre debe tener al menos 3 caracteres';
                }
                return null;
              },
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
                  final data = {'name': nameController.text};
                  
                  final response = rol == null
                      ? await _rolService.createRol(data)
                      : await _rolService.updateRol(rol['id'], data);

                  if (!mounted) return;
                  Navigator.pop(context);

                  if (response['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(rol == null
                            ? 'Rol creado exitosamente'
                            : 'Rol actualizado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadRoles();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response['message'] ?? 'Error al guardar rol'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(rol == null ? 'Crear' : 'Guardar'),
            ),
          ],
        );
      },
    );
  }

  // 🔹 Confirmar eliminación de rol
  Future<void> _confirmDelete(Map<String, dynamic> rol) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Está seguro de eliminar el rol "${rol['name']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                final response = await _rolService.deleteRol(rol['id']);

                if (!mounted) return;

                if (response['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rol eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadRoles();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response['message'] ?? 'Error al eliminar rol'),
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
        title: const Text('Roles'),
        backgroundColor: Colors.deepPurple,
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
                        onPressed: _loadRoles,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : roles.isEmpty
                  ? const Center(child: Text('No hay roles disponibles'))
                  : RefreshIndicator(
                      onRefresh: _loadRoles,
                      child: ListView.builder(
                        itemCount: roles.length,
                        itemBuilder: (context, index) {
                          final rol = roles[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple,
                                child: const Icon(
                                  Icons.security,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                rol['name'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'ID: ${rol['id']}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Botón editar
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showRolDialog(rol: rol),
                                  ),
                                  // Botón eliminar
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmDelete(rol),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRolDialog(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }
}
