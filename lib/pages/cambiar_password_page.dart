import 'package:flutter/material.dart';
import '../api/server.dart';

class CambiarPasswordPage extends StatefulWidget {
  const CambiarPasswordPage({super.key});

  @override
  State<CambiarPasswordPage> createState() => _CambiarPasswordPageState();
}

class _CambiarPasswordPageState extends State<CambiarPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();

  void _changePassword(String token) async {
    if (_formKey.currentState!.validate()) {
      try {
        await AuthService().changePassword(
          token,
          _oldPassController.text,
          _newPassController.text,
        );

        // ✅ Mostramos confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contraseña cambiada con éxito 🎉")),
        );

        // ✅ Redirigir al login y limpiar navegación
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
              TextFormField(
                controller: _oldPassController,
                decoration: const InputDecoration(labelText: "Contraseña actual"),
                obscureText: true,
                validator: (v) =>
                    v!.isEmpty ? "Ingrese su contraseña actual" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPassController,
                decoration: const InputDecoration(labelText: "Nueva contraseña"),
                obscureText: true,
                validator: (v) =>
                    v!.isEmpty ? "Ingrese su nueva contraseña" : null,
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
