import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _pass2Controller = TextEditingController();
  final AuthService _authService = AuthService();

  // Validación de contraseña fuerte
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Ingrese su contraseña";
    if (value.length < 8) return "Debe tener al menos 8 caracteres";
    if (!RegExp(r'[A-Z]').hasMatch(value)) return "Debe tener al menos una mayúscula";
    if (!RegExp(r'[0-9]').hasMatch(value)) return "Debe tener al menos un número";
    if (!RegExp(r'[!@#\$&*~.,;?¿¡]').hasMatch(value)) {
      return "Debe tener al menos un carácter especial (!@#\$&*~.,;?¿¡)";
    }
    return null;
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _userController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passController.text;
    final pass2 = _pass2Controller.text;

    if (pass != pass2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden ❌")),
      );
      return;
    }

    final res = await _authService.register(user, email, pass, pass2);

    if (res['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registro exitoso 🎉")),
      );

      // 🔹 Login automático
      final loginRes = await _authService.login(user, pass);
      if (loginRes['success']) {
        final access = loginRes['data']['access'];
        Navigator.pushReplacementNamed(context, "/perfil", arguments: access);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loginRes['message'] ?? "Error al iniciar sesión")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Error al registrarse")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                CustomTextField(
                  controller: _userController,
                  label: "Usuario",
                  validator: (v) => v!.isEmpty ? "Ingrese un nombre de usuario" : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: "Correo electrónico",
                  validator: (v) => v!.isEmpty ? "Ingrese su correo" : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passController,
                  label: "Contraseña",
                  isPassword: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _pass2Controller,
                  label: "Repetir contraseña",
                  isPassword: true,
                  validator: (v) => v!.isEmpty ? "Repita su contraseña" : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("Registrarse"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
