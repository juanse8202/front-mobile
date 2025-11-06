import 'package:flutter/material.dart';
import '../services/vehiculo_service.dart';

class VehiculosPage extends StatefulWidget {
  const VehiculosPage({super.key});

  @override
  State<VehiculosPage> createState() => _VehiculosPageState();
}

class _VehiculosPageState extends State<VehiculosPage> {
  final VehiculoService _service = VehiculoService();
  final TextEditingController _searchCtrl = TextEditingController();

  String? token;
  bool loading = true;
  String? error;
  List<dynamic> vehiculos = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialized) return;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['token'] is String) {
        token = args['token'] as String;
        _load();
      }
      _initialized = true;
    });
  }

  Future<void> _load({String? search}) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await _service.fetchAll(token: token, search: search);
      setState(() {
        vehiculos = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _delete(int id) async {
    final ok = await _service.deleteVehiculo(id, token: token);
    if (ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehículo eliminado')),
        );
      }
      await _load(search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim());
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehículos'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barra de búsqueda simple
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por placa, VIN, cliente, marca, modelo...',
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (v) => _load(search: v.trim()),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48),
                            const SizedBox(height: 16),
                            Text('Error: $error', textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _load(),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _load(search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim()),
                        child: vehiculos.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.directions_car_outlined, size: 48),
                                    SizedBox(height: 16),
                                    Text('No hay vehículos registrados'),
                                    SizedBox(height: 8),
                                    Text('Toca el botón + para agregar el primero'),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: vehiculos.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final v = vehiculos[index] as Map<String, dynamic>;
                                  final placa = v['numero_placa'] ?? '-';
                                  final marca = v['marca_nombre'] ?? '';
                                  final modelo = v['modelo_nombre'] ?? '';
                                  final color = v['color'] ?? '';
                                  final cliente = v['cliente_nombre'] ?? '';
                                  final anio = v['año']?.toString() ?? '';
                                  
                                  return ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.deepPurple,
                                      child: Icon(Icons.directions_car, color: Colors.white),
                                    ),
                                    title: Text(
                                      placa,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      '$marca $modelo'.trim() + 
                                      (anio.isNotEmpty ? ' • $anio' : '') + 
                                      (color.isNotEmpty ? ' • $color' : '') + 
                                      (cliente.isNotEmpty ? ' • $cliente' : ''),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility),
                                          onPressed: () async {
                                            await Navigator.pushNamed(
                                              context,
                                              '/vehiculo-detalle',
                                              arguments: {'token': token, 'vehiculoId': v['id']},
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () async {
                                            final changed = await Navigator.pushNamed(
                                              context,
                                              '/vehiculo-form',
                                              arguments: {'token': token, 'vehiculoId': v['id']},
                                            );
                                            if (changed == true) {
                                              _load(search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim());
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Eliminar vehículo'),
                                                content: Text('¿Estás seguro de eliminar el vehículo "$placa"?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx, false),
                                                    child: const Text('Cancelar'),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                                    child: const Text('Eliminar'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              _delete(v['id'] as int);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final changed = await Navigator.pushNamed(context, '/vehiculo-form', arguments: {'token': token});
          if (changed == true) {
            _load(search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim());
          }
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }
}


