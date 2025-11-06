import 'package:flutter/material.dart';
import '../services/usuario_service.dart';
import '../services/rol_service.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final UsuarioService _usuarioService = UsuarioService();
  final RolService _rolService = RolService();
  List<dynamic> usuarios = [];
  List<dynamic> roles = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadUsuarios();
    await _loadRoles();
  }

  Future<void> _loadUsuarios() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await _usuarioService.getUsuarios();

    if (response['success']) {
      setState(() {
        usuarios = response['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = response['message'];
        isLoading = false;
      });
    }
  }

  Future<void> _loadRoles() async {
    final rolesData = await _rolService.getRolesForDropdown();
    setState(() {
      roles = rolesData;
    });
  }

  // 🔹 Mostrar diálogo para crear/editar usuario
  Future<void> _showUsuarioDialog({Map<String, dynamic>? usuario}) async {
    final usernameController = TextEditingController(text: usuario?['username'] ?? '');
    final emailController = TextEditingController(text: usuario?['email'] ?? '');
    final passwordController = TextEditingController();
    int? selectedRoleId = usuario?['role'] != null 
        ? roles.firstWhere((r) => r['name'] == usuario!['role'], orElse: () => {'id': null})['id']
        : null;
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(usuario == null ? 'Crear Usuario' : 'Editar Usuario'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de Usuario',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El nombre de usuario es requerido';
                          }
                          if (value.length < 3) {
                            return 'Mínimo 3 caracteres';
                          }
                          if (value.contains(' ')) {
                            return 'No puede contener espacios';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El email es requerido';
                          }
                          if (!value.contains('@')) {
                            return 'Email inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: usuario == null ? 'Contraseña' : 'Nueva Contraseña (opcional)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (usuario == null && (value == null || value.isEmpty)) {
                            return 'La contraseña es requerida';
                          }
                          if (value != null && value.isNotEmpty && value.length < 8) {
                            return 'Mínimo 8 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: selectedRoleId,
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.security),
                        ),
                        items: roles.map<DropdownMenuItem<int>>((rol) {
                          return DropdownMenuItem<int>(
                            value: rol['id'],
                            child: Text(rol['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedRoleId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Debe seleccionar un rol';
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
                        'username': usernameController.text,
                        'email': emailController.text,
                        'role_id': selectedRoleId,
                      };

                      if (passwordController.text.isNotEmpty) {
                        data['password'] = passwordController.text;
                      }

                      final response = usuario == null
                          ? await _usuarioService.createUsuario(data)
                          : await _usuarioService.updateUsuario(usuario['id'], data);

                      if (!mounted) return;
                      Navigator.pop(context);

                      if (response['success']) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(usuario == null
                                ? 'Usuario creado exitosamente'
                                : 'Usuario actualizado exitosamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadUsuarios();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(response['message'] ?? 'Error al guardar usuario'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(usuario == null ? 'Crear' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🔹 Confirmar eliminación de usuario
  Future<void> _confirmDelete(Map<String, dynamic> usuario) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Está seguro de eliminar el usuario "${usuario['username']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                final response = await _usuarioService.deleteUsuario(usuario['id']);

                if (!mounted) return;

                if (response['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Usuario eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadUsuarios();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response['message'] ?? 'Error al eliminar usuario'),
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
        title: const Text('Usuarios'),
        backgroundColor: Colors.blue,
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
                        onPressed: _loadUsuarios,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : usuarios.isEmpty
                  ? const Center(child: Text('No hay usuarios disponibles'))
                  : RefreshIndicator(
                      onRefresh: _loadUsuarios,
                      child: ListView.builder(
                        itemCount: usuarios.length,
                        itemBuilder: (context, index) {
                          final usuario = usuarios[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                usuario['username'] ?? 'Sin usuario',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(usuario['email'] ?? 'Sin email'),
                                  Text(
                                    'Rol: ${usuario['role'] ?? 'Sin rol'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.deepPurple,
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
                                    onPressed: () => _showUsuarioDialog(usuario: usuario),
                                  ),
                                  // Botón eliminar
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmDelete(usuario),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUsuarioDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
