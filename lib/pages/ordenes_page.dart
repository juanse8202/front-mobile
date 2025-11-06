import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/orden_trabajo_service.dart';
import 'orden_detail_page.dart';

class OrdenesPage extends StatefulWidget {
  const OrdenesPage({Key? key}) : super(key: key);

  @override
  State<OrdenesPage> createState() => _OrdenesPageState();
}

class _OrdenesPageState extends State<OrdenesPage> {
  final OrdenTrabajoService _ordenService = OrdenTrabajoService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _todasLasOrdenes = []; // Todas las órdenes sin filtrar
  List<dynamic> _ordenesFiltradas = []; // Las órdenes filtradas que se muestran
  bool _isLoading = true;
  String? _error;
  String? _selectedEstado;
  String _searchQuery = '';

  final List<Map<String, String>> _estados = [
    {'value': '', 'label': 'Todos'},
    {'value': 'pendiente', 'label': 'Pendiente'},
    {'value': 'en_proceso', 'label': 'En Proceso'},
    {'value': 'finalizada', 'label': 'Finalizada'},
    {'value': 'entregada', 'label': 'Entregada'},
    {'value': 'cancelada', 'label': 'Cancelada'},
  ];

  @override
  void initState() {
    super.initState();
    _loadOrdenes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _aplicarFiltros();
  }

  Future<void> _loadOrdenes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _storage.read(key: 'access_token');
      
      // Obtener TODAS las órdenes del backend (sin filtro)
      print('🔍 Cargando todas las órdenes del backend...');
      final todasLasOrdenes = await _ordenService.fetchAll(
        token: token,
        estado: null, // No filtrar en el backend
      );
      
      print('📦 Total órdenes recibidas del backend: ${todasLasOrdenes.length}');
      
      setState(() {
        _todasLasOrdenes = todasLasOrdenes;
        _isLoading = false;
      });
      
      // Aplicar filtros después de cargar
      _aplicarFiltros();
    } catch (e) {
      print('❌ Error al cargar órdenes: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltros() {
    List<dynamic> ordenesFiltradas = _todasLasOrdenes;

    // Filtrar por estado
    if (_selectedEstado != null && _selectedEstado!.isNotEmpty) {
      ordenesFiltradas = ordenesFiltradas.where((orden) {
        return orden['estado'] == _selectedEstado;
      }).toList();
    }

    // Filtrar por búsqueda de texto
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      ordenesFiltradas = ordenesFiltradas.where((orden) {
        final ordenId = orden['id'].toString().toLowerCase();
        final clienteNombre = (orden['cliente_nombre'] ?? '').toString().toLowerCase();
        final vehiculoPlaca = (orden['vehiculo_placa'] ?? '').toString().toLowerCase();
        final vehiculoMarca = (orden['vehiculo_marca'] ?? '').toString().toLowerCase();
        final vehiculoModelo = (orden['vehiculo_modelo'] ?? '').toString().toLowerCase();
        
        return ordenId.contains(query) ||
               clienteNombre.contains(query) ||
               vehiculoPlaca.contains(query) ||
               vehiculoMarca.contains(query) ||
               vehiculoModelo.contains(query);
      }).toList();
    }

    setState(() {
      _ordenesFiltradas = ordenesFiltradas;
    });

    print('✅ Filtros aplicados - Mostrando ${ordenesFiltradas.length} órdenes');
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
        title: const Text('Órdenes de Trabajo'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrdenes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Buscador y filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Buscador
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar',
                    hintText: 'Cliente, placa, marca, modelo o #orden',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),
                // Filtro por estado
                DropdownButtonFormField<String>(
                  value: _selectedEstado ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por Estado',
                    prefixIcon: Icon(Icons.filter_list),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _estados.map((estado) {
                    return DropdownMenuItem<String>(
                      value: estado['value'],
                      child: Text(estado['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedEstado = value;
                    });
                    _aplicarFiltros();
                  },
                ),
              ],
            ),
          ),
          
          // Lista de órdenes
          Expanded(
            child: _isLoading
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
                              onPressed: _loadOrdenes,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _ordenesFiltradas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedEstado == null || _selectedEstado!.isEmpty
                                      ? 'No hay órdenes de trabajo'
                                      : 'No hay órdenes con estado "${_getEstadoLabel(_selectedEstado)}"',
                                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadOrdenes,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _ordenesFiltradas.length,
                              itemBuilder: (context, index) {
                                final orden = _ordenesFiltradas[index];
                                return _buildOrdenCard(orden);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/crear-orden');
          if (result == true) {
            // Recargar las órdenes después de crear una nueva
            _loadOrdenes();
          }
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Helper para parsear valores numéricos que pueden venir como String
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _confirmarEliminarOrden(int ordenId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Orden'),
        content: const Text('¿Está seguro de eliminar esta orden de trabajo? Esta acción no se puede deshacer.'),
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

    if (confirmar == true) {
      await _eliminarOrden(ordenId);
    }
  }

  Future<void> _eliminarOrden(int ordenId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await _ordenService.deleteOrden(ordenId, token: token);

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        // Recargar la lista de órdenes
        await _loadOrdenes();
      } else {
        throw Exception('No se pudo eliminar la orden');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading si está abierto
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar orden: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildOrdenCard(Map<String, dynamic> orden) {
    final ordenId = orden['id'];
    final estado = orden['estado'];
    final clienteNombre = orden['cliente_nombre'] ?? 'Sin cliente';
    final vehiculoPlaca = orden['vehiculo_placa'] ?? 'Sin placa';
    final vehiculoMarca = orden['vehiculo_marca'] ?? '';
    final vehiculoModelo = orden['vehiculo_modelo'] ?? '';
    final fechaCreacion = orden['fecha_creacion'] ?? '';
    final total = _parseDouble(orden['total']);
    final falloRequerimiento = orden['fallo_requerimiento'] ?? 'Sin descripción';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrdenDetailPage(ordenId: ordenId),
            ),
          ).then((_) => _loadOrdenes());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado: ID, Estado y botón eliminar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Orden #$ordenId',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(estado),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getEstadoLabel(estado),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmarEliminarOrden(ordenId),
                    tooltip: 'Eliminar orden',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Cliente
              Row(
                children: [
                  const Icon(Icons.person, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      clienteNombre,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Vehículo
              Row(
                children: [
                  const Icon(Icons.directions_car, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$vehiculoPlaca - $vehiculoMarca $vehiculoModelo',
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Fallo/Requerimiento
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.build, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      falloRequerimiento,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Fecha y Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        fechaCreacion.split('T')[0],
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
