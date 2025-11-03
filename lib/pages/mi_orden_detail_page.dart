import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/orden_trabajo_service.dart';

class MiOrdenDetailPage extends StatefulWidget {
  final int ordenId;

  const MiOrdenDetailPage({super.key, required this.ordenId});

  @override
  State<MiOrdenDetailPage> createState() => _MiOrdenDetailPageState();
}

class _MiOrdenDetailPageState extends State<MiOrdenDetailPage> with SingleTickerProviderStateMixin {
  final OrdenTrabajoService _ordenService = OrdenTrabajoService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  Map<String, dynamic>? _orden;
  bool _isLoading = true;
  String? _error;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadOrdenDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrdenDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _storage.read(key: 'access_token');
      final orden = await _ordenService.fetchById(widget.ordenId, token: token);
      
      setState(() {
        _orden = orden;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getEstadoLabel(String? estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_proceso':
        return 'En Proceso';
      case 'finalizada':
        return 'Finalizada';
      case 'entregada':
        return 'Entregada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return 'Desconocido';
    }
  }

  Color _getEstadoColor(String? estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'en_proceso':
        return Colors.blue;
      case 'finalizada':
        return Colors.green;
      case 'entregada':
        return Colors.teal;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orden #${widget.ordenId}'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrdenDetail,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'General', icon: Icon(Icons.info_outline, size: 20)),
            Tab(text: 'Detalles', icon: Icon(Icons.receipt_long, size: 20)),
            Tab(text: 'Vehículo', icon: Icon(Icons.directions_car, size: 20)),
            Tab(text: 'Notas', icon: Icon(Icons.note, size: 20)),
            Tab(text: 'Tareas', icon: Icon(Icons.check_box, size: 20)),
            Tab(text: 'Técnicos', icon: Icon(Icons.people, size: 20)),
            Tab(text: 'Imágenes', icon: Icon(Icons.photo_library, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOrdenDetail,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGeneralTab(),
                    _buildDetallesListTab(),
                    _buildVehiculoTab(),
                    _buildNotasTab(),
                    _buildTareasTab(),
                    _buildTecnicosTab(),
                    _buildImagenesTab(),
                  ],
                ),
    );
  }

