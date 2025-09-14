import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';

class EditarPerfilPage extends StatelessWidget {
  const EditarPerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final nombreController = TextEditingController();
    final correoController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(
              controller: nombreController,
              label: "Nombre",
              validator: (value) => null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: correoController,
              label: "Correo electrónico",
              validator: (value) => null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Perfil actualizado ✅")),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Guardar cambios"),
            ),
          ],
        ),
      ),
    );
  }
}

      