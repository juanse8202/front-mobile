import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/presupuestos_api.dart';
import '../services/orden_trabajo_service.dart';
import '../services/cliente_service.dart';
import '../services/vehiculo_service.dart';

class CrearOrdenPage extends StatefulWidget {
  const CrearOrdenPage({super.key});

  @override
  State<CrearOrdenPage> createState() => _CrearOrdenPageState();
}

class _CrearOrdenPageState extends State<CrearOrdenPage> {
  final _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final OrdenTrabajoService _ordenService = OrdenTrabajoService();
  final ClienteService _clienteService = ClienteService();
  final VehiculoService _vehiculoService = VehiculoService();

  List<dynamic> _clientes = [];
  List<dynamic> _vehiculos = [];
  List<dynamic> _vehiculosFiltrados = [];
  List<dynamic> _marcas = [];
  List<dynamic> _modelos = [];

  int? _clienteSeleccionado;
  int? _vehiculoSeleccionado;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'access_token');
      
      // Cargar desde dos endpoints diferentes para comparar
      final clientes = await PresupuestosApi.fetchClientesForPresupuesto();
      
      // Intentar cargar vehículos desde VehiculoService
      final vehiculosService = await _vehiculoService.fetchAll(token: token);
      print('🚗 VEHÍCULOS desde VehiculoService: ${vehiculosService.length}');
      if (vehiculosService.isNotEmpty) {
        print('📋 Primer vehículo: ${vehiculosService[0]}');
        // Verificar si es un Map para evitar errores
        if (vehiculosService[0] is Map) {
          final vehiculoMap = vehiculosService[0] as Map<String, dynamic>;
          print('📋 Campos disponibles: ${vehiculoMap.keys.join(", ")}');
        }
      }
      
      final marcas = await _vehiculoService.fetchMarcas(token: token);
      
      print('✅ Clientes cargados: ${clientes.length}');
      print('✅ Vehículos cargados: ${vehiculosService.length}');
      
      setState(() {
        _clientes = clientes;
        _vehiculos = vehiculosService;
        _vehiculosFiltrados = [];
        _marcas = marcas;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ ERROR al cargar datos: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filtrarVehiculosPorCliente(int? clienteId) {
    if (clienteId == null) {
      setState(() {
        _vehiculosFiltrados = [];
        _vehiculoSeleccionado = null;
      });
      return;
    }

    print('🔍 Filtrando vehículos para cliente ID: $clienteId');
    print('📦 Total vehículos disponibles: ${_vehiculos.length}');
    
    // Buscar el nombre del cliente seleccionado
    final clienteSeleccionado = _clientes.firstWhere(
      (c) => c['id'] == clienteId,
      orElse: () => <String, dynamic>{},
    );
    
    print('👤 Cliente seleccionado completo: $clienteSeleccionado');
    
    // El cliente puede tener 'nombre' solo, o 'nombre' y 'apellido'
    final nombreCliente = clienteSeleccionado['nombre'] ?? '';
    final apellidoCliente = clienteSeleccionado['apellido'] ?? '';
    final nombreCompletoCliente = '$nombreCliente $apellidoCliente'.trim().toLowerCase();
    
    print('👤 Nombre a buscar: "$nombreCompletoCliente"');
    
    // Verificar el primer vehículo
    if (_vehiculos.isNotEmpty) {
      print('📋 Ejemplo vehículo: ${_vehiculos[0]}');
      print('📋 cliente_nombre del primer vehículo: "${_vehiculos[0]['cliente_nombre']}"');
    }

    final vehiculosFiltrados = _vehiculos.where((v) {
      final clienteNombreVehiculo = (v['cliente_nombre'] ?? '').toString().toLowerCase().trim();
      
      // Intentar varias formas de match
      final matchCompleto = clienteNombreVehiculo == nombreCompletoCliente;
      final matchParcial = clienteNombreVehiculo.contains(nombreCliente.toLowerCase());
      final matchInverso = nombreCompletoCliente.contains(clienteNombreVehiculo);
      
      final match = matchCompleto || matchParcial || matchInverso;
      
      if (match) {
        print('✅ Vehículo encontrado: ${v['numero_placa']} - cliente: "$clienteNombreVehiculo" (match: completo=$matchCompleto, parcial=$matchParcial, inverso=$matchInverso)');
      } else {
        print('❌ No match: vehiculo="$clienteNombreVehiculo" vs cliente="$nombreCompletoCliente"');
      }
      
      return match;
    }).toList();

    print('✅ Vehículos filtrados: ${vehiculosFiltrados.length}');

    setState(() {
      _vehiculosFiltrados = vehiculosFiltrados;
      // Si el vehículo seleccionado ya no está en la lista filtrada, deseleccionarlo
      if (_vehiculoSeleccionado != null &&
          !vehiculosFiltrados.any((v) => v['id'] == _vehiculoSeleccionado)) {
        _vehiculoSeleccionado = null;
      }
    });
  }

  Future<void> _crearOrden() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clienteSeleccionado == null || _vehiculoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un cliente y un vehículo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final token = await _storage.read(key: 'access_token');

      final body = {
        'cliente': _clienteSeleccionado,
        'vehiculo': _vehiculoSeleccionado,
        'estado': 'pendiente',
      };

      print('📦 Creando orden con datos: ${jsonEncode(body)}');

      await _ordenService.createOrden(body, token: token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden de trabajo creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear orden: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _mostrarDialogoNuevoCliente() async {
    final nombreController = TextEditingController();
    final apellidoController = TextEditingController();
    final nitController = TextEditingController();
    final telefonoController = TextEditingController();
    final direccionController = TextEditingController();
    String tipoCliente = 'NATURAL';

    await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo Cliente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: apellidoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nitController,
                  decoration: const InputDecoration(
                    labelText: 'NIT *',
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tipoCliente,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Cliente',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'NATURAL', child: Text('Persona Natural')),
                    DropdownMenuItem(value: 'EMPRESA', child: Text('Empresa')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      tipoCliente = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.isEmpty ||
                    apellidoController.text.isEmpty ||
                    nitController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor completa los campos requeridos (Nombre, Apellido, NIT)'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                try {
                  final token = await _storage.read(key: 'access_token');
                  final body = {
                    'nombre': nombreController.text,
                    'apellido': apellidoController.text,
                    'nit': nitController.text,
                    'tipo_cliente': tipoCliente,
                    if (telefonoController.text.isNotEmpty) 'telefono': telefonoController.text,
                    if (direccionController.text.isNotEmpty) 'direccion': direccionController.text,
                  };

                  final response = await _clienteService.createCliente(body, token: token);

                  if (response['status'] >= 200 && response['status'] < 300) {
                    final nuevoCliente = jsonDecode(response['body']);
                    if (mounted) {
                      setState(() {
                        _clientes.add(nuevoCliente);
                        _clienteSeleccionado = nuevoCliente['id'];
                        _filtrarVehiculosPorCliente(_clienteSeleccionado);
                      });
                      Navigator.pop(context, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cliente creado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    throw Exception(response['body']);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al crear cliente: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoNuevoVehiculo() async {
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero debes seleccionar un cliente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final placaController = TextEditingController();
    final anioController = TextEditingController();
    final colorController = TextEditingController();
    final vinController = TextEditingController();
    final numeroMotorController = TextEditingController();
    final cilindradaController = TextEditingController();
    
    int? marcaSeleccionada;
    int? modeloSeleccionado;
    String? tipoVehiculo;
    String? tipoCombustible;

    await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo Vehículo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: placaController,
                  decoration: const InputDecoration(
                    labelText: 'Placa *',
                    prefixIcon: Icon(Icons.pin),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: marcaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Marca *',
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  items: _marcas.map((marca) {
                    return DropdownMenuItem<int>(
                      value: marca['id'],
                      child: Text(marca['nombre']),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    setDialogState(() {
                      marcaSeleccionada = value;
                      modeloSeleccionado = null;
                    });
                    if (value != null) {
                      try {
                        final token = await _storage.read(key: 'access_token');
                        final modelos = await _vehiculoService.fetchModelos(marcaId: value, token: token);
                        setDialogState(() {
                          _modelos = modelos;
                        });
                      } catch (e) {
                        print('Error al cargar modelos: $e');
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: modeloSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Modelo *',
                    prefixIcon: Icon(Icons.style),
                  ),
                  items: _modelos.map((modelo) {
                    return DropdownMenuItem<int>(
                      value: modelo['id'],
                      child: Text(modelo['nombre']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      modeloSeleccionado = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: anioController,
                  decoration: const InputDecoration(
                    labelText: 'Año',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(
                    labelText: 'Color',
                    prefixIcon: Icon(Icons.color_lens),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tipoVehiculo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Vehículo',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'CAMIONETA', child: Text('Camioneta')),
                    DropdownMenuItem(value: 'DEPORTIVO', child: Text('Deportivo')),
                    DropdownMenuItem(value: 'FURGON', child: Text('Furgón')),
                    DropdownMenuItem(value: 'HATCHBACK', child: Text('Hatchback')),
                    DropdownMenuItem(value: 'SEDAN', child: Text('Sedán')),
                    DropdownMenuItem(value: 'SUV', child: Text('SUV')),
                    DropdownMenuItem(value: 'CITYCAR', child: Text('CityCar')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      tipoVehiculo = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: vinController,
                  decoration: const InputDecoration(
                    labelText: 'VIN',
                    prefixIcon: Icon(Icons.numbers),
                    hintText: 'Número de identificación',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numeroMotorController,
                  decoration: const InputDecoration(
                    labelText: 'Número de Motor',
                    prefixIcon: Icon(Icons.settings),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cilindradaController,
                  decoration: const InputDecoration(
                    labelText: 'Cilindrada',
                    prefixIcon: Icon(Icons.speed),
                    hintText: 'Ej: 1600cc',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tipoCombustible,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Combustible',
                    prefixIcon: Icon(Icons.local_gas_station),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'GASOLINA', child: Text('Gasolina')),
                    DropdownMenuItem(value: 'DIESEL', child: Text('Diesel')),
                    DropdownMenuItem(value: 'GAS_NATURAL', child: Text('Gas Natural')),
                    DropdownMenuItem(value: 'ELECTRICO', child: Text('Eléctrico')),
                    DropdownMenuItem(value: 'HIBRIDO', child: Text('Híbrido')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      tipoCombustible = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (placaController.text.isEmpty ||
                    marcaSeleccionada == null ||
                    modeloSeleccionado == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor completa los campos requeridos'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                try {
                  final token = await _storage.read(key: 'access_token');
                  final body = {
                    'numero_placa': placaController.text.toUpperCase(),
                    'marca': marcaSeleccionada,
                    'modelo': modeloSeleccionado,
                    'cliente': _clienteSeleccionado,
                    if (anioController.text.isNotEmpty) 'año': int.parse(anioController.text),
                    if (colorController.text.isNotEmpty) 'color': colorController.text,
                    if (tipoVehiculo != null) 'tipo': tipoVehiculo,
                    if (vinController.text.isNotEmpty) 'vin': vinController.text.toUpperCase(),
                    if (numeroMotorController.text.isNotEmpty) 'numero_motor': numeroMotorController.text.toUpperCase(),
                    if (cilindradaController.text.isNotEmpty) 'cilindrada': cilindradaController.text,
                    if (tipoCombustible != null) 'tipo_combustible': tipoCombustible,
                  };

                  final response = await _vehiculoService.createVehiculo(body, token: token);

                  if (response['status'] >= 200 && response['status'] < 300) {
                    final nuevoVehiculo = jsonDecode(response['body']);
                    if (mounted) {
                      setState(() {
                        _vehiculos.add(nuevoVehiculo);
                        _filtrarVehiculosPorCliente(_clienteSeleccionado);
                        _vehiculoSeleccionado = nuevoVehiculo['id'];
                      });
                      Navigator.pop(context, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vehículo creado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    throw Exception(response['body']);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al crear vehículo: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Orden de Trabajo'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSeccionCliente(),
                    const SizedBox(height: 16),
                    _buildSeccionVehiculo(),
                    const SizedBox(height: 24),
                    _buildBotonCrear(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSeccionCliente() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cliente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _mostrarDialogoNuevoCliente,
                  icon: const Icon(Icons.add_circle, size: 20),
                  label: const Text('Nuevo'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _clienteSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Seleccionar Cliente *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              items: _clientes.map((cliente) {
                return DropdownMenuItem<int>(
                  value: cliente['id'],
                  child: Text(
                    '${cliente['nombre']} - CI: ${cliente['ci']}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _clienteSeleccionado = value;
                  _filtrarVehiculosPorCliente(value);
                });
              },
              validator: (value) {
                if (value == null) return 'Por favor selecciona un cliente';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionVehiculo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vehículo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _clienteSeleccionado == null ? null : _mostrarDialogoNuevoVehiculo,
                  icon: const Icon(Icons.add_circle, size: 20),
                  label: const Text('Nuevo'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_clienteSeleccionado == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Primero selecciona un cliente',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              )
            else if (_vehiculosFiltrados.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este cliente no tiene vehículos registrados. Crea uno nuevo.',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<int>(
                value: _vehiculoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Vehículo *',
                  prefixIcon: Icon(Icons.directions_car),
                  border: OutlineInputBorder(),
                ),
                items: _vehiculosFiltrados.map((vehiculo) {
                  return DropdownMenuItem<int>(
                    value: vehiculo['id'],
                    child: Text(
                      '${vehiculo['numero_placa']} - ${vehiculo['marca_nombre']} ${vehiculo['modelo_nombre']}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _vehiculoSeleccionado = value;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Por favor selecciona un vehículo';
                  return null;
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonCrear() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _crearOrden,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Crear Orden de Trabajo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
