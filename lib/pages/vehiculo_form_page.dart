import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/vehiculo_service.dart';
import '../services/cliente_service.dart';

class VehiculoFormPage extends StatefulWidget {
  const VehiculoFormPage({super.key});

  @override
  State<VehiculoFormPage> createState() => _VehiculoFormPageState();
}

class _VehiculoFormPageState extends State<VehiculoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final VehiculoService _service = VehiculoService();
  final ClienteService _clienteService = ClienteService();

  String? token;
  Map<String, dynamic>? vehiculo;
  int? vehiculoId;
  bool _initialized = false;

  // Campos
  final TextEditingController placaCtrl = TextEditingController();
  final TextEditingController vinCtrl = TextEditingController();
  final TextEditingController motorCtrl = TextEditingController();
  final TextEditingController versionCtrl = TextEditingController();
  final TextEditingController colorCtrl = TextEditingController();
  final TextEditingController tipoCtrl = TextEditingController();
  final TextEditingController cilindradaCtrl = TextEditingController();
  final TextEditingController anioCtrl = TextEditingController();
  final TextEditingController combustibleCtrl = TextEditingController();

  int? clienteId;
  int? marcaId;
  int? modeloId;
  List<dynamic> marcas = [];
  List<dynamic> modelos = [];
  List<dynamic> clientes = [];
  bool loadingModelos = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    // Leer argumentos después del primer frame y cargar una sola vez
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialized) return;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        token = args['token'] as String?;
        vehiculoId = args['vehiculoId'] as int?;
        vehiculo = args['vehiculo'] as Map<String, dynamic>?;
      }
      _initialized = true;
      _init();
    });
  }

  Future<void> _init() async {
    setState(() => loading = true);
    try {
      marcas = await _service.fetchMarcas(token: token);
      clientes = await _clienteService.fetchAll(token: token);
      // Si se recibió solo el ID, obtener detalle para precargar datos
      if (vehiculo == null && vehiculoId != null) {
        vehiculo = await _service.fetchById(vehiculoId!, token: token);
      }
      if (vehiculo != null) {
        placaCtrl.text = vehiculo!['numero_placa'] ?? '';
        vinCtrl.text = vehiculo!['vin'] ?? '';
        motorCtrl.text = vehiculo!['numero_motor'] ?? '';
        versionCtrl.text = vehiculo!['version'] ?? '';
        colorCtrl.text = vehiculo!['color'] ?? '';
        tipoCtrl.text = vehiculo!['tipo'] ?? '';
        cilindradaCtrl.text = vehiculo!['cilindrada']?.toString() ?? '';
        anioCtrl.text = vehiculo!['año']?.toString() ?? '';
        combustibleCtrl.text = vehiculo!['tipo_combustible'] ?? '';
        clienteId = vehiculo!['cliente'] is Map ? vehiculo!['cliente']['id'] : vehiculo!['cliente'];
        marcaId = vehiculo!['marca'] is Map ? vehiculo!['marca']['id'] : vehiculo!['marca'];
        modeloId = vehiculo!['modelo'] is Map ? vehiculo!['modelo']['id'] : vehiculo!['modelo'];
      }
      loadingModelos = true;
      modelos = await _service.fetchModelos(marcaId: marcaId, token: token);
      loadingModelos = false;
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    final body = {
      'numero_placa': placaCtrl.text.trim(),
      'vin': vinCtrl.text.trim().isEmpty ? null : vinCtrl.text.trim(),
      'numero_motor': motorCtrl.text.trim().isEmpty ? null : motorCtrl.text.trim(),
      'version': versionCtrl.text.trim().isEmpty ? null : versionCtrl.text.trim(),
      'color': colorCtrl.text.trim().isEmpty ? null : colorCtrl.text.trim(),
      'tipo': tipoCtrl.text.trim().isEmpty ? null : tipoCtrl.text.trim(),
      'cilindrada': cilindradaCtrl.text.trim().isEmpty ? null : int.tryParse(cilindradaCtrl.text.trim()),
      'año': anioCtrl.text.trim().isEmpty ? null : int.tryParse(anioCtrl.text.trim()),
      'tipo_combustible': combustibleCtrl.text.trim().isEmpty ? null : combustibleCtrl.text.trim(),
      'cliente': clienteId,
      'marca': marcaId,
      'modelo': modeloId,
    }..removeWhere((key, value) => value == null);

    Map<String, dynamic> res;
    if (vehiculo != null && vehiculo!['id'] != null) {
      res = await _service.updateVehiculo(vehiculo!['id'] as int, body, token: token);
    } else {
      res = await _service.createVehiculo(body, token: token);
    }
    setState(() => loading = false);

    final status = res['status'] as int? ?? 0;
    if (status >= 200 && status < 300) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vehiculo == null ? 'Vehículo creado' : 'Vehículo actualizado')),
        );
        Navigator.pop(context, true);
      }
    } else {
      try {
        final body = jsonDecode(res['body'] as String);
        final msg = body is Map && body.values.isNotEmpty ? body.values.first.toString() : res['body'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $msg')));
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res['body']}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = vehiculo != null && vehiculo!['id'] != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Editar vehículo' : 'Nuevo vehículo')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: placaCtrl,
                      decoration: const InputDecoration(labelText: 'Número de placa *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                      textInputAction: TextInputAction.next,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: vinCtrl,
                      decoration: const InputDecoration(labelText: 'VIN', border: OutlineInputBorder()),
                      textInputAction: TextInputAction.next,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: motorCtrl,
                      decoration: const InputDecoration(labelText: 'Número motor', border: OutlineInputBorder()),
                      textInputAction: TextInputAction.next,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: clienteId,
                      items: [
                        for (final c in clientes)
                          DropdownMenuItem<int>(
                            value: c['id'] as int,
                            child: Text((
                              ((c['nombre'] ?? '') + ' ' + (c['apellido'] ?? '')).trim().isNotEmpty
                                  ? ((c['nombre'] ?? '') + ' ' + (c['apellido'] ?? '')).trim()
                                  : (c['nit'] ?? '-').toString()
                            )),
                          ),
                      ],
                      onChanged: (val) => setState(() => clienteId = val),
                      decoration: const InputDecoration(labelText: 'Cliente', border: OutlineInputBorder()),
                      menuMaxHeight: 320,
                      isDense: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: marcaId,
                            items: [
                              for (final m in marcas)
                                DropdownMenuItem<int>(value: m['id'] as int, child: Text(m['nombre'] ?? '-')),
                            ],
                            onChanged: (val) async {
                              setState(() { marcaId = val; modeloId = null; modelos = []; loadingModelos = true; });
                              final fetched = await _service.fetchModelos(marcaId: marcaId, token: token);
                              if (!mounted) return;
                              setState(() { modelos = fetched; loadingModelos = false; });
                            },
                            decoration: const InputDecoration(labelText: 'Marca', border: OutlineInputBorder()),
                            isDense: true,
                            menuMaxHeight: 320,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: modeloId,
                            items: loadingModelos
                                ? const []
                                : [
                                    for (final mo in modelos)
                                      DropdownMenuItem<int>(value: mo['id'] as int, child: Text(mo['nombre'] ?? '-')),
                                  ],
                            onChanged: loadingModelos ? null : (val) => setState(() => modeloId = val),
                            decoration: InputDecoration(
                              labelText: loadingModelos ? 'Modelo (cargando...)' : 'Modelo',
                              border: const OutlineInputBorder(),
                            ),
                            isDense: true,
                            menuMaxHeight: 320,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: versionCtrl,
                      decoration: const InputDecoration(labelText: 'Versión', border: OutlineInputBorder()),
                      textInputAction: TextInputAction.next,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: colorCtrl,
                            decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder()),
                            textInputAction: TextInputAction.next,
                            onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: anioCtrl,
                            decoration: const InputDecoration(labelText: 'Año', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: tipoCtrl.text.isEmpty ? null : tipoCtrl.text,
                            items: const [
                              DropdownMenuItem(value: 'CAMIONETA', child: Text('Camioneta')),
                              DropdownMenuItem(value: 'DEPORTIVO', child: Text('Deportivo')),
                              DropdownMenuItem(value: 'FURGON', child: Text('Furgón')),
                              DropdownMenuItem(value: 'HATCHBACK', child: Text('Hatchback')),
                              DropdownMenuItem(value: 'SEDAN', child: Text('Sedán')),
                              DropdownMenuItem(value: 'SUV', child: Text('SUV')),
                              DropdownMenuItem(value: 'CITYCAR', child: Text('CityCar')),
                            ],
                            onChanged: (val) => setState(() => tipoCtrl.text = val ?? ''),
                            decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                            isDense: true,
                            menuMaxHeight: 320,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: cilindradaCtrl,
                            decoration: const InputDecoration(labelText: 'Cilindrada', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: combustibleCtrl.text.isEmpty ? null : combustibleCtrl.text,
                      items: const [
                        DropdownMenuItem(value: 'Gasolina', child: Text('Gasolina')),
                        DropdownMenuItem(value: 'Diésel', child: Text('Diésel')),
                        DropdownMenuItem(value: 'Gas (GNV/GLP)', child: Text('Gas (GNV/GLP)')),
                        DropdownMenuItem(value: 'Híbrido', child: Text('Híbrido')),
                        DropdownMenuItem(value: 'Eléctrico', child: Text('Eléctrico')),
                        DropdownMenuItem(value: 'Flex', child: Text('Flex')),
                      ],
                      onChanged: (val) => setState(() => combustibleCtrl.text = val ?? ''),
                      decoration: const InputDecoration(labelText: 'Tipo de combustible', border: OutlineInputBorder()),
                      isDense: true,
                      menuMaxHeight: 320,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: loading ? null : _save,
                      child: Text(editing ? 'Guardar cambios' : 'Crear vehículo'),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}


