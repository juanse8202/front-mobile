import 'package:flutter/material.dart';
import '../api/server.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    token = ModalRoute.of(context)!.settings.arguments as String;
    _loadProfile(token);
  }

  Future<void> _loadProfile(String token) async {
    try {
      final data = await AuthService().getProfile(token);
      setState(() {
        userData = data;
      });
    } catch (e) {
      print("Error al obtener perfil: $e");
    }
  }

  void _logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final username = userData?["username"] ?? "Cargando...";
    final email = userData?["email"] ?? "";
    final firstName = userData?["first_name"] ?? "";
    final lastName = userData?["last_name"] ?? "";

    return Scaffold(
      appBar: AppBar(
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
            UserAccountsDrawerHeader(
              accountName: Text("$firstName $lastName"),
              accountEmail: Text(email),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.deepPurple),
              ),
              decoration: const BoxDecoration(color: Colors.deepPurple),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Editar Perfil"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/editar-perfil");
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Cerrar sesión"),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Bienvenido $username 🎉",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Nombre: $firstName $lastName"),
            Text("Correo: $email"),
          ],
        ),
      ),
    );
  }
}
