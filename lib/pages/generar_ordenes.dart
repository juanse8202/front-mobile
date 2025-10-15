import 'package:flutter/material.dart';

class GenerarOrdenPage extends StatelessWidget {
  const GenerarOrdenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final presupuesto = args != null ? args['presupuesto'] as Map<String, dynamic>? : null;

    if (presupuesto == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Orden de trabajo')),
        body: const Center(child: Text('No hay presupuesto seleccionado')),
      );
    }

    final detalles = List<Map<String, dynamic>>.from(presupuesto['detalles'] ?? []);

    String _fmt(dynamic v) {
      try {
        if (v == null) return '-';
        final n = (v is num) ? v.toDouble() : double.parse(v.toString());
        return n.toStringAsFixed(2);
      } catch (e) {
        return v.toString();
      }
    }

    final subtotal = (presupuesto['subtotal'] is num) ? (presupuesto['subtotal'] as num).toDouble() : detalles.fold<double>(0.0, (p, d) => p + ((d['total'] ?? d['subtotal'] ?? 0) as num).toDouble());
    final impuesto = (presupuesto['impuesto'] is num) ? (presupuesto['impuesto'] as num).toDouble() : 0.0;
    final descuento = (presupuesto['descuento'] is num) ? (presupuesto['descuento'] as num).toDouble() : 0.0;
    final total = subtotal * (1 + impuesto) - descuento;

    return Scaffold(
      appBar: AppBar(title: Text('Orden #${presupuesto['id'] ?? ''}')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.deepPurple.shade600,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Orden de trabajo - Presupuesto #${presupuesto['id'] ?? '-'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Diagnóstico: ${presupuesto['diagnostico'] ?? '-'}', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Servicios / Productos', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: detalles.length,
                itemBuilder: (context, i) {
                  final d = detalles[i];
                  final item = d['item'] ?? '-';
                  final cant = d['cantidad'] ?? '-';
                  final price = d['precio_unitario'] ?? d['subtotal'] ?? 0;
                  final lineTotal = d['total'] ?? d['subtotal'] ?? 0;
                  return ListTile(
                    title: Text('Item $item'),
                    subtitle: Text('Cant: $cant  Precio: ${_fmt(price)}'),
                    trailing: Text('${_fmt(lineTotal)}'),
                  );
                },
              ),
            ),
            const Divider(),
            // summary and actions container pushed up a bit from the bottom
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Subtotal: ${_fmt(subtotal)}'),
                      Text('IVA: ${_fmt(impuesto)}'),
                      Text('Descuento: ${_fmt(descuento)}'),
                      Text('Total: ${_fmt(total)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SafeArea(
              minimum: const EdgeInsets.only(bottom: 18.0),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent.shade700, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Orden generada (simulada)')));
                        Navigator.pop(context);
                      },
                      child: const Text('Generar orden'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
