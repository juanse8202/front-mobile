import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/pago_service.dart';
import '../widgets/custom_text_field.dart';
import 'pago_detalle_page.dart';

class PagosPage extends StatefulWidget {
  const PagosPage({super.key});

  @override
  State<PagosPage> createState() => _PagosPageState();
}

class _PagosPageState extends State<PagosPage> {
  final _storage = const FlutterSecureStorage();
  final _pagoService = PagoService();
  
  List<dynamic> _pagos = [];
  bool _isLoading = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _cargarToken();
  }

  Future<void> _cargarToken() async {
    _token = await _storage.read(key: 'access_token');
    if (_token != null) {
      _cargarPagos();
    }
  }

  Future<void> _cargarPagos() async {
    setState(() => _isLoading = true);
    
    final result = await _pagoService.getHistorialPagos(token: _token);
    
    setState(() => _isLoading = false);
    
    if (result['success']) {
      setState(() {
        // Filtrar solo los pagos completados
        final todosPagos = result['data'] is List ? result['data'] : [];
        _pagos = todosPagos.where((pago) {
          final estado = pago['estado']?.toString().toLowerCase() ?? '';
          return estado == 'completado' || estado == 'succeeded';
        }).toList();
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Error al cargar pagos')),
        );
      }
    }
  }

  void _mostrarDialogoPagoManual(int ordenId, double total) {
    final formKey = GlobalKey<FormState>();
    final montoController = TextEditingController(text: total.toStringAsFixed(2));
    String metodoPago = 'efectivo';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.payment, color: Colors.deepPurple),
              SizedBox(width: 10),
              Text('Registrar Pago Manual'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: montoController,
                    label: 'Monto',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.attach_money,
                    filled: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese el monto';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Monto inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: metodoPago,
                    decoration: InputDecoration(
                      labelText: 'Método de Pago',
                      labelStyle: TextStyle(
                        fontWeight: Theme.of(context).brightness == Brightness.dark
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                      prefixIcon: const Icon(Icons.credit_card),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                      DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                      DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                      DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                    ],
                    onChanged: (value) {
                      setStateDialog(() => metodoPago = value!);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _registrarPagoManual(
                    ordenId,
                    double.parse(montoController.text),
                    metodoPago,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registrarPagoManual(int ordenId, double monto, String metodo) async {
    setState(() => _isLoading = true);

    final pagoData = {
      'orden': ordenId,
      'monto': monto,
      'metodo_pago': metodo,
      'estado': 'completado',
    };

    final result = await _pagoService.crearPagoManual(pagoData, token: _token);

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pago registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarPagos();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _procesarPagoStripe(int ordenId) async {
    setState(() => _isLoading = true);

    final result = await _pagoService.iniciarPagoStripe(ordenId, token: _token);

    setState(() => _isLoading = false);

    if (result['success']) {
      // Aquí se debería integrar el SDK de Stripe para Flutter
      // Por ahora mostramos el client_secret para pruebas
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Pago con Stripe'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Integración con Stripe en desarrollo.'),
                const SizedBox(height: 10),
                Text('Client Secret: ${result['data']['client_secret']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getMetodoIcon(String metodo) {
    switch (metodo.toLowerCase()) {
      case 'efectivo':
        return '💵';
      case 'tarjeta':
        return '💳';
      case 'transferencia':
        return '🏦';
      case 'cheque':
        return '📄';
      case 'stripe':
        return '💳';
      default:
        return '💰';
    }
  }

  String _getEstadoEmoji(String estado) {
    switch (estado.toLowerCase()) {
      case 'completado':
        return '✅';
      case 'pendiente':
        return '⏳';
      case 'fallido':
        return '❌';
      case 'cancelado':
        return '🚫';
      default:
        return '❓';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pagos'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarPagos,
              child: _pagos.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                          SizedBox(height: 20),
                          Text(
                            'No hay pagos registrados',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pagos.length,
                      itemBuilder: (context, index) {
                        final pago = _pagos[index];
                        // Manejar monto como String o número
                        final montoRaw = pago['monto'] ?? 0;
                        final monto = montoRaw is String 
                            ? double.tryParse(montoRaw) ?? 0.0
                            : (montoRaw is num ? montoRaw.toDouble() : 0.0);
                        final metodo = pago['metodo_pago'] ?? 'N/A';
                        final estado = pago['estado'] ?? 'pendiente';
                        final fecha = pago['fecha_pago'] ?? pago['created_at'] ?? 'N/A';

                        return InkWell(
                          onTap: () {
                            // Navegar a la página de detalles pasando el pago completo
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PagoDetallePage(pago: pago),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.deepPurple.shade50,
                                  Colors.white,
                                ],
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
                                      Text(
                                        _getEstadoEmoji(estado),
                                        style: const TextStyle(fontSize: 32),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Orden #${pago['orden_trabajo_numero'] ?? pago['orden_trabajo_id']?.toString() ?? pago['orden_trabajo']?.toString() ?? 'N/A'}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.deepPurple,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_getMetodoIcon(metodo)} $metodo',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          '\$${monto.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: Colors.orangeAccent.shade700,
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today,
                                              size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 6),
                                          Text(
                                            fecha.split('T')[0],
                                            style: TextStyle(color: Colors.grey[700]),
                                          ),
                                        ],
                                      ),
                                      Chip(
                                        label: Text(estado.toUpperCase()),
                                        backgroundColor: estado == 'completado'
                                            ? Colors.green.shade100
                                            : estado == 'pendiente'
                                                ? Colors.orange.shade100
                                                : Colors.red.shade100,
                                        labelStyle: TextStyle(
                                          color: estado == 'completado'
                                              ? Colors.green.shade800
                                              : estado == 'pendiente'
                                                  ? Colors.orange.shade800
                                                  : Colors.red.shade800,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ));
                      },
                    ),
            ),
    );
  }
}
