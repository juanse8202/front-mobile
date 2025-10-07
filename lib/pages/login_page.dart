import 'package:flutter/material.dart';
import '../api/server.dart';
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

      try {
        final tokens = await _authService.login(user, pass);
        final access = tokens["access"];

        Navigator.pushReplacementNamed(context, "/perfil", arguments: access);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Iniciar Sesión"),
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 👇 Logo en la parte superior
              SizedBox(
                height: 180,
                width: 180,
                child: Image.asset("assets/images/logo7.png"),
              ),
              const SizedBox(height: 32),

              CustomTextField(
                controller: _userController,
                label: "Usuario",
                validator: (value) =>
                    value!.isEmpty ? "Ingrese su usuario" : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passController,
                label: "Contraseña",
                isPassword: true,
                validator: (value) =>
                    value!.isEmpty ? "Ingrese su contraseña" : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
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
    );
  }
}
