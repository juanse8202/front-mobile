import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/cliente_service.dart';
import '../services/user_service.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final ClienteService _clienteService = ClienteService();
  final UserService _userService = UserService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<dynamic> clientes = [];
  List<dynamic> usuarios = [];
  bool loading = true;
  String? token;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    token = await _storage.read(key: 'access_token');
    await Future.wait([
      _cargarClientes(),
      _cargarUsuarios(),
    ]);
  }

  Future<void> _cargarClientes() async {
    setState(() => loading = true);
    try {
      final result = await _clienteService.fetchAll(
        token: token,
        search: searchQuery.isEmpty ? null : searchQuery,
      );
      setState(() {
        clientes = result;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar clientes: $e')),
        );
      }
    }
  }

  Future<void> _cargarUsuarios() async {
    try {
      final result = await _userService.fetchAll(token: token);
      setState(() {
        usuarios = result;
      });
      print('Usuarios cargados: ${usuarios.length}');
    } catch (e) {
      print('Error al cargar usuarios: $e');
      // Silenciar error si no se pueden cargar usuarios
    }
  }

  Future<void> _mostrarDialogoCliente({Map<String, dynamic>? cliente}) async {
    final esEdicion = cliente != null;
    final nombreController = TextEditingController(text: cliente?['nombre'] ?? '');
    final apellidoController = TextEditingController(text: cliente?['apellido'] ?? '');
    final ciController = TextEditingController(text: cliente?['ci'] ?? '');
    final nitController = TextEditingController(text: cliente?['nit'] ?? '');
    final telefonoController = TextEditingController(text: cliente?['telefono'] ?? '');
    final direccionController = TextEditingController(text: cliente?['direccion'] ?? '');
    
    String tipoCliente = cliente?['tipo_cliente'] ?? 'NATURAL';
    bool activo = cliente?['activo'] ?? true;
    int? usuarioSeleccionado = cliente?['usuario'];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(esEdicion ? 'Editar Cliente' : 'Nuevo Cliente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: apellidoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ciController,
                  decoration: const InputDecoration(
                    labelText: 'CI (Cédula de Identidad)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nitController,
                  decoration: const InputDecoration(
                    labelText: 'NIT *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tipoCliente,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Cliente',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'NATURAL', child: Text('Natural')),
                    DropdownMenuItem(value: 'EMPRESA', child: Text('Empresa')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      tipoCliente = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: activo ? 'Activo' : 'Inactivo',
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                    DropdownMenuItem(value: 'Inactivo', child: Text('Inactivo')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      activo = value == 'Activo';
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (usuarios.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'No hay usuarios disponibles para asociar',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<int?>(
                    value: usuarioSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Usuario Asociado (Opcional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Sin usuario asociado'),
                      ),
                      ...usuarios.map((user) => DropdownMenuItem(
                        value: user['id'],
                        child: Text(user['username'] ?? 'Usuario ${user['id']}'),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        usuarioSeleccionado = value;
                      });
                    },
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
                if (nombreController.text.isEmpty || nitController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nombre y NIT son obligatorios')),
                  );
                  return;
                }

                final body = {
                  'nombre': nombreController.text.trim(),
                  'apellido': apellidoController.text.trim(),
                  'ci': ciController.text.trim().isEmpty ? null : ciController.text.trim(),
                  'nit': nitController.text.trim(),
                  'telefono': telefonoController.text.trim(),
                  'direccion': direccionController.text.trim(),
                  'tipo_cliente': tipoCliente,
                  'activo': activo,
                  'usuario': usuarioSeleccionado,
                };

                try {
                  final response = esEdicion
                      ? await _clienteService.updateCliente(cliente['id'], body, token: token)
                      : await _clienteService.createCliente(body, token: token);

                  if (response['status'] >= 200 && response['status'] < 300) {
                    Navigator.pop(ctx, true);
                  } else {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${response['body']}')),
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
              child: Text(esEdicion ? 'Guardar Cambios' : 'Crear Cliente'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _cargarClientes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(esEdicion ? 'Cliente actualizado' : 'Cliente creado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _eliminarCliente(int id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar al cliente "$nombre"?'),
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
        final response = await _clienteService.deleteCliente(id, token: token);
        if (response['status'] >= 200 && response['status'] < 300) {
          await _cargarClientes();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cliente eliminado'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  Future<void> _verDetalles(int id) async {
    try {
      final cliente = await _clienteService.getCliente(id, token: token);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('${cliente['nombre']} ${cliente['apellido']}'.trim()),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('CI', cliente['ci'] ?? 'No especificado'),
                  _buildDetailRow('NIT', cliente['nit'] ?? 'No especificado'),
                  _buildDetailRow('Teléfono', cliente['telefono'] ?? 'No especificado'),
                  _buildDetailRow('Dirección', cliente['direccion'] ?? 'No especificada'),
                  _buildDetailRow('Tipo', cliente['tipo_cliente'] == 'EMPRESA' ? 'Empresa' : 'Natural'),
                  _buildDetailRow('Estado', cliente['activo'] ? 'Activo' : 'Inactivo'),
                  if (cliente['usuario_info'] != null) ...[
                    const Divider(),
                    const Text('Usuario Asociado:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    _buildDetailRow('Usuario', cliente['usuario_info']['username'] ?? 'N/A'),
                    _buildDetailRow('Email', cliente['usuario_info']['email'] ?? 'N/A'),
                  ] else
                    const Text('Sin usuario asociado', style: TextStyle(color: Colors.grey)),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar detalles: $e')),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Clientes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
                _cargarClientes();
              },
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : clientes.isEmpty
              ? const Center(
                  child: Text(
                    'No hay clientes registrados',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarClientes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: clientes.length,
                    itemBuilder: (context, index) {
                      final cliente = clientes[index];
                      final nombre = cliente['nombre'] ?? '';
                      final apellido = cliente['apellido'] ?? '';
                      final ci = cliente['ci'] ?? 'Sin CI';
                      final nit = cliente['nit'] ?? 'Sin NIT';
                      final telefono = cliente['telefono'] ?? 'Sin teléfono';
                      final direccion = cliente['direccion'] ?? 'Sin dirección';
                      final tipoCliente = cliente['tipo_cliente'] ?? 'NATURAL';
                      final activo = cliente['activo'] ?? true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: activo ? Colors.deepPurple : Colors.grey,
                            child: Icon(
                              tipoCliente == 'EMPRESA' 
                                ? Icons.business 
                                : Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            '$nombre $apellido'.trim(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('CI: $ci'),
                              Text('NIT: $nit'),
                              Text('Tel: $telefono'),
                              if (direccion != 'Sin dirección')
                                Text('Dir: $direccion'),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: activo ? Colors.green : Colors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  activo ? 'Activo' : 'Inactivo',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'ver',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility, size: 20),
                                    SizedBox(width: 8),
                                    Text('Ver detalles'),
                                  ],
                                ),
                              ),
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
                              if (value == 'ver') {
                                _verDetalles(cliente['id']);
                              } else if (value == 'editar') {
                                _mostrarDialogoCliente(cliente: cliente);
                              } else if (value == 'eliminar') {
                                final nombre = '${cliente['nombre']} ${cliente['apellido']}'.trim();
                                _eliminarCliente(cliente['id'], nombre);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => _mostrarDialogoCliente(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
