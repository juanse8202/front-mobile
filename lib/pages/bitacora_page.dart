import 'package:flutter/material.dart';
import '../services/bitacora_service.dart';
import 'package:intl/intl.dart';

class BitacoraPage extends StatefulWidget {
  const BitacoraPage({super.key});

  @override
  State<BitacoraPage> createState() => _BitacoraPageState();
}

class _BitacoraPageState extends State<BitacoraPage> {
  final _bitacoraService = BitacoraService();
  
  List<Map<String, dynamic>> _registros = [];
  List<Map<String, dynamic>> _registrosFiltrados = [];
  bool _isLoading = false;
  String _searchText = '';
  String _ipFilter = '';
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarBitacora();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _cargarBitacora() async {
    setState(() => _isLoading = true);
    
    final result = await _bitacoraService.getBitacoras();
    
    if (result['success']) {
      final data = result['data'];
      final registros = data is List 
          ? data.cast<Map<String, dynamic>>() 
          : <Map<String, dynamic>>[];
      setState(() {
        _registros = registros;
        _aplicarFiltros();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Error al cargar la bitácora')),
        );
      }
    }
  }

  void _aplicarFiltros() {
    List<Map<String, dynamic>> filtrados = _registros;

    // Filtrar por búsqueda de texto
    if (_searchText.isNotEmpty) {
      filtrados = filtrados.where((registro) {
        final descripcion = registro['descripcion']?.toString().toLowerCase() ?? '';
        final usuario = registro['usuario']?.toString().toLowerCase() ?? '';
        final modulo = registro['modulo']?.toString().toLowerCase() ?? '';
        final accion = registro['accion']?.toString().toLowerCase() ?? '';
        final searchLower = _searchText.toLowerCase();
        return descripcion.contains(searchLower) || 
               usuario.contains(searchLower) ||
               modulo.contains(searchLower) ||
               accion.contains(searchLower);
      }).toList();
    }

    // Filtrar por IP
    if (_ipFilter.isNotEmpty) {
      filtrados = filtrados.where((registro) {
        final ip = registro['ip_address']?.toString() ?? '';
        return ip.contains(_ipFilter);
      }).toList();
    }

    setState(() {
      _registrosFiltrados = filtrados;
    });
  }

  String _formatearFecha(String? fechaStr) {
    if (fechaStr == null) return 'N/A';
    try {
      // Parsear la fecha UTC del servidor
      final fechaUTC = DateTime.parse(fechaStr);
      // Convertir a hora de Bolivia (UTC-4)
      final fechaBolivia = fechaUTC.subtract(const Duration(hours: 4));
      return DateFormat('dd/MM/yyyy, HH:mm:ss').format(fechaBolivia);
    } catch (e) {
      return fechaStr;
    }
  }

  Color _getAccionColor(String accion) {
    switch (accion.toUpperCase()) {
      case 'LOGIN':
        return Colors.pink.shade400;
      case 'CREAR':
        return Colors.green.shade400;
      case 'EDITAR':
        return Colors.orange.shade400;
      case 'ELIMINAR':
        return Colors.red.shade400;
      case 'CONSULTAR':
        return Colors.blue.shade400;
      case 'LOGOUT':
        return Colors.grey.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  Color _getModuloColor(String modulo) {
    switch (modulo) {
      case 'Autenticacion':
        return Colors.pink.shade400;
      case 'Cliente':
        return Colors.blue.shade400;
      case 'Vehiculo':
        return Colors.purple.shade400;
      case 'Cita':
        return Colors.teal.shade400;
      case 'OrdenTrabajo':
        return Colors.indigo.shade400;
      case 'Presupuesto':
        return Colors.amber.shade600;
      case 'Item':
        return Colors.cyan.shade400;
      case 'Empleado':
        return Colors.deepOrange.shade400;
      case 'Cargo':
        return Colors.brown.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bitácora del Sistema'),
            Text('Registro de todas las acciones realizadas en el sistema', style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarBitacora,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buscar en bitácora',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Buscar en descripción...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchText = value;
                            _aplicarFiltros();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _ipController,
                        decoration: const InputDecoration(
                          hintText: 'Ej: 192.168.1.1',
                          labelText: 'Filtrar por IP',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _ipFilter = value;
                            _aplicarFiltros();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.filter_list_off),
                      label: const Text('Limpiar'),
                      onPressed: () {
                        _searchController.clear();
                        _ipController.clear();
                        setState(() {
                          _searchText = '';
                          _ipFilter = '';
                          _aplicarFiltros();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Tabla de registros
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _cargarBitacora,
                    child: _registrosFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history, size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 20),
                                Text(
                                  _registros.isEmpty
                                      ? 'No hay registros de bitácora'
                                      : 'No se encontraron registros',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                                columns: const [
                                  DataColumn(label: Text('FECHA', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('USUARIO', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('IP', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('ACCIÓN', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('MÓDULO', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('DESCRIPCIÓN', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: _registrosFiltrados.map((registro) {
                                  final fecha = _formatearFecha(registro['fecha_accion']);
                                  final usuario = registro['usuario']?.toString() ?? 'N/A';
                                  final ip = registro['ip_address']?.toString() ?? '-';
                                  final accion = registro['accion']?.toString() ?? 'N/A';
                                  final modulo = registro['modulo']?.toString() ?? 'N/A';
                                  final descripcion = registro['descripcion']?.toString() ?? '';
                                  
                                  return DataRow(cells: [
                                    DataCell(Text(fecha, style: const TextStyle(fontSize: 12))),
                                    DataCell(Text(usuario, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                                    DataCell(Text(ip, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getAccionColor(accion),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          accion,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getModuloColor(modulo),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          modulo,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 300),
                                        child: Text(
                                          descripcion,
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
