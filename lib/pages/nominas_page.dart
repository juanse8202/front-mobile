import 'package:flutter/material.dart';

class NominasPage extends StatelessWidget {
  const NominasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nóminas'),
        backgroundColor: Colors.greenAccent.shade700,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.money,
              size: 80,
              color: Colors.greenAccent.shade700,
            ),
            const SizedBox(height: 16),
            const Text(
              'Módulo de Nóminas',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Próximamente disponible',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
