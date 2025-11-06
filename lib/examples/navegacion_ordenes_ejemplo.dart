import 'package:flutter/material.dart';
import '../pages/ordenes_page.dart';

/// EJEMPLO: Cómo navegar al módulo de órdenes desde cualquier página de tu app

// ========== OPCIÓN 1: Usar rutas nombradas ==========
void navegarConRutaNombrada(BuildContext context) {
  Navigator.pushNamed(context, '/ordenes');
}

// ========== OPCIÓN 2: Usar Navigator.push directo ==========
void navegarConPush(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const OrdenesPage()),
  );
}

// ========== EJEMPLO: Botón para navegar a órdenes ==========
class BotonOrdenes extends StatelessWidget {
  const BotonOrdenes({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pushNamed(context, '/ordenes');
      },
      icon: const Icon(Icons.work),
      label: const Text('Ver Órdenes de Trabajo'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}

// ========== EJEMPLO: Card para navegar a órdenes ==========
class CardOrdenes extends StatelessWidget {
  const CardOrdenes({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/ordenes');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.work, size: 48, color: Colors.deepPurple),
              const SizedBox(height: 8),
              const Text(
                'Órdenes de Trabajo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Gestiona las órdenes del taller',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== EJEMPLO: ListTile en un Drawer/Menu ==========
ListTile menuItemOrdenes(BuildContext context) {
  return ListTile(
    leading: const Icon(Icons.work, color: Colors.deepPurple),
    title: const Text('Órdenes de Trabajo'),
    onTap: () {
      Navigator.pop(context); // Cierra el drawer si está abierto
      Navigator.pushNamed(context, '/ordenes');
    },
  );
}

// ========== EJEMPLO: Agregar en el perfil o menú principal ==========
class EjemploMenuPrincipal extends StatelessWidget {
  const EjemploMenuPrincipal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú Principal'),
        backgroundColor: Colors.deepPurple,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildMenuCard(
            context,
            icon: Icons.work,
            title: 'Órdenes',
            subtitle: 'Ver órdenes de trabajo',
            route: '/ordenes',
            color: Colors.deepPurple,
          ),
          _buildMenuCard(
            context,
            icon: Icons.directions_car,
            title: 'Vehículos',
            subtitle: 'Gestionar vehículos',
            route: '/vehiculos',
            color: Colors.blue,
          ),
          _buildMenuCard(
            context,
            icon: Icons.receipt_long,
            title: 'Presupuestos',
            subtitle: 'Ver presupuestos',
            route: '/presupuestos',
            color: Colors.green,
          ),
          _buildMenuCard(
            context,
            icon: Icons.person,
            title: 'Perfil',
            subtitle: 'Mi cuenta',
            route: '/perfil',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== EJEMPLO: Uso en PerfilPage o HomePage ==========
/// En tu archivo perfil_page.dart o cualquier otra página, puedes agregar:
/// 
/// ```dart
/// ListTile(
///   leading: const Icon(Icons.work),
///   title: const Text('Órdenes de Trabajo'),
///   trailing: const Icon(Icons.arrow_forward_ios),
///   onTap: () {
///     Navigator.pushNamed(context, '/ordenes');
///   },
/// ),
/// ```
