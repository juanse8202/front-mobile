import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/item_service.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final _storage = const FlutterSecureStorage();
  final _itemService = ItemService();
  final _searchController = TextEditingController();
  
  List<dynamic> _items = [];
  List<dynamic> _itemsFiltrados = [];
  bool _isLoading = false;
  String? _token;
  String? _filtroTipo;

  @override
  void initState() {
    super.initState();
    _cargarToken();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarToken() async {
    _token = await _storage.read(key: 'access_token');
    if (_token != null) {
      _cargarItems();
    }
  }

  Future<void> _cargarItems() async {
    setState(() => _isLoading = true);
    
    final result = await _itemService.getItems(token: _token);
    
    setState(() => _isLoading = false);
    
    if (result['success']) {
      setState(() {
        _items = result['data'] is List ? result['data'] : [];
        _itemsFiltrados = _items;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Error al cargar items')),
        );
      }
    }
  }

  void _filtrarItems(String query) {
    setState(() {
      if (query.isEmpty && _filtroTipo == null) {
        _itemsFiltrados = _items;
      } else {
        _itemsFiltrados = _items.where((item) {
          final nombre = (item['nombre'] ?? '').toString().toLowerCase();
          final descripcion = (item['descripcion'] ?? '').toString().toLowerCase();
          final codigo = (item['codigo'] ?? '').toString().toLowerCase();
          final tipo = item['tipo'] ?? '';
          
          final matchQuery = query.isEmpty || 
              nombre.contains(query.toLowerCase()) ||
              descripcion.contains(query.toLowerCase()) ||
              codigo.contains(query.toLowerCase());
          
          final matchTipo = _filtroTipo == null || tipo == _filtroTipo;
          
          return matchQuery && matchTipo;
        }).toList();
      }
    });
  }

  void _cambiarFiltroTipo(String? tipo) {
    setState(() {
      _filtroTipo = tipo;
      _filtrarItems(_searchController.text);
    });
  }

  void _mostrarDetalleItem(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getTipoIcon(item['tipo']),
                          color: Colors.deepPurple,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['nombre'] ?? 'Sin nombre',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Código: ${item['codigo'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Descripción', item['descripcion'] ?? 'Sin descripción', Icons.description),
                    _buildDetailRow('Precio', '\$${(item['precio'] ?? 0).toStringAsFixed(2)}', Icons.attach_money),
                    _buildDetailRow('Stock', '${item['stock'] ?? 0} unidades', Icons.inventory),
                    _buildDetailRow('Tipo', item['tipo'] ?? 'N/A', Icons.category),
                    _buildDetailRow('Estado', item['estado'] ?? 'disponible', Icons.info),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cerrar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.deepPurple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTipoIcon(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'taller':
        return Icons.build;
      case 'venta':
        return Icons.shopping_cart;
      case 'servicio':
        return Icons.handyman;
      default:
        return Icons.category;
    }
  }

  Color _getTipoColor(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'taller':
        return Colors.blue;
      case 'venta':
        return Colors.green;
      case 'servicio':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Servicios'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _filtrarItems,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, código o descripción...',
                    prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                // Filtros por tipo
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Todos', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('Taller', 'taller'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Venta', 'venta'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Servicio', 'servicio'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de items
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _cargarItems,
                    child: _itemsFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2, size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 20),
                                Text(
                                  _items.isEmpty 
                                      ? 'No hay items disponibles'
                                      : 'No se encontraron resultados',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _itemsFiltrados.length,
                            itemBuilder: (context, index) {
                              final item = _itemsFiltrados[index];
                              return _buildItemCard(item);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? tipo) {
    final isSelected = _filtroTipo == tipo;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _cambiarFiltroTipo(selected ? tipo : null),
      selectedColor: Colors.deepPurple,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.deepPurple,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,
      elevation: 2,
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final precio = (item['precio'] ?? 0).toDouble();
    final stock = item['stock'] ?? 0;
    final tipo = item['tipo'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _mostrarDetalleItem(item),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getTipoColor(tipo).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getTipoIcon(tipo),
                        color: _getTipoColor(tipo),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['nombre'] ?? 'Sin nombre',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Código: ${item['codigo'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(
                        '\$$precio',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.orangeAccent.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item['descripcion'] ?? 'Sin descripción',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      label: Text(
                        tipo.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getTipoColor(tipo),
                        ),
                      ),
                      backgroundColor: _getTipoColor(tipo).withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    Row(
                      children: [
                        Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Stock: $stock',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
