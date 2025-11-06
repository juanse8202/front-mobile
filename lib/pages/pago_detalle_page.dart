import 'package:flutter/material.dart';

class PagoDetallePage extends StatefulWidget {
  final Map<String, dynamic> pago;

  const PagoDetallePage({super.key, required this.pago});

  @override
  State<PagoDetallePage> createState() => _PagoDetallePageState();
}

class _PagoDetallePageState extends State<PagoDetallePage> {

  String _getMetodoIcon(String metodo) {
    switch (metodo.toLowerCase()) {
      case 'efectivo':
        return '💵';
      case 'tarjeta':
        return '💳';
      case 'transferencia':
        return '🏦';
      case 'cheque':
        return '📄';
      case 'stripe':
        return '💳';
      default:
        return '💰';
    }
  }

  // Helper to build a simple label/value row for details
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Colors.grey[700])),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pago = widget.pago;
    final montoRaw = pago['monto'] ?? 0;
    final monto = montoRaw is String ? double.tryParse(montoRaw) ?? 0.0 : (montoRaw is num ? montoRaw.toDouble() : 0.0);
    final metodo = (pago['metodo_pago'] ?? 'N/A').toString();
    final estado = (pago['estado'] ?? 'pendiente').toString();
    final fecha = (pago['fecha_pago'] ?? pago['created_at'] ?? 'N/A').toString();
    final orden = pago['orden_trabajo_numero'] ?? pago['orden_trabajo_id'] ?? pago['orden_trabajo'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Pago'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_getMetodoIcon(metodo), style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Orden #$orden', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                              const SizedBox(height: 6),
                              Text(metodo, style: const TextStyle(color: Colors.black87)),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text('\$${monto.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.orangeAccent.shade700,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Fecha'),
                      subtitle: Text(fecha.split('T')[0]),
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Estado'),
                      subtitle: Text(estado.toString()),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('ID', pago['id']?.toString() ?? '—'),
                    _buildDetailRow('Orden', pago['orden_trabajo_numero']?.toString() ?? pago['orden_trabajo_id']?.toString() ?? pago['orden_trabajo']?.toString() ?? '—'),
                    _buildDetailRow('Cliente', pago['cliente_nombre']?.toString() ?? pago['usuario_nombre']?.toString() ?? '—'),
                    _buildDetailRow('Monto', '\$${monto.toStringAsFixed(2)}'),
                    _buildDetailRow('Método', metodo),
                    _buildDetailRow('Estado', estado.toString()),
                    _buildDetailRow('Fecha', fecha.split('T')[0]),
                    _buildDetailRow('Payment Intent', pago['stripe_payment_intent_id']?.toString() ?? pago['payment_intent_id']?.toString() ?? '—'),
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
