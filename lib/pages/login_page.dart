import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const LoginPage({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final AuthService _authService = AuthService();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final user = _userController.text;
      final pass = _passController.text;

      // 🔹 Usando la versión final de AuthService
      final result = await _authService.login(user, pass);

      if (result['success']) {
        final access = result['data']['access'];
        // Debug: imprimir token en consola para verificar que llega correctamente
        print('Login successful - access token: ${access}');
        Navigator.pushReplacementNamed(context, "/perfil", arguments: access);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Error al iniciar sesión')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text("Iniciar Sesión"),
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         kToolbarHeight - 32,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 👇 Logo en la parte superior (más pequeño en pantallas pequeñas)
                  SizedBox(
                    height: MediaQuery.of(context).size.height > 600 ? 150 : 100,
                    width: MediaQuery.of(context).size.height > 600 ? 150 : 100,
                    child: Image.asset("assets/images/logo7.png"),
                  ),
                  const SizedBox(height: 24),

                  CustomTextField(
                    controller: _userController,
                    label: "Usuario",
                    prefixIcon: Icons.person,
                    filled: true,
                    validator: (value) => value!.isEmpty ? "Ingrese su usuario" : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passController,
                    label: "Contraseña",
                    isPassword: true,
                    prefixIcon: Icons.lock,
                    filled: true,
                    validator: (value) => value!.isEmpty ? "Ingrese su contraseña" : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent.shade700,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Ingresar"),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/registro");
                    },
                    child: const Text("¿No tienes cuenta? Regístrate"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
