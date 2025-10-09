import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';

class EditarPerfilPage extends StatefulWidget {
  const EditarPerfilPage({super.key});

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final AuthService _authService = AuthService();
  late String token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recibimos el token pasado desde PerfilPage con manejo de errores
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args != null && args is String) {
      token = args;
      _loadProfile(token);
    } else {
      // Si no hay token, regresar a login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No se encontró el token de sesión")),
      );
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
    }
  }

  // Cargar datos actuales del usuario
  void _loadProfile(String token) async {
    final res = await _authService.getProfile(token);

    if (res['success']) {
      final data = res['data'];
      _nombreController.text = "${data['first_name'] ?? ''} ${data['last_name'] ?? ''}";
      _correoController.text = data['email'] ?? '';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Error al cargar perfil")),
      );
    }
  }

  // Guardar cambios
  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreController.text.trim();
    final correo = _correoController.text.trim();

    // Aquí podrías separar first_name y last_name si quieres
    final parts = nombre.split(" ");
    final firstName = parts.isNotEmpty ? parts[0] : "";
    final lastName = parts.length > 1 ? parts.sublist(1).join(" ") : "";

    final res = await _authService.updateProfile(token, firstName, lastName, correo);

    if (res['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil actualizado ✅")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Error al actualizar perfil")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nombreController,
                label: "Nombre completo",
                validator: (value) =>
                    value!.isEmpty ? "Ingrese su nombre" : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _correoController,
                label: "Correo electrónico",
                validator: (value) =>
                    value!.isEmpty ? "Ingrese su correo" : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Guardar cambios"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
