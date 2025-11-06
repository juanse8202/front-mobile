import 'package:flutter/material.dart';
import 'reportes_estaticos_page.dart';
import 'reportes_personalizados_page.dart';

class ReportesPage extends StatelessWidget {
  const ReportesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes y Análisis'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selecciona el tipo de reporte',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Genera reportes según tus necesidades',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // Reportes Estáticos (FUNCIONAL)
            _buildReporteCard(
              context: context,
              icon: Icons.insert_chart,
              title: 'Reportes Estáticos',
              description: 'Reportes predefinidos del sistema: órdenes, ingresos, inventario crítico',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportesEstaticosPage(),
                  ),
                );
              },
              isAvailable: true,
            ),
            const SizedBox(height: 16),
            
            // Reportes Personalizados (FUNCIONAL)
            _buildReporteCard(
              context: context,
              icon: Icons.tune,
              title: 'Reportes Personalizados',
              description: 'Crea reportes personalizados seleccionando campos y filtros específicos',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportesPersonalizadosPage(),
                  ),
                );
              },
              isAvailable: true,
            ),
            const SizedBox(height: 16),
            
            // Reportes con Lenguaje Natural (PRÓXIMAMENTE)
            _buildReporteCard(
              context: context,
              icon: Icons.chat_bubble_outline,
              title: 'Reportes con IA',
              description: 'Genera reportes usando lenguaje natural: "Muéstrame las órdenes del mes pasado"',
              color: Colors.green,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Próximamente disponible'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              isAvailable: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReporteCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    required bool isAvailable,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isAvailable) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Próximamente',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isAvailable ? color : Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
