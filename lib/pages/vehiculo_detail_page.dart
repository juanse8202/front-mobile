import 'package:flutter/material.dart';
import '../services/vehiculo_service.dart';

class VehiculoDetailPage extends StatefulWidget {
  const VehiculoDetailPage({super.key});

  @override
  State<VehiculoDetailPage> createState() => _VehiculoDetailPageState();
}

class _VehiculoDetailPageState extends State<VehiculoDetailPage> {
  final VehiculoService _service = VehiculoService();
  String? token;
  int? vehiculoId;
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      token = args['token'] as String?;
      vehiculoId = args['vehiculoId'] as int?;
    }
    _load();
  }

  Future<void> _load() async {
    if (vehiculoId == null) return;
    setState(() { loading = true; error = null; });
    try {
      data = await _service.fetchById(vehiculoId!, token: token);
      setState(() { loading = false; });
    } catch (e) {
      setState(() { loading = false; error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de vehículo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header simple
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child: Icon(Icons.directions_car, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data?['numero_placa'] ?? '-',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${data?['marca_nombre'] ?? ''} ${data?['modelo_nombre'] ?? ''}'.trim(),
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            if (data?['año'] != null)
                              Chip(
                                label: Text(data!['año'].toString()),
                                backgroundColor: Colors.deepPurple.shade100,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Información del vehículo
                    _tile('VIN', data?['vin']),
                    _tile('Número de Motor', data?['numero_motor']),
                    _tile('Versión', data?['version']),
                    _tile('Color', data?['color']),
                    _tile('Tipo', data?['tipo']),
                    _tile('Cilindrada', data?['cilindrada']?.toString()),
                    _tile('Tipo de Combustible', data?['tipo_combustible']),
                    _tile('Cliente', data?['cliente_nombre']),
                  ],
                ),
    );
  }

  Widget _tile(String title, String? value) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(value == null || value.toString().isEmpty ? 'No especificado' : value.toString()),
      ),
    );
  }
}


