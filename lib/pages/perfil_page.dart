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
      setState(() {
        userData = res['data'];
        isLoading = false;
        errorMessage = null;
      });
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
    // Eliminar tokens del storage
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');

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
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              displayName(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
            const SizedBox(height: 6),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Color(0xFF5E35B1)),
              ),
              title: const Text("Editar Perfil"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  "/editar-perfil",
                  arguments: token,
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, color: Colors.teal),
              ),
              title: const Text("Cambiar Contraseña"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  "/cambiar-password",
                  arguments: token,
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long, color: Colors.orange),
              ),
              title: const Text("Presupuestos"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/presupuestos',
                  arguments: {'token': token},
                );
              },
            ),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle), child: const Icon(Icons.directions_car, color: Colors.blue)),
              title: const Text("Vehículos"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/vehiculos', arguments: {'token': token});
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.green),
              ),
              title: const Text("Reconocimiento de Placas"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/reconocimiento');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.work, color: Colors.deepPurple),
              ),
              title: const Text("Órdenes de Trabajo"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/ordenes');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history, color: Colors.teal),
              ),
              title: const Text("Mis Órdenes"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/mis-ordenes');
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(color: Colors.grey),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: Colors.red),
              ),
              title: const Text("Cerrar sesión"),
              onTap: () => _logout(context),
            ),
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
