import 'package:flutter/material.dart';
import '../api/server.dart';
import '../widgets/custom_text_field.dart'; // 👈 Importamos el TextField con ojito

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

  // 👇 Función para validar seguridad de la contraseña
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
    if (_formKey.currentState!.validate()) {
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

      try {
        // 🔹 Registrar usuario
        final res = await _authService.register(user, email, pass, pass2);
        final msg = res["message"] ?? "Registro exitoso 🎉";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );

        // 🔹 Login automático después de registro
        final tokens = await _authService.login(user, pass);
        final access = tokens["access"];

        Navigator.pushReplacementNamed(context, "/perfil", arguments: access);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
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
                TextFormField(
                  controller: _userController,
                  decoration: const InputDecoration(
                    labelText: "Usuario",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? "Ingrese un nombre de usuario" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Correo electrónico",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? "Ingrese su correo" : null,
                ),
                const SizedBox(height: 16),

                // 👇 Contraseña con ojito y validación fuerte
                CustomTextField(
                  controller: _passController,
                  label: "Contraseña",
                  isPassword: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),

                // 👇 Confirmar contraseña con validación normal
                CustomTextField(
                  controller: _pass2Controller,
                  label: "Repetir contraseña",
                  isPassword: true,
                  validator: (v) =>
                      v!.isEmpty ? "Repita su contraseña" : null,
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
