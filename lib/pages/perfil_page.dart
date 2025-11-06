import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';

class PerfilPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const PerfilPage({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  Map<String, dynamic>? userData;
  late String token;
  bool isLoading = true;
  String? errorMessage;
  String? userRole; // 🔹 Rol del usuario
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) {
      token = args;
      _loadProfile(token);
    } else {
      // Token faltante: ir al login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token no proporcionado. Por favor inicie sesión.'),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      });
    }
  }

  Future<void> _loadProfile(String token) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final res = await AuthService().getProfile(token);

    if (res['success']) {
      // 🔹 Cargar el rol del usuario desde secure storage
      final storedRole = await _storage.read(key: 'user_role');
      
      setState(() {
        userData = res['data'];
        userRole = storedRole ?? 'cliente'; // Por defecto cliente si no hay rol
        isLoading = false;
        errorMessage = null;
      });
      
      print('Perfil cargado. Rol: $userRole');
    } else {
      setState(() {
        isLoading = false;
        errorMessage = res['message'] ?? 'Error al obtener perfil';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage!)));
    }
  }

  Future<void> _logout(BuildContext context) async {
    // Eliminar tokens y rol del storage
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_role');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión cerrada correctamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
    }
  }

  // Widget para construir módulos expandibles
  Widget _buildExpansionModule({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      iconColor: Colors.white,
      collapsedIconColor: Colors.white70,
      children: children,
    );
  }

  // Widget para construir items del menú
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72, right: 16, top: 0, bottom: 0),
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = userData?['username'] ?? '';
    final email = userData?['email'] ?? '';
    final firstName = userData?['first_name'] ?? userData?['nombre'] ?? '';
    final lastName = userData?['last_name'] ?? userData?['apellido'] ?? '';

    // Calcular nombre a mostrar: preferir first+last, luego nombre+apellido, luego username
    String displayName() {
      final f = firstName.trim();
      final l = lastName.trim();
      if (f.isNotEmpty || l.isNotEmpty) {
        return (f + (f.isNotEmpty && l.isNotEmpty ? ' ' : '') + l).trim();
      }
      if (username.isNotEmpty) return username;
      return '-';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text("Mi Perfil"),
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header del Drawer
            Container(
              height: 160,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5E35B1), Color(0xFF8E24AA)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 36,
                          color: Color(0xFF5E35B1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              displayName(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Dashboard (solo para admin y empleado)
            if (userRole != 'cliente') ...[
              ListTile(
                leading: const Icon(Icons.dashboard, color: Colors.white),
                title: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  // Navegar al dashboard si existe
                },
              ),
              const Divider(height: 1, thickness: 1),
            ],

            // Mis Órdenes
            ListTile(
              leading: const Icon(Icons.assignment, color: Colors.white),
              title: const Text("Mis Órdenes", style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/mis-ordenes');
              },
            ),

            const Divider(height: 1, thickness: 1),

            // Módulo: Administración (solo para administradores y empleados)
            if (userRole == 'administrador' || userRole == 'admin' || userRole == 'empleado') ...[
              _buildExpansionModule(
                title: "Administración",
                icon: Icons.admin_panel_settings,
                children: [
                  _buildMenuItem(
                    icon: Icons.security,
                    title: "Rol",
                    color: Colors.deepPurple,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/roles", arguments: token);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.person,
                    title: "Usuario",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/usuarios", arguments: token);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.badge,
                    title: "Empleado",
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/empleados", arguments: token);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.work,
                    title: "Cargo",
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/cargos", arguments: token);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.check_circle,
                    title: "Asistencia",
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/asistencias", arguments: token);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.money,
                    title: "Nómina",
                    color: Colors.greenAccent.shade700,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/nominas", arguments: token);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.history,
                    title: "Bitácora",
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/bitacora');
                    },
                  ),
                ],
              ),
            ],

            const Divider(height: 1, thickness: 1),

            // CLIENTE: Solo mostrar Cita e Historial de Pagos
            if (userRole == 'cliente') ...[
              // Cita
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.white),
                title: const Text("Cita", style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/citas');
                },
              ),
              const Divider(height: 1, thickness: 1),
              
              // Historial de Pagos
              ListTile(
                leading: const Icon(Icons.payment, color: Colors.white),
                title: const Text("Historial de Pagos", style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/pagos');
                },
              ),
            ],

            // ADMIN Y EMPLEADO: Mostrar todos los módulos
            if (userRole != 'cliente') ...[
              // Módulo: Clientes
              _buildExpansionModule(
                title: "Clientes",
                icon: Icons.people,
                children: [
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: "Cliente",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/clientes', arguments: {'token': token});
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.calendar_today,
                    title: "Cita",
                    color: Colors.amber,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/citas');
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.chat,
                    title: "Asistente Virtual",
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/asistente-virtual');
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.history,
                    title: "Historial",
                    color: Colors.grey,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/historial');
                    },
                  ),
                ],
              ),

              const Divider(height: 1, thickness: 1),

              // Módulo: Operaciones
              _buildExpansionModule(
                title: "Operaciones",
                icon: Icons.settings,
                children: [
                  _buildMenuItem(
                    icon: Icons.receipt_long,
                    title: "Presupuesto",
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/presupuestos', arguments: {'token': token});
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.assignment,
                    title: "Orden de Trabajo",
                    color: Colors.deepPurple,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/ordenes');
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.directions_car,
                    title: "Vehículo",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/vehiculos', arguments: {'token': token});
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.camera_alt,
                    title: "Reconocimiento de Placas",
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/reconocimiento');
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.inventory,
                    title: "Inventario",
                    color: Colors.brown,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/inventario');
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.miscellaneous_services,
                    title: "Servicios",
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/servicios');
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.local_shipping,
                    title: "Proveedores",
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/proveedores');
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.category,
                    title: "Área",
                    color: Colors.cyan,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/areas');
                    },
                  ),
                ],
              ),

              const Divider(height: 1, thickness: 1),

              // Módulo: Finanzas
              _buildExpansionModule(
                title: "Finanzas",
                icon: Icons.account_balance_wallet,
                children: [
                  _buildMenuItem(
                    icon: Icons.payment,
                    title: "Historial de Pagos",
                    color: Colors.pink,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/pagos');
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.receipt,
                    title: "Factura Proveedor",
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/facturas-proveedor');
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.analytics,
                    title: "Reportes",
                    color: Colors.deepOrange,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/reportes');
                    },
                  ),
                ],
              ),
            ],

            const Divider(height: 1, thickness: 1),

            // Cerrar Sesión
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Cerrar Sesión",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () => _logout(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: Center(
        child: isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Cargando perfil...'),
                ],
              )
            : errorMessage != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $errorMessage', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _loadProfile(token),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent.shade700,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    username.isNotEmpty
                        ? 'Bienvenido $username 🎉'
                        : 'Bienvenido',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Nombre: ${displayName()}'),
                  Text('Correo: ${email.isNotEmpty ? email : '-'}'),
                ],
              ),
      ),
    );
  }
}
