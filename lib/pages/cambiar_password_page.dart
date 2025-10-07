import 'package:flutter/material.dart';
import '../api/server.dart';
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

  void _changePassword(String token) async {
    if (_formKey.currentState!.validate()) {
      if (_newPassController.text != _confirmPassController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Las contraseñas no coinciden ⚠️")),
        );
        return;
      }

      try {
        await AuthService().changePassword(
          token,
          _oldPassController.text,
          _newPassController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contraseña cambiada con éxito 🎉")),
        );

        Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(title: const Text("Cambiar Contraseña")),
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
                validator: (v) =>
                    v!.isEmpty ? "Ingrese su contraseña actual" : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _newPassController,
                label: "Nueva contraseña",
                isPassword: true,
                validator: (v) =>
                    v!.isEmpty ? "Ingrese su nueva contraseña" : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _confirmPassController,
                label: "Repetir nueva contraseña",
                isPassword: true,
                validator: (v) =>
                    v!.isEmpty ? "Repita su nueva contraseña" : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _changePassword(token),
                style: ElevatedButton.styleFrom(
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
