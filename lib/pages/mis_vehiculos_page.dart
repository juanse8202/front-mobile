import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/vehiculo_service.dart';

class MisVehiculosPage extends StatefulWidget {
  const MisVehiculosPage({super.key});

  @override
  State<MisVehiculosPage> createState() => _MisVehiculosPageState();
}

class _MisVehiculosPageState extends State<MisVehiculosPage> {
  final VehiculoService _vehiculoService = VehiculoService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  List<dynamic> _vehiculos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
  }

  Future<void> _cargarVehiculos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _storage.read(key: 'access_token');
      final vehiculos = await _vehiculoService.fetchMisVehiculos(token: token);
      
      setState(() {
        _vehiculos = vehiculos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getTipoColor(String? tipo) {
    switch (tipo?.toUpperCase()) {
      case 'SEDAN':
        return Colors.blue;
      case 'SUV':
        return Colors.green;
      case 'CAMIONETA':
        return Colors.orange;
      case 'DEPORTIVO':
        return Colors.red;
      case 'HATCHBACK':
        return Colors.purple;
      case 'FURGON':
        return Colors.grey;
      case 'CITYCAR':
        return Colors.pink;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getTipoIcon(String? tipo) {
    switch (tipo?.toUpperCase()) {
      case 'SEDAN':
        return Icons.directions_car;
      case 'SUV':
        return Icons.drive_eta;
      case 'CAMIONETA':
        return Icons.local_shipping;
      case 'DEPORTIVO':
        return Icons.sports_motorsports;
      case 'HATCHBACK':
        return Icons.airport_shuttle;
      case 'FURGON':
        return Icons.fire_truck;
      case 'CITYCAR':
        return Icons.electric_car;
      default:
        return Icons.directions_car;
    }
  }

  String _getEstadoOrdenText(String? estado) {
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
        return 'Sin servicio';
    }
  }

  Color _getEstadoOrdenColor(String? estado) {
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mis Vehículos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_vehiculos.length} ${_vehiculos.length == 1 ? 'vehículo' : 'vehículos'}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando tus vehículos...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _cargarVehiculos,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _vehiculos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tienes vehículos registrados',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarVehiculos,
                      color: const Color(0xFF6366F1),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _vehiculos.length,
                        itemBuilder: (context, index) {
                          final vehiculo = _vehiculos[index];
                          return _buildVehiculoCard(vehiculo);
                        },
                      ),
                    ),
    );
  }

  Widget _buildVehiculoCard(Map<String, dynamic> vehiculo) {
    final placa = vehiculo['numero_placa']?.toString() ?? 'Sin placa';
    final marca = vehiculo['marca_nombre']?.toString() ?? '';
    final modelo = vehiculo['modelo_nombre']?.toString() ?? '';
    final year = vehiculo['año']?.toString() ?? '';
    final color = vehiculo['color']?.toString() ?? '';
    final tipo = vehiculo['tipo']?.toString() ?? '';
    final version = vehiculo['version']?.toString() ?? '';
    final combustible = vehiculo['tipo_combustible']?.toString() ?? '';
    final vin = vehiculo['vin']?.toString() ?? '';
    final fechaRegistro = vehiculo['fecha_registro']?.toString() ?? '';
    
    // Orden activa del vehículo
    final ordenActiva = vehiculo['orden_activa'];
    final estadoEnTaller = vehiculo['estado_en_taller'] as Map<String, dynamic>?;
    
    // Usar orden_activa si existe, sino usar estado_en_taller
    Map<String, dynamic>? ordenMasReciente;
    if (ordenActiva != null) {
      ordenMasReciente = ordenActiva as Map<String, dynamic>?;
    } else if (estadoEnTaller != null && estadoEnTaller['en_taller'] == true) {
      // Si está en taller pero no tiene orden activa, mostramos el estado
      ordenMasReciente = {
        'estado': 'en_taller',
        'descripcion': 'Vehículo en taller',
      };
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con placa y marca/modelo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getTipoColor(tipo),
                  _getTipoColor(tipo).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      placa,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$marca $modelo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTipoIcon(tipo),
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),

          // Estado de la orden más reciente
          if (ordenMasReciente != null)
            Builder(
              builder: (context) {
                final orden = ordenMasReciente!;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getEstadoOrdenColor(orden['estado']?.toString()).withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getEstadoOrdenColor(orden['estado']?.toString()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getEstadoOrdenText(orden['estado']?.toString()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (orden['id'] != null)
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/mi-orden-detail',
                              arguments: {'ordenId': orden['id']},
                            );
                          },
                          child: Text(
                            'Ver orden #${orden['numero_orden'] ?? orden['id']}',
                            style: const TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

          // Si tiene descripción de servicio
          if (ordenMasReciente != null && ordenMasReciente['descripcion'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                ordenMasReciente['descripcion'].toString(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Mensaje cuando no hay orden activa
          if (ordenMasReciente == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sin servicio activo',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Detalles del vehículo
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDetailRow('Tipo', tipo),
                if (year.isNotEmpty) _buildDetailRow('Año', year),
                if (color.isNotEmpty) _buildDetailRow('Color', color),
                if (version.isNotEmpty) _buildDetailRow('Versión', version),
                if (combustible.isNotEmpty)
                  _buildDetailRow('Combustible', combustible),
                if (vin.isNotEmpty) _buildDetailRow('VIN', vin),
                if (fechaRegistro.isNotEmpty)
                  _buildDetailRow(
                    'Registrado el',
                    _formatearFecha(fechaRegistro),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value ?? 'N/A',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      final months = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      return '${date.day} de ${months[date.month - 1]} de ${date.year}';
    } catch (e) {
      return fecha;
    }
  }
}
