import 'package:flutter/material.dart';
import '../api/presupuestos_api.dart';

class PresupuestoFormPage extends StatefulWidget {
  const PresupuestoFormPage({super.key});

  @override
  State<PresupuestoFormPage> createState() => _PresupuestoFormPageState();
}

class _PresupuestoFormPageState extends State<PresupuestoFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _saving = false;
  String? _error;

  // Datos auxiliares
  List<dynamic> _clientes = [];
  List<dynamic> _vehiculos = [];
  List<dynamic> _items = [];

  // Formulario principal
  final TextEditingController _diagnosticoController = TextEditingController();
  String? _clienteId;
  String? _vehiculoId;
  String _estado = 'pendiente';
  bool _conImpuestos = false;
  final TextEditingController _impuestosController = TextEditingController(
    text: '13.00',
  );
  final TextEditingController _observacionesController =
      TextEditingController();
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();

  // Detalles del presupuesto
  List<Map<String, dynamic>> _detalles = [
    {
      'item': null,
      'cantidad': '1.00',
      'precio_unitario': '0.00',
      'descuento_porcentaje': '0.00',
    },
  ];

  // Totales calculados
  double _subtotal = 0.0;
  double _totalDescuentos = 0.0;
  double _montoImpuesto = 0.0;
  double _totalFinal = 0.0;

  // Variables para edición
  int? _presupuestoId;
  bool get _isEditing => _presupuestoId != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    // Calcular totales iniciales para evitar errores de tipo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateTotals();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['id'] != null) {
      _presupuestoId = args['id'] as int;
      _loadPresupuesto(_presupuestoId!);
    }
  }

  @override
  void dispose() {
    _diagnosticoController.dispose();
    _impuestosController.dispose();
    _observacionesController.dispose();
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        PresupuestosApi.fetchClientesForPresupuesto(),
        PresupuestosApi.fetchVehiculosForPresupuesto(),
        PresupuestosApi.fetchItemsForPresupuesto(),
      ]);

      setState(() {
        _clientes = results[0];
        _vehiculos = results[1];
        _items = results[2];
      });
    } catch (e) {
      setState(() => _error = 'Error al cargar datos: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadPresupuesto(int id) async {
    try {
      final data = await PresupuestosApi.fetchPresupuestoById(id);

      setState(() {
        _diagnosticoController.text = data['diagnostico'] ?? '';
        _clienteId = data['cliente']?.toString();
        _vehiculoId = data['vehiculo']?['id']?.toString();
        _estado = data['estado'] ?? 'pendiente';
        _conImpuestos = data['con_impuestos'] ?? false;
        _impuestosController.text = data['impuestos']?.toString() ?? '13.00';
        _observacionesController.text = data['observaciones'] ?? '';
        _fechaInicioController.text = data['fecha_inicio'] ?? '';
        _fechaFinController.text = data['fecha_fin'] ?? '';

        if (data['detalles'] != null && (data['detalles'] as List).isNotEmpty) {
          _detalles = (data['detalles'] as List).map((d) {
            return {
              'id': d['id'],
              'item': d['item']?['id']?.toString() ?? d['item']?.toString(),
              'cantidad': d['cantidad']?.toString() ?? '1.00',
              'precio_unitario': d['precio_unitario']?.toString() ?? '0.00',
              'descuento_porcentaje':
                  d['descuento_porcentaje']?.toString() ?? '0.00',
            };
          }).toList();
        }
      });

      _calculateTotals();
    } catch (e) {
      setState(() => _error = 'Error al cargar presupuesto: $e');
    }
  }

  void _calculateTotals() {
    double subtotal = 0.0;
    double totalDescuentos = 0.0;

    for (var detalle in _detalles) {
      final cantidadStr = detalle['cantidad']?.toString() ?? '0.0';
      final precioStr = detalle['precio_unitario']?.toString() ?? '0.0';
      final descStr = detalle['descuento_porcentaje']?.toString() ?? '0.0';

      final cantidad = double.tryParse(cantidadStr) ?? 0.0;
      final precio = double.tryParse(precioStr) ?? 0.0;
      final descPorcentaje = double.tryParse(descStr) ?? 0.0;

      final subtotalDetalle = cantidad * precio;
      final descuentoDetalle = subtotalDetalle * (descPorcentaje / 100);

      subtotal += subtotalDetalle;
      totalDescuentos += descuentoDetalle;
    }

    final subtotalConDescuentos = subtotal - totalDescuentos;
    final impuestoPorcentaje =
        double.tryParse(_impuestosController.text) ?? 0.0;
    final montoImpuesto = _conImpuestos
        ? subtotalConDescuentos * (impuestoPorcentaje / 100)
        : 0.0;
    final totalFinal = subtotalConDescuentos + montoImpuesto;

    setState(() {
      _subtotal = subtotal;
      _totalDescuentos = totalDescuentos;
      _montoImpuesto = montoImpuesto;
      _totalFinal = totalFinal;
    });
  }

  void _addDetalle() {
    setState(() {
      _detalles.add({
        'item': null,
        'cantidad': '1.00',
        'precio_unitario': '0.00',
        'descuento_porcentaje': '0.00',
      });
    });
  }

  void _removeDetalle(int index) {
    if (_detalles.length > 1) {
      setState(() {
        _detalles.removeAt(index);
      });
      _calculateTotals();
    }
  }

  void _updateDetalle(int index, String field, String value) {
    setState(() {
      _detalles[index][field] = value;
    });
    _calculateTotals();
  }

  void _onItemChanged(int index, String? itemId) {
    if (itemId != null) {
      final item = _items.firstWhere(
        (i) => i['id'].toString() == itemId,
        orElse: () => null,
      );

      if (item != null) {
        setState(() {
          _detalles[index]['item'] = itemId;
          _detalles[index]['precio_unitario'] =
              item['precio']?.toString() ?? '0.00';
        });
        _calculateTotals();
      }
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        controller.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_detalles.any((d) => d['item'] == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los detalles deben tener un item seleccionado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final payload = {
        'diagnostico': _diagnosticoController.text,
        'fecha_inicio': _fechaInicioController.text.isEmpty
            ? null
            : _fechaInicioController.text,
        'fecha_fin': _fechaFinController.text.isEmpty
            ? null
            : _fechaFinController.text,
        'estado': _estado,
        'con_impuestos': _conImpuestos,
        'impuestos': _impuestosController.text,
        'observaciones': _observacionesController.text,
        'cliente': _clienteId,
        'vehiculo_id': _vehiculoId,
        'detalles': _detalles.map((d) {
          return {
            if (d['id'] != null) 'id': d['id'],
            'item_id': d['item'],
            'cantidad': d['cantidad'],
            'precio_unitario': d['precio_unitario'],
            'descuento_porcentaje': d['descuento_porcentaje'],
          };
        }).toList(),
      };

      if (_isEditing) {
        await PresupuestosApi.updatePresupuesto(_presupuestoId!, payload);
      } else {
        await PresupuestosApi.createPresupuesto(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Presupuesto actualizado correctamente'
                  : 'Presupuesto creado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _error = 'Error al guardar: $e';
        _saving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al ${_isEditing ? "actualizar" : "crear"} presupuesto: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(2);
  }

  List<dynamic> get _vehiculosFiltrados {
    // Mostrar TODOS los vehículos para permitir selección libre
    return _vehiculos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Presupuesto' : 'Nuevo Presupuesto'),
        elevation: 2,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Error al cargar datos: $_error',
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),

                  // Información General
                  _buildSection('Información General', [
                    TextFormField(
                      controller: _diagnosticoController,
                      decoration: const InputDecoration(
                        labelText: 'Diagnóstico',
                        border: OutlineInputBorder(),
                        hintText: 'Describa el diagnóstico del vehículo',
                      ),
                      maxLines: 3,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _estado,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'pendiente',
                          child: Text('Pendiente'),
                        ),
                        DropdownMenuItem(
                          value: 'aprobado',
                          child: Text('Aprobado'),
                        ),
                        DropdownMenuItem(
                          value: 'rechazado',
                          child: Text('Rechazado'),
                        ),
                        DropdownMenuItem(
                          value: 'cancelado',
                          child: Text('Cancelado'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _estado = v!),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                _selectDate(context, _fechaInicioController),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha Inicio',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _fechaInicioController.text.isEmpty
                                    ? 'Seleccionar fecha'
                                    : _fechaInicioController.text,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                _selectDate(context, _fechaFinController),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha Fin',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _fechaFinController.text.isEmpty
                                    ? 'Seleccionar fecha'
                                    : _fechaFinController.text,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Información del Cliente
                  _buildSection('Información del Cliente', [
                    DropdownButtonFormField<String>(
                      value: _clienteId,
                      decoration: const InputDecoration(
                        labelText: 'Cliente *',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Seleccionar cliente'),
                        ),
                        ..._clientes.map((c) {
                          return DropdownMenuItem(
                            value: c['id'].toString(),
                            child: Text('${c['nombre']} ${c['apellido']}'),
                          );
                        }).toList(),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _clienteId = v;
                          // NO resetear vehículo, permitir selección libre
                        });
                      },
                      validator: (v) =>
                          v == null ? 'Seleccione un cliente' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _vehiculoId,
                      decoration: const InputDecoration(
                        labelText: 'Vehículo (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Sin vehículo asignado'),
                        ),
                        ..._vehiculosFiltrados.map((v) {
                          // Usar los campos _nombre que vienen del backend
                          final marca = v['marca_nombre']?.toString() ?? '';
                          final modelo = v['modelo_nombre']?.toString() ?? '';
                          final placa =
                              v['numero_placa']?.toString() ??
                              v['placa']?.toString() ??
                              'S/N';

                          return DropdownMenuItem(
                            value: v['id'].toString(),
                            child: Text('$marca $modelo - $placa'),
                          );
                        }).toList(),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _vehiculoId = v;
                        });
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Detalles del Presupuesto
                  _buildSection('Detalles del Presupuesto', [
                    ..._detalles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final detalle = entry.value;

                      final cantidadStr =
                          detalle['cantidad']?.toString() ?? '0.0';
                      final precioStr =
                          detalle['precio_unitario']?.toString() ?? '0.0';
                      final descStr =
                          detalle['descuento_porcentaje']?.toString() ?? '0.0';

                      final cantidad = double.tryParse(cantidadStr) ?? 0.0;
                      final precio = double.tryParse(precioStr) ?? 0.0;
                      final desc = double.tryParse(descStr) ?? 0.0;
                      final subtotalItem = cantidad * precio * (1 - desc / 100);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Item ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (_detalles.length > 1)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeDetalle(index),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: detalle['item'],
                                decoration: const InputDecoration(
                                  labelText: 'Seleccionar Item *',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Seleccionar...'),
                                  ),
                                  ..._items.map((item) {
                                    return DropdownMenuItem(
                                      value: item['id'].toString(),
                                      child: Text(item['nombre']),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (v) => _onItemChanged(index, v),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: detalle['cantidad'],
                                      decoration: const InputDecoration(
                                        labelText: 'Cantidad',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) =>
                                          _updateDetalle(index, 'cantidad', v),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: detalle['precio_unitario'],
                                      decoration: const InputDecoration(
                                        labelText: 'Precio Unit.',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => _updateDetalle(
                                        index,
                                        'precio_unitario',
                                        v,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue:
                                          detalle['descuento_porcentaje'],
                                      decoration: const InputDecoration(
                                        labelText: 'Desc. (%)',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => _updateDetalle(
                                        index,
                                        'descuento_porcentaje',
                                        v,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Subtotal: ${_formatCurrency(subtotalItem)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    ElevatedButton.icon(
                      onPressed: _addDetalle,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Impuestos y Totales
                  _buildSection('Impuestos y Totales', [
                    CheckboxListTile(
                      title: const Text('Aplicar impuestos'),
                      value: _conImpuestos,
                      onChanged: (v) {
                        setState(() => _conImpuestos = v!);
                        _calculateTotals();
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (_conImpuestos)
                      TextFormField(
                        controller: _impuestosController,
                        decoration: const InputDecoration(
                          labelText: 'Porcentaje de Impuesto (%)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _calculateTotals(),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _observacionesController,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildTotalsCard(),
                  ]),

                  const SizedBox(height: 24),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isEditing
                                      ? 'Actualizar Presupuesto'
                                      : 'Guardar Presupuesto',
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTotalsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal:', _subtotal, bold: true),
          if (_totalDescuentos > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow(
              'Descuentos:',
              -_totalDescuentos,
              color: Colors.red,
              bold: true,
            ),
          ],
          if (_conImpuestos && _montoImpuesto > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow(
              'IVA (${_impuestosController.text}%):',
              _montoImpuesto,
              color: Colors.blue,
              bold: true,
            ),
          ],
          const Divider(height: 24),
          _buildTotalRow(
            'Total Final:',
            _totalFinal,
            fontSize: 18,
            color: Colors.green,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double value, {
    Color? color,
    double? fontSize,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.bold : null,
            color: color,
          ),
        ),
        Text(
          '${value < 0 ? '-' : ''}Bs. ${_formatCurrency(value.abs())}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.bold : null,
            color: color,
          ),
        ),
      ],
    );
  }
}
