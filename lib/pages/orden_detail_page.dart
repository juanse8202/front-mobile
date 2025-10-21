import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../services/orden_trabajo_service.dart';

class OrdenDetailPage extends StatefulWidget {
  final int ordenId;

  const OrdenDetailPage({super.key, required this.ordenId});

  @override
  State<OrdenDetailPage> createState() => _OrdenDetailPageState();
}

class _OrdenDetailPageState extends State<OrdenDetailPage> with SingleTickerProviderStateMixin {
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

  Future<void> _cambiarEstado(String nuevoEstado) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      // Mostrar diálogo de confirmación
      if (!mounted) return;
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar cambio de estado'),
          content: Text(
            '¿Está seguro de cambiar el estado a "${_getEstadoLabel(nuevoEstado)}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getEstadoColor(nuevoEstado),
              ),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );

      if (confirmar != true) return;

      // Mostrar indicador de carga
      if (!mounted) return;
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Actualizar estado en el backend
      final dataToUpdate = <String, dynamic>{'estado': nuevoEstado};
      
      // Si el nuevo estado es 'entregada', establecer fecha de entrega automáticamente
      if (nuevoEstado == 'entregada') {
        dataToUpdate['fecha_entrega'] = DateTime.now().toIso8601String();
      } else {
        // Si cambia a otro estado, eliminar la fecha de entrega
        dataToUpdate['fecha_entrega'] = null;
      }
      
      await _ordenService.updateOrden(
        widget.ordenId,
        dataToUpdate,
        token: token,
      );

      // Cerrar diálogo de carga
      if (!mounted) return;
      Navigator.pop(context);

      // Recargar datos
      await _loadOrdenDetail();

      // Mostrar mensaje de éxito
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a ${_getEstadoLabel(nuevoEstado)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      if (!mounted) return;
      Navigator.pop(context);

      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar estado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _mostrarDialogoCambiarEstado(String estadoActual) async {
    final List<Map<String, String>> estados = [
      {'value': 'pendiente', 'label': 'Pendiente'},
      {'value': 'en_proceso', 'label': 'En Proceso'},
      {'value': 'finalizada', 'label': 'Finalizada'},
      {'value': 'entregada', 'label': 'Entregada'},
      {'value': 'cancelada', 'label': 'Cancelada'},
    ];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: estados.map((estado) {
            final value = estado['value']!;
            final label = estado['label']!;
            final isActual = value == estadoActual;

            return ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getEstadoColor(value),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(
                label,
                style: TextStyle(
                  fontWeight: isActual ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isActual
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              enabled: !isActual,
              onTap: isActual
                  ? null
                  : () {
                      Navigator.pop(context);
                      _cambiarEstado(value);
                    },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'General', icon: Icon(Icons.info_outline)),
            Tab(text: 'Detalles', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Vehículo', icon: Icon(Icons.directions_car)),
            Tab(text: 'Notas', icon: Icon(Icons.note)),
            Tab(text: 'Tareas', icon: Icon(Icons.check_box)),
            Tab(text: 'Técnicos', icon: Icon(Icons.people)),
            Tab(text: 'Imágenes', icon: Icon(Icons.photo_library)),
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
                    _buildDetallesOrdenTab(),
                    _buildVehiculoTab(),
                    _buildNotasTab(),
                    _buildTareasTab(),
                    _buildTecnicosTab(),
                    _buildImagenesTab(),
                  ],
                ),
    );
  }

  // ==================== TAB: GENERAL ====================
  Widget _buildGeneralTab() {
    if (_orden == null) return const Center(child: Text('No hay datos'));

    final estado = _orden!['estado'];
    final clienteNombre = _orden!['cliente_nombre'] ?? 'Sin cliente';
    final clienteTelefono = _orden!['cliente_telefono'] ?? 'Sin teléfono';
    final vehiculoPlaca = _orden!['vehiculo_placa'] ?? 'Sin placa';
    final vehiculoMarca = _orden!['vehiculo_marca'] ?? '';
    final vehiculoModelo = _orden!['vehiculo_modelo'] ?? '';
    final falloRequerimiento = _orden!['fallo_requerimiento'] ?? 'Sin descripción';
    final fechaCreacion = _orden!['fecha_creacion'] ?? '';
    final fechaInicio = _orden!['fecha_inicio'] ?? '';
    final fechaFinalizacion = _orden!['fecha_finalizacion'] ?? '';
    final fechaEntrega = _orden!['fecha_entrega'] ?? '';
    final kilometraje = _orden!['kilometraje'] ?? '';
    final nivelCombustible = _orden!['nivel_combustible'] ?? '';
    final observaciones = _orden!['observaciones'] ?? 'Sin observaciones';
    final subtotal = _parseDouble(_orden!['subtotal']);
    final impuesto = _parseDouble(_orden!['impuesto']);
    final descuento = _parseDouble(_orden!['descuento']);
    final total = _parseDouble(_orden!['total']);

    return RefreshIndicator(
      onRefresh: _loadOrdenDetail,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _getEstadoColor(estado),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  _getEstadoLabel(estado),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Botón para cambiar estado
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _mostrarDialogoCambiarEstado(estado),
                icon: const Icon(Icons.edit),
                label: const Text('Cambiar Estado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Cliente
            _buildSectionTitle('Cliente'),
            _buildInfoCard([
              _buildInfoRow(Icons.person, 'Nombre', clienteNombre),
              _buildInfoRow(Icons.phone, 'Teléfono', clienteTelefono),
            ]),

            const SizedBox(height: 16),

            // Vehículo
            _buildSectionTitle('Vehículo'),
            _buildInfoCard([
              _buildInfoRow(Icons.directions_car, 'Placa', vehiculoPlaca),
              _buildInfoRow(Icons.car_rental, 'Marca', vehiculoMarca),
              _buildInfoRow(Icons.model_training, 'Modelo', vehiculoModelo),
              _buildEditableInfoRow(
                Icons.speed,
                'Kilometraje',
                '$kilometraje km',
                () => _editarKilometraje(kilometraje),
              ),
              _buildEditableInfoRow(
                Icons.local_gas_station,
                'Combustible',
                _getNivelCombustibleLabel(nivelCombustible),
                () => _editarNivelCombustible(nivelCombustible),
              ),
            ]),

            const SizedBox(height: 16),

            // Fallo/Requerimiento
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Fallo/Requerimiento'),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.deepPurple),
                  onPressed: () => _editarFalloRequerimiento(falloRequerimiento),
                  tooltip: 'Editar',
                ),
              ],
            ),
            _buildInfoCard([
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  falloRequerimiento,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ]),

            const SizedBox(height: 16),

            // Fechas
            _buildSectionTitle('Fechas'),
            _buildInfoCard([
              _buildInfoRow(Icons.calendar_today, 'Creación', fechaCreacion.split('T')[0]),
              if (fechaInicio.isNotEmpty)
                _buildInfoRow(Icons.play_arrow, 'Inicio', fechaInicio.split('T')[0]),
              if (fechaFinalizacion.isNotEmpty)
                _buildEditableInfoRow(
                  Icons.stop,
                  'Finalización',
                  fechaFinalizacion.split('T')[0],
                  () => _editarFechaFinalizacion(fechaFinalizacion),
                )
              else
                _buildEditableInfoRow(
                  Icons.stop,
                  'Finalización',
                  'No establecida',
                  () => _editarFechaFinalizacion(''),
                ),
              if (fechaEntrega.isNotEmpty)
                _buildInfoRow(Icons.check_circle, 'Entrega', fechaEntrega.split('T')[0]),
            ]),

            const SizedBox(height: 16),

            // Observaciones
            if (observaciones.isNotEmpty || true) // Mostrar siempre para poder agregar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Observaciones'),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.deepPurple),
                        onPressed: () => _editarObservaciones(observaciones),
                        tooltip: 'Editar',
                      ),
                    ],
                  ),
                  _buildInfoCard([
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        observaciones.isEmpty ? 'Sin observaciones' : observaciones,
                        style: TextStyle(
                          fontSize: 15,
                          color: observaciones.isEmpty ? Colors.grey : Colors.black87,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                ],
              ),

            // Detalles de Servicios
            _buildSectionTitle('Detalles de Servicios'),
            _buildDetallesResumen(),

            const SizedBox(height: 16),

            // Totales
            _buildSectionTitle('Totales'),
            _buildInfoCard([
              _buildInfoRow(Icons.attach_money, 'Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
              _buildInfoRow(Icons.discount, 'Descuento', '\$${descuento.toStringAsFixed(2)}'),
              _buildInfoRow(Icons.receipt, 'Impuesto', '\$${impuesto.toStringAsFixed(2)}'),
              const Divider(thickness: 2),
              _buildInfoRow(
                Icons.monetization_on,
                'TOTAL',
                '\$${total.toStringAsFixed(2)}',
                bold: true,
                color: Colors.green,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // Resumen de detalles para el tab General
  Widget _buildDetallesResumen() {
    final detalles = _orden?['detalles'] as List<dynamic>? ?? [];

    if (detalles.isEmpty) {
      return _buildInfoCard([
        const Padding(
          padding: EdgeInsets.all(12),
          child: Center(
            child: Text('No hay detalles de servicio', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ]);
    }

    return _buildInfoCard(
      detalles.map((detalle) {
        final nombreItem = detalle['nombre_item'] ?? detalle['item_nombre'] ?? 'Item sin nombre';
        final cantidad = detalle['cantidad'] ?? 0;
        final total = _parseDouble(detalle['total']);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.build, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$nombreItem (x$cantidad)',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ==================== TAB: DETALLES ORDEN (ITEMS) ====================
  Widget _buildDetallesOrdenTab() {
    final detalles = _orden?['detalles'] as List<dynamic>? ?? [];
    final subtotal = _parseDouble(_orden?['subtotal'] ?? 0);
    final descuento = _parseDouble(_orden?['descuento'] ?? 0);
    final impuesto = _parseDouble(_orden?['impuesto'] ?? 0);
    final total = _parseDouble(_orden?['total'] ?? 0);

    return Column(
      children: [
        // Encabezado con botón de agregar
        Container(
          color: Colors.deepPurple.shade50,
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items/Servicios',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _mostrarDialogoAgregarDetalle,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        
        // Lista de detalles
        Expanded(
          child: detalles.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay items agregados',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: detalles.length,
                  itemBuilder: (context, index) {
                    final detalle = detalles[index];
                    return _buildDetalleCard(detalle);
                  },
                ),
        ),
        
        // Totales
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTotalRow('Subtotal:', subtotal),
              if (descuento > 0) _buildTotalRow('Descuento:', -descuento, color: Colors.green),
              _buildTotalRow('Impuesto (13%):', impuesto),
              const Divider(thickness: 2),
              _buildTotalRow('TOTAL:', total, isBold: true, fontSize: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetalleCard(Map<String, dynamic> detalle) {
    final id = detalle['id'];
    final nombreItem = detalle['nombre_item'] ?? detalle['item_nombre'] ?? 'Item sin nombre';
    final cantidad = detalle['cantidad'] ?? 0;
    final precioUnitario = _parseDouble(detalle['precio_unitario']);
    final descuentoPorcentaje = _parseDouble(detalle['descuento_porcentaje'] ?? 0);
    final descuento = _parseDouble(detalle['descuento'] ?? 0);
    final subtotal = _parseDouble(detalle['subtotal']);
    final total = _parseDouble(detalle['total']);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    nombreItem,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarDetalle(id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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

  Widget _buildTotalRow(String label, double value, {Color? color, bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB: VEHÍCULO ====================
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

  // ==================== TAB: NOTAS ====================
  Widget _buildNotasTab() {
    final notas = _orden?['notas'] as List<dynamic>? ?? [];

    return Column(
      children: [
        // Botón para agregar nota
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _mostrarDialogoAgregarNota,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Nota'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ),
        
        // Lista de notas
        Expanded(
          child: notas.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay notas', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrdenDetail,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notas.length,
                    itemBuilder: (context, index) {
                      final nota = notas[index];
                      final notaId = nota['id'];
                      final contenido = nota['contenido'] ?? '';
                      final fechaNota = nota['fecha_nota'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.note, color: Colors.blue),
                          title: Text(contenido),
                          subtitle: Text(
                            fechaNota.split('T')[0],
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminarNota(notaId),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _mostrarDialogoAgregarNota() async {
    final controller = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Nota'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Contenido',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.isNotEmpty) {
      await _crearNota(controller.text);
    }
  }

  Future<void> _crearNota(String contenido) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _ordenService.createNota(
        widget.ordenId,
        {'contenido': contenido},
        token: token,
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (result['status'] >= 200 && result['status'] < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota agregada exitosamente')),
        );
        await _loadOrdenDetail();
      } else {
        throw Exception('Error al crear nota');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading si está abierto
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _eliminarNota(int notaId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Nota'),
        content: const Text('¿Está seguro de eliminar esta nota?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final token = await _storage.read(key: 'access_token');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await _ordenService.deleteNota(widget.ordenId, notaId, token: token);

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota eliminada')),
        );
        await _loadOrdenDetail();
      } else {
        throw Exception('Error al eliminar nota');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading si está abierto
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ==================== TAB: TAREAS ====================
  Widget _buildTareasTab() {
    final tareas = _orden?['tareas'] as List<dynamic>? ?? [];

    return Column(
      children: [
        // Botón para agregar tarea
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _mostrarDialogoAgregarTarea,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Tarea'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ),
        
        // Lista de tareas
        Expanded(
          child: tareas.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_box_outline_blank, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay tareas', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrdenDetail,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tareas.length,
                    itemBuilder: (context, index) {
                      final tarea = tareas[index];
                      final tareaId = tarea['id'];
                      final descripcion = tarea['descripcion'] ?? '';
                      final completada = tarea['completada'] ?? false;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Checkbox(
                            value: completada,
                            onChanged: (value) => _toggleTarea(tareaId, value ?? false),
                          ),
                          title: Text(
                            descripcion,
                            style: TextStyle(
                              decoration: completada ? TextDecoration.lineThrough : null,
                              color: completada ? Colors.grey : Colors.black,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminarTarea(tareaId),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _mostrarDialogoAgregarTarea() async {
    final controller = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Tarea'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.isNotEmpty) {
      await _crearTarea(controller.text);
    }
  }

  Future<void> _crearTarea(String descripcion) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _ordenService.createTarea(
        widget.ordenId,
        {'descripcion': descripcion, 'completada': false},
        token: token,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (result['status'] >= 200 && result['status'] < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea agregada exitosamente')),
        );
        await _loadOrdenDetail();
      } else {
        throw Exception('Error al crear tarea');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _toggleTarea(int tareaId, bool completada) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      final result = await _ordenService.updateTarea(
        widget.ordenId,
        tareaId,
        {'completada': completada},
        token: token,
      );

      if (result['status'] >= 200 && result['status'] < 300) {
        await _loadOrdenDetail();
      } else {
        throw Exception('Error al actualizar tarea');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _eliminarTarea(int tareaId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Tarea'),
        content: const Text('¿Está seguro de eliminar esta tarea?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final token = await _storage.read(key: 'access_token');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await _ordenService.deleteTarea(widget.ordenId, tareaId, token: token);

      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea eliminada')),
        );
        await _loadOrdenDetail();
      } else {
        throw Exception('Error al eliminar tarea');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ==================== TAB: INVENTARIO ====================
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
    final inventarioId = inventario['id'];

    final items = [
      {'label': 'Extintor', 'field': 'extintor', 'value': inventario['extintor'], 'icon': Icons.fire_extinguisher},
      {'label': 'Botiquín', 'field': 'botiquin', 'value': inventario['botiquin'], 'icon': Icons.medical_services},
      {'label': 'Antena', 'field': 'antena', 'value': inventario['antena'], 'icon': Icons.wifi},
      {'label': 'Llanta de repuesto', 'field': 'llanta_repuesto', 'value': inventario['llanta_repuesto'], 'icon': Icons.album},
      {'label': 'Documentos', 'field': 'documentos', 'value': inventario['documentos'], 'icon': Icons.description},
      {'label': 'Encendedor', 'field': 'encendedor', 'value': inventario['encendedor'], 'icon': Icons.local_fire_department},
      {'label': 'Pisos', 'field': 'pisos', 'value': inventario['pisos'], 'icon': Icons.grid_4x4},
      {'label': 'Luces', 'field': 'luces', 'value': inventario['luces'], 'icon': Icons.lightbulb},
      {'label': 'Llaves', 'field': 'llaves', 'value': inventario['llaves'], 'icon': Icons.key},
      {'label': 'Gata', 'field': 'gata', 'value': inventario['gata'], 'icon': Icons.hardware},
      {'label': 'Herramientas', 'field': 'herramientas', 'value': inventario['herramientas'], 'icon': Icons.handyman},
      {'label': 'Tapas de ruedas', 'field': 'tapas_ruedas', 'value': inventario['tapas_ruedas'], 'icon': Icons.circle},
      {'label': 'Triángulos', 'field': 'triangulos', 'value': inventario['triangulos'], 'icon': Icons.change_history},
    ];

    return RefreshIndicator(
      onRefresh: _loadOrdenDetail,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final label = item['label'] as String;
          final field = item['field'] as String;
          final value = item['value'] as bool? ?? false;
          final icon = item['icon'] as IconData;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: CheckboxListTile(
              secondary: Icon(icon, color: Colors.deepPurple),
              title: Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
              value: value,
              activeColor: Colors.green,
              onChanged: (newValue) {
                _actualizarItemInventario(inventarioId, field, newValue ?? false);
              },
            ),
          );
        },
      ),
    );
  }

  // ==================== TAB: INSPECCIONES ====================
  Widget _buildInspeccionesTab() {
    final inspecciones = _orden?['inspecciones'] as List<dynamic>? ?? [];

    return Column(
      children: [
        // Botón para agregar inspección
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _mostrarDialogoAgregarInspeccion,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Inspección'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ),
        
        // Lista de inspecciones
        Expanded(
          child: inspecciones.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay inspecciones registradas', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrdenDetail,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: inspecciones.length,
                    itemBuilder: (context, index) {
                      final inspeccion = inspecciones[index];
                      final inspeccionId = inspeccion['id'];
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _mostrarDialogoEditarInspeccion(inspeccion),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _eliminarInspeccion(inspeccionId),
                              ),
                            ],
                          ),
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
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInspeccionItem(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    String displayValue;
    Color valueColor;
    IconData icon;

    // Determinar el valor a mostrar y el color
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

  // ==================== TAB: TÉCNICOS ====================
  Widget _buildTecnicosTab() {
    final asignaciones = _orden?['asignaciones_tecnicos'] as List<dynamic>? ?? [];

    return Column(
      children: [
        // Botón para asignar técnico
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _mostrarDialogoAsignarTecnico,
            icon: const Icon(Icons.person_add),
            label: const Text('Asignar Técnico'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ),
        
        // Lista de técnicos asignados
        Expanded(
          child: asignaciones.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay técnicos asignados', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrdenDetail,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: asignaciones.length,
                    itemBuilder: (context, index) {
                      final asignacion = asignaciones[index];
                      final asignacionId = asignacion['id'];
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
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _eliminarAsignacionTecnico(asignacionId),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _mostrarDialogoAsignarTecnico() async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Obtener lista de empleados
      final empleados = await _ordenService.fetchEmpleados(token: token);

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (empleados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay empleados disponibles')),
        );
        return;
      }

      // Mostrar diálogo de selección con buscador
      final tecnicoSeleccionado = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _DialogoSeleccionTecnico(empleados: empleados),
      );

      if (tecnicoSeleccionado != null) {
        await _asignarTecnico(tecnicoSeleccionado['id']);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading si está abierto
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _asignarTecnico(int tecnicoId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _ordenService.createAsignacion(
        widget.ordenId,
        {'tecnico': tecnicoId},
        token: token,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (result['status'] >= 200 && result['status'] < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Técnico asignado exitosamente')),
        );
        await _loadOrdenDetail();
      } else {
        throw Exception('Error al asignar técnico');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _eliminarAsignacionTecnico(int asignacionId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Asignación'),
        content: const Text('¿Está seguro de eliminar esta asignación de técnico?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final token = await _storage.read(key: 'access_token');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await _ordenService.deleteAsignacion(widget.ordenId, asignacionId, token: token);

      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asignación eliminada')),
        );
        await _loadOrdenDetail();
      } else {
        throw Exception('Error al eliminar asignación');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ==================== TAB: PRUEBAS DE RUTA ====================
  Widget _buildPruebasRutaTab() {
    final pruebas = _orden?['pruebas_ruta'] as List<dynamic>? ?? [];

    return Column(
      children: [
        // Botón para agregar prueba de ruta
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _mostrarDialogoAgregarPruebaRuta,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Prueba de Ruta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ),
        
        // Lista de pruebas
        Expanded(
          child: pruebas.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay pruebas de ruta registradas', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrdenDetail,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: pruebas.length,
                    itemBuilder: (context, index) {
                      final prueba = pruebas[index];
                      final pruebaId = prueba['id'];
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _mostrarDialogoEditarPruebaRuta(prueba),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _eliminarPruebaRuta(pruebaId),
                              ),
                            ],
                          ),
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
                  ),
                ),
        ),
      ],
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

  // ==================== TAB: IMÁGENES ====================
  Widget _buildImagenesTab() {
    final imagenes = _orden?['imagenes'] as List<dynamic>? ?? [];

    return Column(
      children: [
        // Botón para agregar imagen
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _mostrarDialogoAgregarImagen,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Agregar Imagen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ),
        
        // Lista de imágenes
        Expanded(
          child: imagenes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay imágenes', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrdenDetail,
                  child: GridView.builder(
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
                      final imagenId = imagen['id'];
                      final imagenUrl = imagen['imagen_url'] ?? '';
                      final descripcion = imagen['descripcion'] ?? 'Sin descripción';

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Stack(
                          children: [
                            InkWell(
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
                            // Botón de eliminar
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.white),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.all(8),
                                ),
                                onPressed: () => _eliminarImagen(imagenId),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _mostrarDialogoAgregarImagen() async {
    final ImagePicker picker = ImagePicker();
    
    // Mostrar opciones para elegir fuente
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Imagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    // Seleccionar imagen
    final XFile? image = await picker.pickImage(source: source);
    
    if (image == null) return;

    // Pedir descripción
    final descripcionController = TextEditingController();
    
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descripción de la Imagen'),
        content: TextField(
          controller: descripcionController,
          decoration: const InputDecoration(
            labelText: 'Descripción (opcional)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Subir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _subirImagen(image.path, descripcionController.text);
    }
  }

  Future<void> _subirImagen(String filePath, String descripcion) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      // Mostrar SnackBar con indicador de carga
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 16),
              Text('Subiendo imagen...'),
            ],
          ),
          duration: Duration(seconds: 30), // Duración larga, se cerrará al terminar
        ),
      );

      final result = await _ordenService.uploadImagen(
        widget.ordenId,
        filePath,
        descripcion: descripcion,
        token: token,
      );

      if (!mounted) return;
      
      // Cerrar el SnackBar de carga
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result['status'] >= 200 && result['status'] < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 16),
                Text('Imagen subida exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        await _loadOrdenDetail();
      } else {
        throw Exception('Error al subir imagen: ${result['body']}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _eliminarImagen(int imagenId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Imagen'),
        content: const Text('¿Está seguro de eliminar esta imagen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final token = await _storage.read(key: 'access_token');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await _ordenService.deleteImagen(widget.ordenId, imagenId, token: token);

      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen eliminada')),
        );
        await _loadOrdenDetail();
      } else {
        throw Exception('Error al eliminar imagen');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ==================== CRUD: INSPECCIONES ====================

  Future<void> _mostrarDialogoAgregarInspeccion() async {
    // Primero obtener lista de técnicos
    final token = await _storage.read(key: 'access_token');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final empleados = await _ordenService.fetchEmpleados(token: token);
      
      if (!mounted) return;
      Navigator.pop(context);

      // Mostrar diálogo de inspección
      final resultado = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _DialogoInspeccion(empleados: empleados),
      );

      if (resultado != null) {
        // SOLUCIÓN: El serializer espera orden_trabajo aunque el ViewSet lo asigne
        // porque no está en read_only_fields
        resultado['orden_trabajo'] = widget.ordenId;
        
        await _crearInspeccion(resultado);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar técnicos: $e')),
      );
    }
  }

  Future<void> _mostrarDialogoEditarInspeccion(Map<String, dynamic> inspeccion) async {
    // Primero obtener lista de técnicos
    final token = await _storage.read(key: 'access_token');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final empleados = await _ordenService.fetchEmpleados(token: token);
      
      if (!mounted) return;
      Navigator.pop(context);

      // Mostrar diálogo de inspección con datos precargados
      final resultado = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _DialogoInspeccion(
          empleados: empleados,
          inspeccionInicial: inspeccion,
        ),
      );

      if (resultado != null) {
        await _actualizarInspeccion(inspeccion['id'], resultado);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar técnicos: $e')),
      );
    }
  }

  Future<void> _crearInspeccion(Map<String, dynamic> data) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      // Debug: Imprimir datos antes de enviar
      print('🔧 Datos de inspección a enviar: $data');
      print('🔧 Orden ID: ${widget.ordenId}');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _ordenService.createInspeccion(widget.ordenId, data, token: token);

      if (!mounted) return;
      Navigator.pop(context);

      if (result['status'] >= 200 && result['status'] < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspección creada exitosamente')),
        );
        await _loadOrdenDetail();
      } else {
        // Mostrar error específico del backend
        final errorMsg = result['body'] ?? 'Error desconocido';
        throw Exception('Error ${result['status']}: $errorMsg');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear inspección: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _actualizarInspeccion(int inspeccionId, Map<String, dynamic> data) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _ordenService.updateInspeccion(widget.ordenId, inspeccionId, data, token: token);

      if (!mounted) return;
      Navigator.pop(context);

      if (result['status'] >= 200 && result['status'] < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspección actualizada exitosamente')),
        );
        await _loadOrdenDetail();
      } else {
        throw Exception('Error al actualizar inspección');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _eliminarInspeccion(int inspeccionId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Inspección'),
        content: const Text('¿Está seguro de eliminar esta inspección?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final token = await _storage.read(key: 'access_token');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await _ordenService.deleteInspeccion(widget.ordenId, inspeccionId, token: token);

      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspección eliminada')),
        );
        await _loadOrdenDetail();
      } else {
        throw Exception('Error al eliminar inspección');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ==================== CRUD: PRUEBAS DE RUTA ====================

  Future<void> _mostrarDialogoAgregarPruebaRuta() async {
    // Primero obtener lista de técnicos
    final token = await _storage.read(key: 'access_token');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final empleados = await _ordenService.fetchEmpleados(token: token);
      
      if (!mounted) return;
      Navigator.pop(context);

      // Mostrar diálogo de prueba de ruta
      final resultado = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _DialogoPruebaRuta(empleados: empleados),
      );

      if (resultado != null) {
        // SOLUCIÓN: El serializer espera orden_trabajo aunque el ViewSet lo asigne
        // porque no está en read_only_fields
        resultado['orden_trabajo'] = widget.ordenId;
        
        await _crearPruebaRuta(resultado);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar técnicos: $e')),
      );
    }
  }

  Future<void> _mostrarDialogoEditarPruebaRuta(Map<String, dynamic> prueba) async {
    // Primero obtener lista de técnicos
    final token = await _storage.read(key: 'access_token');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final empleados = await _ordenService.fetchEmpleados(token: token);
      
      if (!mounted) return;
      Navigator.pop(context);

      // Mostrar diálogo de prueba con datos precargados
      final resultado = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _DialogoPruebaRuta(
          empleados: empleados,
          pruebaInicial: prueba,
        ),
      );

      if (resultado != null) {
        await _actualizarPruebaRuta(prueba['id'], resultado);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar técnicos: $e')),
      );
    }
  }

  Future<void> _crearPruebaRuta(Map<String, dynamic> data) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      // Debug: Imprimir datos antes de enviar
      print('🔧 Datos de prueba de ruta a enviar: $data');
      print('🔧 Orden ID: ${widget.ordenId}');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _ordenService.createPruebaRuta(widget.ordenId, data, token: token);

      if (!mounted) return;
      Navigator.pop(context);

      if (result['status'] >= 200 && result['status'] < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prueba de ruta creada exitosamente')),
        );
        await _loadOrdenDetail();
      } else {
        // Mostrar error específico del backend
        final errorMsg = result['body'] ?? 'Error desconocido';
        throw Exception('Error ${result['status']}: $errorMsg');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear prueba: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _actualizarPruebaRuta(int pruebaId, Map<String, dynamic> data) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _ordenService.updatePruebaRuta(widget.ordenId, pruebaId, data, token: token);

      if (!mounted) return;
      Navigator.pop(context);

      if (result['status'] >= 200 && result['status'] < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prueba de ruta actualizada exitosamente')),
        );
        await _loadOrdenDetail();
      } else {
        throw Exception('Error al actualizar prueba de ruta');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _eliminarPruebaRuta(int pruebaId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Prueba de Ruta'),
        content: const Text('¿Está seguro de eliminar esta prueba de ruta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final token = await _storage.read(key: 'access_token');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await _ordenService.deletePruebaRuta(widget.ordenId, pruebaId, token: token);

      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prueba de ruta eliminada')),
        );
        await _loadOrdenDetail();
      } else {
        throw Exception('Error al eliminar prueba de ruta');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ==================== CRUD: DETALLES (ITEMS) ====================
  
  Future<void> _mostrarDialogoAgregarDetalle() async {
    // Opciones: Item del catálogo o Personalizado
    final tipoItem = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Item/Servicio'),
        content: const Text('¿Qué tipo de item desea agregar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'catalogo'),
            child: const Text('Del Catálogo'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'personalizado'),
            child: const Text('Personalizado'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (tipoItem == null) return;

    if (tipoItem == 'catalogo') {
      await _mostrarDialogoSeleccionarItem();
    } else {
      await _mostrarDialogoItemPersonalizado();
    }
  }

  Future<void> _mostrarDialogoSeleccionarItem() async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      // Mostrar loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final items = await _ordenService.fetchItems(token: token);

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (items.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay items disponibles en el catálogo')),
        );
        return;
      }

      // Mostrar diálogo de selección con búsqueda
      if (!mounted) return;
      final itemSeleccionado = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _DialogoSeleccionItem(items: items),
      );

      if (itemSeleccionado == null) return;

      // Mostrar diálogo para cantidad y descuento
      await _mostrarDialogoDetalleItem(
        itemId: itemSeleccionado['id'],
        nombreItem: itemSeleccionado['nombre'],
        precioUnitario: _parseDouble(itemSeleccionado['precio']),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading si está abierto
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar items: $e')),
      );
    }
  }

  Future<void> _mostrarDialogoItemPersonalizado() async {
    final nombreController = TextEditingController();
    final cantidadController = TextEditingController(text: '1');
    final precioController = TextEditingController();
    final descuentoController = TextEditingController(text: '0');
    final tipoDescuento = ValueNotifier<String>('porcentaje'); // 'porcentaje' o 'monto'

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Item Personalizado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Item/Servicio',
                  hintText: 'Ej: Cambio de aceite especial',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cantidadController,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio Unitario',
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<String>(
                valueListenable: tipoDescuento,
                builder: (context, tipo, _) => Column(
                  children: [
                    RadioGroup<String>(
                      groupValue: tipo,
                      onChanged: (value) => tipoDescuento.value = value!,
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Descuento %'),
                              value: 'porcentaje',
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Descuento \$'),
                              value: 'monto',
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextField(
                      controller: descuentoController,
                      decoration: InputDecoration(
                        labelText: tipo == 'porcentaje' ? 'Descuento (%)' : 'Descuento (\$)',
                        prefixText: tipo == 'monto' ? '\$ ' : '',
                        suffixText: tipo == 'porcentaje' ? '%' : '',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
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
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final nombre = nombreController.text.trim();
    final cantidad = int.tryParse(cantidadController.text) ?? 1;
    final precio = double.tryParse(precioController.text) ?? 0.0;
    final descuento = double.tryParse(descuentoController.text) ?? 0.0;

    if (nombre.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe ingresar el nombre del item')),
      );
      return;
    }

    if (precio <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El precio debe ser mayor a 0')),
      );
      return;
    }

    await _crearDetalle(
      itemPersonalizado: nombre,
      cantidad: cantidad,
      precioUnitario: precio,
      descuentoPorcentaje: tipoDescuento.value == 'porcentaje' ? descuento : 0.0,
      descuentoMonto: tipoDescuento.value == 'monto' ? descuento : 0.0,
    );
  }

  Future<void> _mostrarDialogoDetalleItem({
    required int itemId,
    required String nombreItem,
    required double precioUnitario,
  }) async {
    final cantidadController = TextEditingController(text: '1');
    final descuentoController = TextEditingController(text: '0');
    final tipoDescuento = ValueNotifier<String>('porcentaje');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nombreItem),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Precio unitario: \$${precioUnitario.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cantidadController,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<String>(
                valueListenable: tipoDescuento,
                builder: (context, tipo, _) => Column(
                  children: [
                    RadioGroup<String>(
                      groupValue: tipo,
                      onChanged: (value) => tipoDescuento.value = value!,
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Descuento %'),
                              value: 'porcentaje',
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Descuento \$'),
                              value: 'monto',
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextField(
                      controller: descuentoController,
                      decoration: InputDecoration(
                        labelText: tipo == 'porcentaje' ? 'Descuento (%)' : 'Descuento (\$)',
                        prefixText: tipo == 'monto' ? '\$ ' : '',
                        suffixText: tipo == 'porcentaje' ? '%' : '',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
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
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final cantidad = int.tryParse(cantidadController.text) ?? 1;
    final descuento = double.tryParse(descuentoController.text) ?? 0.0;

    await _crearDetalle(
      itemId: itemId,
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      descuentoPorcentaje: tipoDescuento.value == 'porcentaje' ? descuento : 0.0,
      descuentoMonto: tipoDescuento.value == 'monto' ? descuento : 0.0,
    );
  }

  Future<void> _crearDetalle({
    int? itemId,
    String? itemPersonalizado,
    required int cantidad,
    required double precioUnitario,
    double descuentoPorcentaje = 0.0,
    double descuentoMonto = 0.0,
  }) async {
    try {
      final token = await _storage.read(key: 'access_token');

      final data = <String, dynamic>{
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
      };

      if (itemId != null) {
        data['item'] = itemId;
      } else if (itemPersonalizado != null) {
        data['item_personalizado'] = itemPersonalizado;
      }

      if (descuentoPorcentaje > 0) {
        data['descuento_porcentaje'] = descuentoPorcentaje;
      } else if (descuentoMonto > 0) {
        data['descuento'] = descuentoMonto;
      }

      await _ordenService.createDetalle(widget.ordenId, data, token: token);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detalle agregado exitosamente')),
      );
      await _loadOrdenDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar detalle: $e')),
      );
    }
  }

  Future<void> _eliminarDetalle(int detalleId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro de eliminar este detalle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final token = await _storage.read(key: 'access_token');
      
      await _ordenService.deleteDetalle(widget.ordenId, detalleId, token: token);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detalle eliminado')),
      );
      await _loadOrdenDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar detalle: $e')),
      );
    }
  }

  // ==================== EDITAR KILOMETRAJE Y COMBUSTIBLE ====================
  
  Future<void> _editarKilometraje(dynamic kilometrajeActual) async {
    final controller = TextEditingController(text: kilometrajeActual.toString());

    final resultado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Kilometraje'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Kilometraje',
            suffixText: 'km',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (resultado == null || resultado.isEmpty) return;

    final nuevoKilometraje = int.tryParse(resultado);
    if (nuevoKilometraje == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valor de kilometraje inválido')),
      );
      return;
    }

    await _actualizarOrden({'kilometraje': nuevoKilometraje});
  }

  Future<void> _editarNivelCombustible(dynamic nivelActual) async {
    final nivelesMap = {
      0: 'E (Vacío)',
      1: '1/4',
      2: '1/2',
      3: '3/4',
      4: 'F (Lleno)',
    };

    final nivelSeleccionado = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nivel de Combustible'),
        content: RadioGroup<int>(
          groupValue: nivelActual is int ? nivelActual : 0,
          onChanged: (value) => Navigator.pop(context, value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: nivelesMap.entries.map((entry) {
              return RadioListTile<int>(
                title: Text(entry.value),
                value: entry.key,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (nivelSeleccionado == null) return;

    await _actualizarOrden({'nivel_combustible': nivelSeleccionado});
  }

  Future<void> _editarFalloRequerimiento(String falloActual) async {
    final controller = TextEditingController(
      text: falloActual == 'Sin descripción' ? '' : falloActual,
    );

    final resultado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Fallo/Requerimiento'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Descripción del fallo o requerimiento',
            hintText: 'Describa el problema o servicio requerido...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (resultado == null) return;

    await _actualizarOrden({'fallo_requerimiento': resultado.trim()});
  }

  Future<void> _editarObservaciones(String observacionesActuales) async {
    final controller = TextEditingController(
      text: observacionesActuales == 'Sin observaciones' ? '' : observacionesActuales,
    );

    final resultado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Observaciones'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Observaciones',
            hintText: 'Agregue observaciones adicionales...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (resultado == null) return;

    await _actualizarOrden({'observaciones': resultado.trim()});
  }

  Future<void> _editarFechaFinalizacion(String fechaActual) async {
    // Parsear la fecha actual o usar hoy como default
    DateTime fechaInicial;
    if (fechaActual.isNotEmpty) {
      try {
        fechaInicial = DateTime.parse(fechaActual);
      } catch (e) {
        fechaInicial = DateTime.now();
      }
    } else {
      fechaInicial = DateTime.now();
    }

    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Seleccionar Fecha de Finalización',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada == null) return;

    // Preguntar si también quiere seleccionar hora
    final incluirHora = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hora de finalización'),
        content: const Text('¿Desea especificar también la hora?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Solo fecha'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Agregar hora'),
          ),
        ],
      ),
    );

    DateTime fechaFinal = fechaSeleccionada;

    if (incluirHora == true) {
      final horaSeleccionada = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(fechaInicial),
        helpText: 'Seleccionar Hora',
        cancelText: 'Cancelar',
        confirmText: 'Aceptar',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.deepPurple,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (horaSeleccionada != null) {
        fechaFinal = DateTime(
          fechaSeleccionada.year,
          fechaSeleccionada.month,
          fechaSeleccionada.day,
          horaSeleccionada.hour,
          horaSeleccionada.minute,
        );
      }
    }

    await _actualizarOrden({'fecha_finalizacion': fechaFinal.toIso8601String()});
  }

  // ==================== ACTUALIZAR INVENTARIO ====================
  
  Future<void> _actualizarItemInventario(int inventarioId, String campo, bool valor) async {
    try {
      final token = await _storage.read(key: 'access_token');

      // Actualizar el item específico en el backend
      await _ordenService.updateInventario(
        widget.ordenId,
        inventarioId,
        {campo: valor},
        token: token,
      );

      // Actualizar localmente sin recargar todo
      setState(() {
        final inventarios = _orden?['inventario_vehiculo'] as List<dynamic>?;
        if (inventarios != null && inventarios.isNotEmpty) {
          inventarios[0][campo] = valor;
        }
      });

      // Mostrar feedback sutil
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(valor ? 'Item marcado como presente' : 'Item desmarcado'),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar inventario: $e'),
          backgroundColor: Colors.red,
        ),
      );
      // Recargar para volver al estado correcto
      await _loadOrdenDetail();
    }
  }

  Future<void> _actualizarOrden(Map<String, dynamic> data) async {
    try {
      final token = await _storage.read(key: 'access_token');

      await _ordenService.updateOrden(widget.ordenId, data, token: token);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Actualizado exitosamente')),
      );
      await _loadOrdenDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $e')),
      );
    }
  }

  String _getNivelCombustibleLabel(dynamic nivel) {
    if (nivel == null) return 'No especificado';
    final nivelInt = nivel is int ? nivel : int.tryParse(nivel.toString()) ?? 0;
    
    switch (nivelInt) {
      case 0:
        return 'E (Vacío)';
      case 1:
        return '1/4';
      case 2:
        return '1/2';
      case 3:
        return '3/4';
      case 4:
        return 'F (Lleno)';
      default:
        return 'No especificado';
    }
  }

  // Mostrar imagen en diálogo full screen
  void _showImageDialog(String imageUrl, String descripcion) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
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
                    return const Center(
                      child: Icon(Icons.error, color: Colors.white, size: 60),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: Text(
                descripcion,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPERS ====================
  
  // Parsear valores que pueden venir como String o double desde el backend
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: children),
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

  Widget _buildEditableInfoRow(IconData icon, String label, String value, VoidCallback onEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.deepPurple),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== WIDGET: DIÁLOGO SELECCIÓN ITEM CON BUSCADOR ====================
class _DialogoSeleccionItem extends StatefulWidget {
  final List<dynamic> items;

  const _DialogoSeleccionItem({required this.items});

  @override
  State<_DialogoSeleccionItem> createState() => _DialogoSeleccionItemState();
}

class _DialogoSeleccionItemState extends State<_DialogoSeleccionItem> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _itemsFiltrados = [];

  @override
  void initState() {
    super.initState();
    _itemsFiltrados = widget.items;
    _searchController.addListener(_filtrarItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _itemsFiltrados = widget.items.where((item) {
        final nombre = (item['nombre'] ?? '').toString().toLowerCase();
        final descripcion = (item['descripcion'] ?? '').toString().toLowerCase();
        final precio = (item['precio'] ?? '').toString();
        
        return nombre.contains(query) || 
            descripcion.contains(query) || 
            precio.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Título
            const Text(
              'Seleccionar Item',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Buscador
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, descripción o precio...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Contador de resultados
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_itemsFiltrados.length} items',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            
            // Lista de items
            Expanded(
              child: _itemsFiltrados.isEmpty
                  ? const Center(
                      child: Text(
                        'No se encontraron items',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _itemsFiltrados.length,
                      itemBuilder: (context, index) {
                        final item = _itemsFiltrados[index];
                        final nombre = item['nombre'] ?? 'Sin nombre';
                        final descripcion = item['descripcion'] ?? '';
                        final precio = double.tryParse(item['precio']?.toString() ?? '0') ?? 0.0;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple.shade100,
                              child: const Icon(Icons.build, color: Colors.deepPurple),
                            ),
                            title: Text(
                              nombre,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (descripcion.isNotEmpty)
                                  Text(
                                    descripcion,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  'Precio: \$${precio.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => Navigator.pop(context, item),
                          ),
                        );
                      },
                    ),
            ),
            
            // Botón cancelar
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== WIDGET: DIÁLOGO SELECCIÓN TÉCNICO CON BUSCADOR ====================
class _DialogoSeleccionTecnico extends StatefulWidget {
  final List<dynamic> empleados;

  const _DialogoSeleccionTecnico({required this.empleados});

  @override
  State<_DialogoSeleccionTecnico> createState() => _DialogoSeleccionTecnicoState();
}

class _DialogoSeleccionTecnicoState extends State<_DialogoSeleccionTecnico> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _empleadosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _empleadosFiltrados = widget.empleados;
    _searchController.addListener(_filtrarEmpleados);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarEmpleados() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _empleadosFiltrados = widget.empleados;
      } else {
        _empleadosFiltrados = widget.empleados.where((empleado) {
          final nombre = (empleado['nombre'] ?? '').toLowerCase();
          final apellido = (empleado['apellido'] ?? '').toLowerCase();
          final cargo = (empleado['cargo']?['nombre'] ?? '').toLowerCase();
          final ci = (empleado['ci'] ?? '').toLowerCase();
          
          return nombre.contains(query) || 
                 apellido.contains(query) || 
                 cargo.contains(query) ||
                 ci.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Técnico'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Campo de búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, cargo o CI...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            
            // Contador de resultados
            Text(
              '${_empleadosFiltrados.length} técnico(s) encontrado(s)',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            
            // Lista de empleados filtrados
            Expanded(
              child: _empleadosFiltrados.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No se encontraron técnicos'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _empleadosFiltrados.length,
                      itemBuilder: (context, index) {
                        final empleado = _empleadosFiltrados[index];
                        final nombre = empleado['nombre'] ?? '';
                        final apellido = empleado['apellido'] ?? '';
                        final cargoNombre = empleado['cargo']?['nombre'] ?? 'Sin cargo';
                        final ci = empleado['ci'] ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child: Text(
                                nombre.isNotEmpty ? nombre[0].toUpperCase() : 'T',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text('$nombre $apellido'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cargoNombre, style: const TextStyle(fontSize: 12)),
                                if (ci.isNotEmpty)
                                  Text('CI: $ci', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            onTap: () => Navigator.pop(context, empleado),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

// ==================== WIDGET: DIÁLOGO INSPECCIÓN ====================
class _DialogoInspeccion extends StatefulWidget {
  final List<dynamic> empleados;
  final Map<String, dynamic>? inspeccionInicial;

  const _DialogoInspeccion({
    required this.empleados,
    this.inspeccionInicial,
  });

  @override
  State<_DialogoInspeccion> createState() => _DialogoInspeccionState();
}

class _DialogoInspeccionState extends State<_DialogoInspeccion> {
  final _observacionesController = TextEditingController();
  String _tipoInspeccion = 'ingreso';
  int? _tecnicoSeleccionado;
  String? _aceiteMotor;
  String? _filtrosVH;
  String? _nivelRefrigerante;
  String? _pastillasFreno;
  String? _estadoNeumaticos;
  String? _estadoBateria;
  String? _estadoLuces;

  @override
  void initState() {
    super.initState();
    if (widget.inspeccionInicial != null) {
      final insp = widget.inspeccionInicial!;
      _tipoInspeccion = insp['tipo_inspeccion'] ?? 'ingreso';
      _tecnicoSeleccionado = insp['tecnico'];
      _aceiteMotor = insp['aceite_motor'];
      _filtrosVH = insp['Filtros_VH'];
      _nivelRefrigerante = insp['nivel_refrigerante'];
      _pastillasFreno = insp['pastillas_freno'];
      _estadoNeumaticos = insp['Estado_neumaticos'];
      _estadoBateria = insp['estado_bateria'];
      _estadoLuces = insp['estado_luces'];
      _observacionesController.text = insp['observaciones_generales'] ?? '';
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.inspeccionInicial == null ? 'Nueva Inspección' : 'Editar Inspección'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tipo de inspección
            const Text('Tipo de Inspección:', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioGroup<String>(
              groupValue: _tipoInspeccion,
              onChanged: (value) => setState(() => _tipoInspeccion = value!),
              child: Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Ingreso'),
                      value: 'ingreso',
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Salida'),
                      value: 'salida',
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            
            // Técnico
            const Text('Técnico:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _tecnicoSeleccionado,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Seleccione un técnico',
              ),
              items: widget.empleados.map((emp) {
                return DropdownMenuItem<int>(
                  value: emp['id'],
                  child: Text('${emp['nombre']} ${emp['apellido']}'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _tecnicoSeleccionado = value),
            ),
            const SizedBox(height: 16),
            
            // Aceite motor
            _buildEstadoDropdown('Aceite motor', _aceiteMotor, ['bueno', 'malo'], (value) {
              setState(() => _aceiteMotor = value);
            }),
            
            // Filtros VH
            _buildEstadoDropdown('Filtros VH', _filtrosVH, ['bueno', 'malo'], (value) {
              setState(() => _filtrosVH = value);
            }),
            
            // Nivel refrigerante
            _buildNivelDropdown('Nivel refrigerante', _nivelRefrigerante, (value) {
              setState(() => _nivelRefrigerante = value);
            }),
            
            // Pastillas de freno
            _buildEstadoDropdown('Pastillas de freno', _pastillasFreno, ['bueno', 'malo'], (value) {
              setState(() => _pastillasFreno = value);
            }),
            
            // Estado neumáticos
            _buildEstadoDropdown('Estado neumáticos', _estadoNeumaticos, ['bueno', 'malo'], (value) {
              setState(() => _estadoNeumaticos = value);
            }),
            
            // Estado batería
            _buildNivelDropdown('Estado batería', _estadoBateria, (value) {
              setState(() => _estadoBateria = value);
            }),
            
            // Estado luces
            _buildEstadoDropdown('Estado luces', _estadoLuces, ['bueno', 'malo'], (value) {
              setState(() => _estadoLuces = value);
            }),
            
            const SizedBox(height: 16),
            // Observaciones
            TextField(
              controller: _observacionesController,
              decoration: const InputDecoration(
                labelText: 'Observaciones generales',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final data = <String, dynamic>{
              'tipo_inspeccion': _tipoInspeccion,
            };
            
            // Solo agregar campos si tienen valores
            if (_observacionesController.text.trim().isNotEmpty) {
              data['observaciones_generales'] = _observacionesController.text.trim();
            }
            
            if (_tecnicoSeleccionado != null) data['tecnico'] = _tecnicoSeleccionado;
            if (_aceiteMotor != null && _aceiteMotor!.isNotEmpty) data['aceite_motor'] = _aceiteMotor;
            if (_filtrosVH != null && _filtrosVH!.isNotEmpty) data['Filtros_VH'] = _filtrosVH;
            if (_nivelRefrigerante != null && _nivelRefrigerante!.isNotEmpty) data['nivel_refrigerante'] = _nivelRefrigerante;
            if (_pastillasFreno != null && _pastillasFreno!.isNotEmpty) data['pastillas_freno'] = _pastillasFreno;
            if (_estadoNeumaticos != null && _estadoNeumaticos!.isNotEmpty) data['Estado_neumaticos'] = _estadoNeumaticos;
            if (_estadoBateria != null && _estadoBateria!.isNotEmpty) data['estado_bateria'] = _estadoBateria;
            if (_estadoLuces != null && _estadoLuces!.isNotEmpty) data['estado_luces'] = _estadoLuces;
            
            Navigator.pop(context, data);
          },
          child: Text(widget.inspeccionInicial == null ? 'Crear' : 'Actualizar'),
        ),
      ],
    );
  }

  Widget _buildEstadoDropdown(String label, String? value, List<String> opciones, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: opciones.map((opcion) {
          return DropdownMenuItem<String>(
            value: opcion,
            child: Text(opcion == 'bueno' ? 'Buen estado' : 'Mal estado'),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNivelDropdown(String label, String? value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: 'alto', child: Text('Alto')),
          DropdownMenuItem(value: 'medio', child: Text('Medio')),
          DropdownMenuItem(value: 'bajo', child: Text('Bajo')),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

// ==================== WIDGET: DIÁLOGO PRUEBA DE RUTA ====================
class _DialogoPruebaRuta extends StatefulWidget {
  final List<dynamic> empleados;
  final Map<String, dynamic>? pruebaInicial;

  const _DialogoPruebaRuta({
    required this.empleados,
    this.pruebaInicial,
  });

  @override
  State<_DialogoPruebaRuta> createState() => _DialogoPruebaRutaState();
}

class _DialogoPruebaRutaState extends State<_DialogoPruebaRuta> {
  final _kmInicioController = TextEditingController();
  final _kmFinalController = TextEditingController();
  final _rutaController = TextEditingController();
  final _observacionesController = TextEditingController();
  String _tipoPrueba = 'inicial';
  int? _tecnicoSeleccionado;
  String _frenos = 'bueno';
  String _motor = 'bueno';
  String _suspension = 'bueno';
  String _direccion = 'bueno';

  @override
  void initState() {
    super.initState();
    if (widget.pruebaInicial != null) {
      final prueba = widget.pruebaInicial!;
      _tipoPrueba = prueba['tipo_prueba'] ?? 'inicial';
      _tecnicoSeleccionado = prueba['tecnico'];
      _kmInicioController.text = '${prueba['kilometraje_inicio'] ?? ''}';
      _kmFinalController.text = '${prueba['kilometraje_final'] ?? ''}';
      _rutaController.text = prueba['ruta'] ?? '';
      _frenos = prueba['frenos'] ?? 'bueno';
      _motor = prueba['motor'] ?? 'bueno';
      _suspension = prueba['suspension'] ?? 'bueno';
      _direccion = prueba['direccion'] ?? 'bueno';
      _observacionesController.text = prueba['observaciones'] ?? '';
    }
  }

  @override
  void dispose() {
    _kmInicioController.dispose();
    _kmFinalController.dispose();
    _rutaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.pruebaInicial == null ? 'Nueva Prueba de Ruta' : 'Editar Prueba de Ruta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tipo de prueba
            const Text('Tipo de Prueba:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              initialValue: _tipoPrueba,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'inicial', child: Text('Inicial')),
                DropdownMenuItem(value: 'intermedio', child: Text('Intermedio')),
                DropdownMenuItem(value: 'final', child: Text('Final')),
              ],
              onChanged: (value) => setState(() => _tipoPrueba = value!),
            ),
            const SizedBox(height: 16),
            
            // Técnico
            const Text('Técnico:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _tecnicoSeleccionado,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Seleccione un técnico',
              ),
              items: widget.empleados.map((emp) {
                return DropdownMenuItem<int>(
                  value: emp['id'],
                  child: Text('${emp['nombre']} ${emp['apellido']}'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _tecnicoSeleccionado = value),
            ),
            const SizedBox(height: 16),
            
            // Kilometrajes
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kmInicioController,
                    decoration: const InputDecoration(
                      labelText: 'Km Inicio',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _kmFinalController,
                    decoration: const InputDecoration(
                      labelText: 'Km Final',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Ruta
            TextField(
              controller: _rutaController,
              decoration: const InputDecoration(
                labelText: 'Descripción de la ruta',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            // Estado de componentes
            const Text('Estado de Componentes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildEstadoComponente('Frenos', _frenos, (value) => setState(() => _frenos = value)),
            _buildEstadoComponente('Motor', _motor, (value) => setState(() => _motor = value)),
            _buildEstadoComponente('Suspensión', _suspension, (value) => setState(() => _suspension = value)),
            _buildEstadoComponente('Dirección', _direccion, (value) => setState(() => _direccion = value)),
            const SizedBox(height: 16),
            
            // Observaciones
            TextField(
              controller: _observacionesController,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            // Validar que ruta no esté vacía
            if (_rutaController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Debe ingresar una descripción de la ruta')),
              );
              return;
            }
            
            final data = <String, dynamic>{
              'tipo_prueba': _tipoPrueba,
              'ruta': _rutaController.text.trim(),
              'frenos': _frenos,
              'motor': _motor,
              'suspension': _suspension,
              'direccion': _direccion,
              'observaciones': _observacionesController.text.trim(),
            };
            
            if (_tecnicoSeleccionado != null) data['tecnico'] = _tecnicoSeleccionado;
            
            final kmInicio = int.tryParse(_kmInicioController.text);
            if (kmInicio != null) data['kilometraje_inicio'] = kmInicio;
            
            final kmFinal = int.tryParse(_kmFinalController.text);
            if (kmFinal != null) data['kilometraje_final'] = kmFinal;
            
            Navigator.pop(context, data);
          },
          child: Text(widget.pruebaInicial == null ? 'Crear' : 'Actualizar'),
        ),
      ],
    );
  }

  Widget _buildEstadoComponente(String label, String value, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildOpcionEstado(
                  'Bueno',
                  Icons.check_circle,
                  Colors.green,
                  value == 'bueno',
                  () => onChanged('bueno'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOpcionEstado(
                  'Regular',
                  Icons.warning,
                  Colors.orange,
                  value == 'regular',
                  () => onChanged('regular'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOpcionEstado(
                  'Malo',
                  Icons.cancel,
                  Colors.red,
                  value == 'malo',
                  () => onChanged('malo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpcionEstado(String texto, IconData icono, Color color, bool seleccionado, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: seleccionado ? color.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(
            color: seleccionado ? color : Colors.grey[300]!,
            width: seleccionado ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              color: seleccionado ? color : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                color: seleccionado ? color : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
