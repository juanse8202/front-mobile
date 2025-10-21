import 'package:flutter/material.dart';

/// Página placeholder para detalles de orden de trabajo
/// Esta página será implementada por otro desarrollador
/// Por ahora solo muestra la información básica de la orden
class OrdenDetallesPage extends StatelessWidget {
  const OrdenDetallesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Recibir el ID de la orden como argumento
    final ordenId = ModalRoute.of(context)?.settings.arguments as int?;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ordenId != null ? 'Orden #$ordenId' : 'Orden de Trabajo',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícono de construcción
              const Icon(
                Icons.construction,
                size: 100,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              
              // Título
              Text(
                ordenId != null 
                  ? 'Orden de Trabajo #$ordenId'
                  : 'Orden de Trabajo',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Mensaje
              const Text(
                'Esta funcionalidad está en desarrollo',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              const Text(
                '🚧 Próximamente disponible 🚧',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Botón para volver
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