  Widget _buildGeneralTab() {
    // Extraer valores de forma segura sin casting forzado
    final vehiculoPlaca = _orden?['vehiculo_numero_placa']?.toString() ?? 
                          _orden?['vehiculo_placa']?.toString() ?? 
                          _orden?['numero_placa']?.toString();
    final vehiculoMarca = _orden?['vehiculo_marca']?.toString() ?? _orden?['marca_nombre']?.toString();
    final vehiculoModelo = _orden?['vehiculo_modelo']?.toString() ?? _orden?['modelo_nombre']?.toString();
    final kilometraje = _orden?['kilometraje'];
    final nivelCombustible = _orden?['nivel_combustible']?.toString();
    final clienteNombre = _orden?['cliente_nombre']?.toString();
    final clienteEmail = _orden?['cliente_email']?.toString();
    final clienteTelefono = _orden?['cliente_telefono']?.toString();
    final falloRequerimiento = _orden?['fallo_requerimiento']?.toString();
    final observaciones = _orden?['observaciones']?.toString();
    final fechaCreacion = _orden?['fecha_creacion'];
    final fechaEstimada = _orden?['fecha_estimada'];
    final fechaEntrega = _orden?['fecha_entrega'];
    
    // Formatear valores
    final kilometrajeStr = kilometraje != null ? '$kilometraje km' : null;
    final fechaCreacionStr = fechaCreacion != null ? fechaCreacion.toString().split('T')[0] : null;
    final fechaEstimadaStr = fechaEstimada != null ? fechaEstimada.toString().split('T')[0] : null;
    final fechaEntregaStr = fechaEntrega != null ? fechaEntrega.toString().split('T')[0] : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(
                Icons.circle,
                color: _getEstadoColor(_orden?['estado']),
              ),
              title: const Text('Estado', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_getEstadoLabel(_orden?['estado'])),
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionTitle('Cliente'),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReadOnlyField('Nombre', clienteNombre),
                  const SizedBox(height: 8),
                  _buildReadOnlyField('Email', clienteEmail),
                  const SizedBox(height: 8),
                  _buildReadOnlyField('Teléfono', clienteTelefono),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionTitle('Vehículo'),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReadOnlyField('Placa', vehiculoPlaca),
                  const SizedBox(height: 8),
                  _buildReadOnlyField('Marca', vehiculoMarca),
                  const SizedBox(height: 8),
                  _buildReadOnlyField('Modelo', vehiculoModelo),
                  const SizedBox(height: 8),
                  _buildReadOnlyField('Kilometraje', kilometrajeStr),
                  const SizedBox(height: 8),
                  _buildReadOnlyField('Nivel Combustible', nivelCombustible),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionTitle('Detalles de la Orden'),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReadOnlyField('Fallo/Requerimiento', falloRequerimiento),
                  const SizedBox(height: 8),
                  _buildReadOnlyField('Observaciones', observaciones),
                  const SizedBox(height: 8),
                  _buildReadOnlyField('Fecha de Creación', fechaCreacionStr),
                  const SizedBox(height: 8),
                  _buildReadOnlyField('Fecha Estimada', fechaEstimadaStr),
                  if (fechaEntrega != null) ...[
                    const SizedBox(height: 8),
                    _buildReadOnlyField('Fecha de Entrega', fechaEntregaStr),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionTitle('Totales'),
          Card(
            elevation: 2,
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTotalRow('Subtotal', _parseDouble(_orden?['subtotal'])),
                  const Divider(),
                  _buildTotalRow('Descuento', _parseDouble(_orden?['descuento'])),
                  const Divider(),
                  _buildTotalRow('IVA (13%)', _parseDouble(_orden?['iva'])),
                  const Divider(thickness: 2),
                  _buildTotalRow('TOTAL', _parseDouble(_orden?['total']), isTotal: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetallesListTab() {
    final detalles = _orden?['detalles'] as List<dynamic>? ?? [];

    if (detalles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay artículos en esta orden', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: detalles.length,
      itemBuilder: (context, index) {
        final detalle = detalles[index];
        return _buildDetalleCard(detalle);
      },
    );
  }

  Widget _buildDetalleCard(Map<String, dynamic> detalle) {
    // Obtener el nombre del item (igual que en orden_detail_page.dart)
    final nombreItem = detalle['nombre_item'] ?? 
                       detalle['item_nombre'] ?? 
                       detalle['nombre'] ?? 
                       'Item sin nombre';
    
    final cantidad = detalle['cantidad'] ?? 0;
    final precioUnitario = _parseDouble(detalle['precio_unitario']);
    final descuentoPorcentaje = _parseDouble(detalle['descuento_porcentaje'] ?? 0);
    final descuento = _parseDouble(detalle['descuento'] ?? 0);
    final subtotal = _parseDouble(detalle['subtotal']);
    final total = _parseDouble(detalle['total']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    nombreItem,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cantidad: $cantidad', style: const TextStyle(color: Colors.grey)),
                Text(
                  'Precio Unit: \$${precioUnitario.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            if (descuentoPorcentaje > 0 || descuento > 0) ...[
              const SizedBox(height: 4),
              Text(
                descuentoPorcentaje > 0
                    ? 'Descuento: ${descuentoPorcentaje.toStringAsFixed(0)}% (-\$${descuento.toStringAsFixed(2)})'
                    : 'Descuento: -\$${descuento.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.green, fontSize: 12),
              ),
            ],
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                Text(
                  '\$${subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotasTab() {
    final notas = _orden?['notas'] as List<dynamic>? ?? [];

    if (notas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notes_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay notas en esta orden', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: notas.length,
      itemBuilder: (context, index) {
        final nota = notas[index];
        return _buildNotaCard(nota);
      },
    );
  }

  Widget _buildNotaCard(Map<String, dynamic> nota) {
    final contenido = nota['contenido'] ?? 'Sin contenido';
    final fecha = nota['fecha_creacion'] ?? '';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note, size: 20, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fecha.split('T')[0],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              contenido,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value ?? 'No especificado',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.green[900] : Colors.black,
          ),
        ),
      ],
    );
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // ==================== TAB: VEHÍCULO (con sub-tabs) ====================
  Widget _buildVehiculoTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.grey[200],
            child: const TabBar(
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.deepPurple,
              tabs: [
                Tab(text: 'Inventario'),
                Tab(text: 'Inspecciones'),
                Tab(text: 'Pruebas'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildInventarioTab(),
                _buildInspeccionesTab(),
                _buildPruebasRutaTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventarioTab() {
    final inventarios = _orden?['inventario_vehiculo'] as List<dynamic>? ?? [];

    if (inventarios.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay inventario registrado', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    final inventario = inventarios[0];

    final items = [
      {'label': 'Extintor', 'value': inventario['extintor'], 'icon': Icons.fire_extinguisher},
      {'label': 'Botiquín', 'value': inventario['botiquin'], 'icon': Icons.medical_services},
      {'label': 'Antena', 'value': inventario['antena'], 'icon': Icons.wifi},
      {'label': 'Llanta de repuesto', 'value': inventario['llanta_repuesto'], 'icon': Icons.album},
      {'label': 'Documentos', 'value': inventario['documentos'], 'icon': Icons.description},
      {'label': 'Encendedor', 'value': inventario['encendedor'], 'icon': Icons.local_fire_department},
      {'label': 'Pisos', 'value': inventario['pisos'], 'icon': Icons.grid_4x4},
      {'label': 'Luces', 'value': inventario['luces'], 'icon': Icons.lightbulb},
      {'label': 'Llaves', 'value': inventario['llaves'], 'icon': Icons.key},
      {'label': 'Gata', 'value': inventario['gata'], 'icon': Icons.hardware},
      {'label': 'Herramientas', 'value': inventario['herramientas'], 'icon': Icons.handyman},
      {'label': 'Tapas de ruedas', 'value': inventario['tapas_ruedas'], 'icon': Icons.circle},
      {'label': 'Triángulos', 'value': inventario['triangulos'], 'icon': Icons.change_history},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final label = item['label'] as String;
        final value = item['value'] as bool? ?? false;
        final icon = item['icon'] as IconData;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(icon, color: Colors.deepPurple),
            title: Text(label, style: const TextStyle(fontSize: 16)),
            trailing: Icon(
              value ? Icons.check_circle : Icons.cancel,
              color: value ? Colors.green : Colors.red,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInspeccionesTab() {
    final inspecciones = _orden?['inspecciones'] as List<dynamic>? ?? [];

    if (inspecciones.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay inspecciones registradas', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inspecciones.length,
      itemBuilder: (context, index) {
        final inspeccion = inspecciones[index];
        final tipoInspeccion = inspeccion['tipo_inspeccion'] ?? 'Sin tipo';
        final tipoLabel = tipoInspeccion == 'ingreso' ? 'Ingreso' : 'Salida';
        final fecha = inspeccion['fecha'] ?? '';
        final fechaFormateada = fecha.isNotEmpty ? fecha.split('T')[0] : 'Sin fecha';
        final observaciones = inspeccion['observaciones_generales'] ?? 'Sin observaciones';
        final tecnicoNombre = inspeccion['tecnico_nombre'] ?? 'Sin técnico asignado';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ExpansionTile(
            leading: Icon(
              tipoInspeccion == 'ingreso' ? Icons.login : Icons.logout,
              color: Colors.deepPurple,
            ),
            title: Text('Inspección de $tipoLabel'),
            subtitle: Text('$fechaFormateada • Técnico: $tecnicoNombre'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInspeccionItem('Aceite motor', inspeccion['aceite_motor']),
                    _buildInspeccionItem('Filtros VH', inspeccion['Filtros_VH']),
                    _buildInspeccionItem('Nivel refrigerante', inspeccion['nivel_refrigerante']),
                    _buildInspeccionItem('Pastillas de freno', inspeccion['pastillas_freno']),
                    _buildInspeccionItem('Estado neumáticos', inspeccion['Estado_neumaticos']),
                    _buildInspeccionItem('Estado batería', inspeccion['estado_bateria']),
                    _buildInspeccionItem('Estado luces', inspeccion['estado_luces']),
                    const Divider(height: 24),
                    const Text('Observaciones:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(observaciones, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInspeccionItem(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    String displayValue;
    Color valueColor;
    IconData icon;

    if (value == 'bueno') {
      displayValue = 'Buen estado';
      valueColor = Colors.green;
      icon = Icons.check_circle;
    } else if (value == 'malo') {
      displayValue = 'Mal estado';
      valueColor = Colors.red;
      icon = Icons.cancel;
    } else if (value == 'alto') {
      displayValue = 'Alto';
      valueColor = Colors.green;
      icon = Icons.arrow_upward;
    } else if (value == 'medio') {
      displayValue = 'Medio';
      valueColor = Colors.orange;
      icon = Icons.remove;
    } else if (value == 'bajo') {
      displayValue = 'Bajo';
      valueColor = Colors.red;
      icon = Icons.arrow_downward;
    } else {
      displayValue = value.toString();
      valueColor = Colors.grey;
      icon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: valueColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            displayValue,
            style: TextStyle(fontSize: 14, color: valueColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPruebasRutaTab() {
    final pruebas = _orden?['pruebas_ruta'] as List<dynamic>? ?? [];

    if (pruebas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay pruebas de ruta registradas', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pruebas.length,
      itemBuilder: (context, index) {
        final prueba = pruebas[index];
        final tipoPrueba = prueba['tipo_prueba'] ?? 'Sin tipo';
        String tipoLabel;
        if (tipoPrueba == 'inicial') {
          tipoLabel = 'Inicial';
        } else if (tipoPrueba == 'intermedio') {
          tipoLabel = 'Intermedio';
        } else if (tipoPrueba == 'final') {
          tipoLabel = 'Final';
        } else {
          tipoLabel = tipoPrueba;
        }
        
        final fechaPrueba = prueba['fecha_prueba'] ?? '';
        final fechaFormateada = fechaPrueba.isNotEmpty ? fechaPrueba.split('T')[0] : 'Sin fecha';
        final kmInicio = prueba['kilometraje_inicio'] ?? 0;
        final kmFinal = prueba['kilometraje_final'] ?? 0;
        final ruta = prueba['ruta'] ?? 'Sin descripción';
        final frenos = prueba['frenos'] ?? '';
        final motor = prueba['motor'] ?? '';
        final suspension = prueba['suspension'] ?? '';
        final direccion = prueba['direccion'] ?? '';
        final observaciones = prueba['observaciones'] ?? 'Sin observaciones';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ExpansionTile(
            leading: const Icon(Icons.route, color: Colors.deepPurple),
            title: Text('Prueba $tipoLabel'),
            subtitle: Text('$fechaFormateada • $kmInicio km → $kmFinal km'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.speed, 'Km Inicio', '$kmInicio km'),
                    _buildInfoRow(Icons.speed, 'Km Final', '$kmFinal km'),
                    _buildInfoRow(Icons.map, 'Ruta', ruta),
                    const Divider(height: 24),
                    const Text('Estado de Componentes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    _buildPruebaEstadoItem('Frenos', frenos),
                    _buildPruebaEstadoItem('Motor', motor),
                    _buildPruebaEstadoItem('Suspensión', suspension),
                    _buildPruebaEstadoItem('Dirección', direccion),
                    const Divider(height: 24),
                    const Text('Observaciones:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(observaciones, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPruebaEstadoItem(String label, String estado) {
    if (estado.isEmpty) return const SizedBox.shrink();

    String displayValue;
    Color valueColor;
    IconData icon;

    if (estado == 'bueno') {
      displayValue = 'Bueno';
      valueColor = Colors.green;
      icon = Icons.check_circle;
    } else if (estado == 'regular') {
      displayValue = 'Regular';
      valueColor = Colors.orange;
      icon = Icons.warning;
    } else if (estado == 'malo') {
      displayValue = 'Malo';
      valueColor = Colors.red;
      icon = Icons.cancel;
    } else {
      displayValue = estado;
      valueColor = Colors.grey;
      icon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: valueColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            displayValue,
            style: TextStyle(fontSize: 14, color: valueColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ==================== TAB: TAREAS ====================
  Widget _buildTareasTab() {
    final tareas = _orden?['tareas'] as List<dynamic>? ?? [];

    if (tareas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_box_outline_blank, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay tareas', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tareas.length,
      itemBuilder: (context, index) {
        final tarea = tareas[index];
        final descripcion = tarea['descripcion'] ?? '';
        final completada = tarea['completada'] ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              completada ? Icons.check_box : Icons.check_box_outline_blank,
              color: completada ? Colors.green : Colors.grey,
            ),
            title: Text(
              descripcion,
              style: TextStyle(
                decoration: completada ? TextDecoration.lineThrough : null,
                color: completada ? Colors.grey : Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== TAB: TÉCNICOS ====================
  Widget _buildTecnicosTab() {
    final asignaciones = _orden?['asignaciones_tecnicos'] as List<dynamic>? ?? [];

    if (asignaciones.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay técnicos asignados', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: asignaciones.length,
      itemBuilder: (context, index) {
        final asignacion = asignaciones[index];
        final tecnicoNombre = asignacion['tecnico_nombre'] ?? 'Sin nombre';
        final fechaAsignacion = asignacion['fecha_asignacion'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(tecnicoNombre),
            subtitle: Text('Asignado: ${fechaAsignacion.split('T')[0]}'),
          ),
        );
      },
    );
  }

  // ==================== TAB: IMÁGENES ====================
  Widget _buildImagenesTab() {
    final imagenes = _orden?['imagenes'] as List<dynamic>? ?? [];

    if (imagenes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay imágenes', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: imagenes.length,
      itemBuilder: (context, index) {
        final imagen = imagenes[index];
        final imagenUrl = imagen['imagen_url'] ?? '';
        final descripcion = imagen['descripcion'] ?? 'Sin descripción';

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              _showImageDialog(imagenUrl, descripcion);
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      imagenUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImageDialog(String imageUrl, String descripcion) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Imagen'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                descripcion,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
