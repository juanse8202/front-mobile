import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
// UI-only prototipo local: no se necesita el servicio HTTP aquí

class PresupuestosPage extends StatefulWidget {
  const PresupuestosPage({super.key});

  @override
  State<PresupuestosPage> createState() => _PresupuestosPageState();
}

class _PresupuestosPageState extends State<PresupuestosPage> {
  // Modo local: datos de ejemplo en memoria
  static List<Map<String, dynamic>> samplePresupuestos = [
    {
      'id': 1,
      'diagnostico': 'Revisión general y cambio de aceite',
      'fecha_inicio': '2025-10-10',
      'fecha_fin': '2025-10-12',
      'descuento': 10.0,
      'impuesto': 0.18,
      'subtotal': 200.0,
      'total': 200.0 * 1.18 - 10.0,
      'detalles': [
        {'id': 1, 'item': 5, 'cantidad': 1, 'precio_unitario': 100.0, 'descuento': 0.0, 'subtotal': 100.0, 'total': 100.0},
        {'id': 2, 'item': 6, 'cantidad': 1, 'precio_unitario': 100.0, 'descuento': 0.0, 'subtotal': 100.0, 'total': 100.0},
      ],
    },
    {
      'id': 2,
      'diagnostico': 'Cambio de frenos',
      'fecha_inicio': '2025-09-01',
      'fecha_fin': '2025-09-02',
      'descuento': 0.0,
      'impuesto': 0.12,
      'subtotal': 300.0,
      'total': 300.0 * 1.12,
      'detalles': [
        {'id': 3, 'item': 8, 'cantidad': 2, 'precio_unitario': 150.0, 'descuento': 0.0, 'subtotal': 300.0, 'total': 300.0},
      ],
    }
  ];

  List<dynamic> presupuestos = [];
  bool loading = true;
  String? token;
  bool _loaded = false;

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
    if (!_loaded) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      token = args != null ? (args['token'] as String?) : null;
      // Cargar desde datos locales (sin backend)
      presupuestos = List<Map<String, dynamic>>.from(samplePresupuestos);
      loading = false;
      _loaded = true;
    }
  }

  // Nota: la carga se hace en didChangeDependencies usando los datos locales

  Future<void> _showCreateDialog() async {
    final _diagController = TextEditingController();
    final _dateController = TextEditingController();
    final _vehController = TextEditingController();

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
          child: const Center(child: Text('Nuevo presupuesto', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600))),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _diagController,
                label: 'Diagnóstico',
                prefixIcon: Icons.note,
                filled: true,
                validator: (v) => null,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _dateController,
                label: 'Fecha inicio (YYYY-MM-DD)',
                prefixIcon: Icons.date_range,
                filled: true,
                validator: (v) => null,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _vehController,
                label: 'Vehículo id',
                prefixIcon: Icons.directions_car,
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
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0), child: Text('Crear')),
          ),
        ],
      ),
    );

    if (res == true) {
      // Crear localmente sin backend
      final newId = (samplePresupuestos.isNotEmpty ? samplePresupuestos.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) : 0) + 1;
      final newPres = {
        'id': newId,
        'diagnostico': _diagController.text,
        'fecha_inicio': _dateController.text,
        'fecha_fin': _dateController.text,
        'descuento': 0.0,
        'impuesto': 0.0,
        'subtotal': 0.0,
        'total': 0.0,
        'detalles': [],
      };
      samplePresupuestos.add(newPres);
      presupuestos = List<Map<String, dynamic>>.from(samplePresupuestos);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Presupuesto creado (local)')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presupuestos')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: presupuestos.length,
              itemBuilder: (context, i) {
                final p = presupuestos[i] as Map<String, dynamic>;
                return Card(
                  color: Colors.deepPurple.shade600,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pushNamed(context, '/presupuesto-detalle', arguments: {'presupuesto': p, 'token': token}),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0, top: 4),
                            child: Icon(Icons.receipt_long, color: Colors.white70),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Presupuesto #${p['id'] ?? '?'} - ${p['diagnostico'] ?? ''}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                                const SizedBox(height: 6),
                                Text('Subtotal: ${_fmtNum(p['subtotal'])}   Total: ${_fmtNum(p['total'])}', style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Chip(label: Text('\$ ${_fmtNum(p['total'])}', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.orangeAccent.shade700),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
