import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';

class CambiarPasswordPage extends StatefulWidget {
  const CambiarPasswordPage({super.key});

  @override
  State<CambiarPasswordPage> createState() => _CambiarPasswordPageState();
}

class _CambiarPasswordPageState extends State<CambiarPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? fieldErrors;

  void _changePassword(String token) async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden ⚠️")),
      );
      return;
    }

    final res = await _authService.changePassword(
      token,
      _oldPassController.text,
      _newPassController.text,
    );

    if (res['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contraseña cambiada con éxito 🎉")),
      );
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
    } else {
      fieldErrors = res['errors'] as Map<String, dynamic>?;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Error al cambiar contraseña")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.deepPurple, title: const Text("Cambiar Contraseña")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _oldPassController,
                label: "Contraseña actual",
                isPassword: true,
                prefixIcon: Icons.lock,
                filled: true,
                validator: (v) => v!.isEmpty ? "Ingrese su contraseña actual" : null,
              ),
              if (fieldErrors != null && fieldErrors!['old_password'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(fieldErrors!['old_password'].join('; '), style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _newPassController,
                label: "Nueva contraseña",
                isPassword: true,
                prefixIcon: Icons.lock,
                filled: true,
                validator: (v) => v!.isEmpty ? "Ingrese su nueva contraseña" : null,
              ),
              if (fieldErrors != null && fieldErrors!['new_password'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(fieldErrors!['new_password'].join('; '), style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _confirmPassController,
                label: "Repetir nueva contraseña",
                isPassword: true,
                prefixIcon: Icons.lock,
                filled: true,
                validator: (v) => v!.isEmpty ? "Repita su nueva contraseña" : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _changePassword(token),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent.shade700,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Cambiar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
