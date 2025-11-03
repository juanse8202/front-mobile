import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
// modo local: no requiere servicio

class PresupuestoDetailPage extends StatefulWidget {
  const PresupuestoDetailPage({super.key});

  @override
  State<PresupuestoDetailPage> createState() => _PresupuestoDetailPageState();
}

class _PresupuestoDetailPageState extends State<PresupuestoDetailPage> {
  Map<String, dynamic>? presupuesto;
  List<dynamic> detalles = [];
  bool loading = false;
  int? id;
  String? token;

  String _fmtNum(dynamic v) {
    try {
      if (v == null) return '-';
      final numVal = (v is num) ? v.toDouble() : double.parse(v.toString());
      return numVal.toStringAsFixed(2);
    } catch (e) {
      return v.toString();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      presupuesto = args['presupuesto'] as Map<String, dynamic>?;
      token = args['token'] as String?;
      if (presupuesto != null) {
        id = presupuesto!['id'] as int?;
        detalles = List<dynamic>.from(presupuesto!['detalles'] ?? []);
      }
    }
  }

  // No fetch: mostrar datos pasados desde la lista (modo local)

  Future<void> _showAddDetalle() async {
  final item = TextEditingController();
  final cant = TextEditingController();
  final precio = TextEditingController();
  final descuento = TextEditingController();

    final res = await showDialog<bool>(
      context: context,
  builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: const Center(child: Text('Agregar detalle', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600))),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: item,
                label: 'Item id',
                prefixIcon: Icons.list_alt,
                filled: true,
                // numeric id
                validator: (v) => null,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: cant,
                label: 'Cantidad',
                prefixIcon: Icons.grid_3x3,
                filled: true,
                validator: (v) => null,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: precio,
                label: 'Precio unitario',
                prefixIcon: Icons.attach_money,
                filled: true,
                validator: (v) => null,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: descuento,
                label: 'Descuento (por detalle)',
                prefixIcon: Icons.percent,
                filled: true,
                validator: (v) => null,
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: Colors.deepPurple.shade700))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0), child: Text('Agregar')),
          ),
        ],
      ),
    );

    if (res == true) {
      final qty = double.tryParse(cant.text) ?? 1.0;
      final price = double.tryParse(precio.text) ?? 0.0;
      final disc = double.tryParse(descuento.text) ?? 0.0;

      final newDetalle = {
        'id': (detalles.isNotEmpty ? detalles.map((d) => d['id'] as int).reduce((a, b) => a > b ? a : b) : 0) + 1,
        'item': int.tryParse(item.text) ?? 0,
        'cantidad': qty,
        'precio_unitario': price,
        'descuento': disc,
      };

      final lineSubtotal = qty * price; // antes de descuento
      newDetalle['subtotal'] = lineSubtotal;
      newDetalle['total'] = (lineSubtotal - disc);

      detalles.add(newDetalle);
      // actualizar en presupuesto local
      if (presupuesto != null) {
        presupuesto!['detalles'] = detalles;
        // recalcular subtotal (sumar totales de líneas después de descuento) y total con impuesto y descuento global
        final subtotal = detalles.fold<double>(0.0, (prev, d) => prev + ((d['total'] as num).toDouble()));
        presupuesto!['subtotal'] = subtotal;
        final impuesto = (presupuesto!['impuesto'] is num) ? (presupuesto!['impuesto'] as num).toDouble() : 0.0;
        final descuentoGlobal = (presupuesto!['descuento'] is num) ? (presupuesto!['descuento'] as num).toDouble() : 0.0;
        presupuesto!['total'] = subtotal * (1 + impuesto) - descuentoGlobal;
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Detalle agregado (local)')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Presupuesto #${id ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_check),
            onPressed: () {
              if (presupuesto != null) {
                Navigator.pushNamed(context, '/generar-orden', arguments: {'presupuesto': presupuesto});
              }
            },
            tooltip: 'Generar orden',
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orangeAccent.shade700,
        onPressed: _showAddDetalle,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta con atributos del presupuesto
                      Card(
                        color: Colors.deepPurple.shade500,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Presupuesto #${presupuesto?['id'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                              const SizedBox(height: 8),
                              Text('Diagnóstico: ${presupuesto?['diagnostico'] ?? '-'}', style: const TextStyle(color: Colors.white70)),
                              Text('Fecha inicio: ${presupuesto?['fecha_inicio'] ?? '-'}', style: const TextStyle(color: Colors.white70)),
                              Text('Fecha fin: ${presupuesto?['fecha_fin'] ?? '-'}', style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, children: [
                                Chip(label: Text('Subtotal: ${_fmtNum(presupuesto?['subtotal'])}', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.blueGrey.shade700),
                                Chip(label: Text('IVA: ${_fmtNum(presupuesto?['impuesto'])}', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.teal.shade700),
                                Chip(label: Text('Desc: ${_fmtNum(presupuesto?['descuento'])}', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent.shade700),
                                Chip(label: Text('Total: ${_fmtNum(presupuesto?['total'])}', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.orangeAccent.shade700),
                              ])
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Detalles:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: detalles.isEmpty
                            ? const Center(child: Text('No hay detalles'))
                            : ListView.builder(
                                itemCount: detalles.length,
                                itemBuilder: (context, i) {
                                  final d = detalles[i] as Map<String, dynamic>;
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Detalle #${d['id'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 6),
                                          Text('Item id: ${d['item'] ?? '-'}'),
                                          Text('Cantidad: ${_fmtNum(d['cantidad'])}'),
                                          Text('Precio unitario: ${_fmtNum(d['precio_unitario'])}'),
                                          Text('Descuento: ${_fmtNum(d['descuento'])}'),
                                          Text('Subtotal: ${_fmtNum(d['subtotal'])}'),
                                          Text('Total: ${_fmtNum(d['total'])}'),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      )
                    ],
                  ),
            ),
    );
  }
}
