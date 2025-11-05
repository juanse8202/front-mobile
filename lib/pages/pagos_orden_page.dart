import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/pago_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/pagar_con_stripe.dart';

class PagosOrdenPage extends StatefulWidget {
  const PagosOrdenPage({super.key});

  @override
  State<PagosOrdenPage> createState() => _PagosOrdenPageState();
}

class _PagosOrdenPageState extends State<PagosOrdenPage> {
  final _storage = const FlutterSecureStorage();
  final _pagoService = PagoService();
  
  List<dynamic> _pagos = [];
  bool _isLoading = false;
  String? _token;
  int? _ordenId;
  double? _totalOrden;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && _ordenId == null) {
      _ordenId = args['orden_id'];
      _totalOrden = args['total'];
      _cargarToken();
    }
  }

  Future<void> _cargarToken() async {
    _token = await _storage.read(key: 'access_token');
    if (_token != null && _ordenId != null) {
      _cargarPagos();
    }
  }

  Future<void> _cargarPagos() async {
    if (_ordenId == null) return;
    
    setState(() => _isLoading = true);
    
    final result = await _pagoService.getPagosOrden(_ordenId!, token: _token);
    
    setState(() => _isLoading = false);
    
    if (result['success']) {
      setState(() {
        _pagos = result['data'] is List ? result['data'] : [];
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Error al cargar pagos')),
        );
      }
    }
  }

  void _mostrarDialogoPagoManual() {
    if (_ordenId == null) return;
    
    final formKey = GlobalKey<FormState>();
    final montoController = TextEditingController(
      text: _totalOrden != null ? _totalOrden!.toStringAsFixed(2) : '',
    );
    String metodoPago = 'efectivo';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.payment, color: Colors.deepPurple),
              SizedBox(width: 10),
              Text('Registrar Pago'),
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
                      DropdownMenuItem(value: 'efectivo', child: Text('💵 Efectivo')),
                      DropdownMenuItem(value: 'tarjeta', child: Text('💳 Tarjeta')),
                      DropdownMenuItem(value: 'transferencia', child: Text('🏦 Transferencia')),
                      DropdownMenuItem(value: 'cheque', child: Text('📄 Cheque')),
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

  Future<void> _registrarPagoManual(double monto, String metodo) async {
    if (_ordenId == null) return;
    
    setState(() => _isLoading = true);

    final pagoData = {
      'orden': _ordenId,
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

  Future<void> _procesarPagoStripe() async {
    if (_ordenId == null) return;
    
    // Mostrar diálogo con el widget de Stripe
    if (!mounted) return;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PagarConStripe(
            ordenTrabajoId: _ordenId!,
            monto: _totalOrden ?? 0,
            ordenNumero: '#$_ordenId',
            token: _token,
            onSuccess: (data) {
              Navigator.pop(context); // Cerrar diálogo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Pago procesado exitosamente con Stripe'),
                  backgroundColor: Colors.green,
                ),
              );
              _cargarPagos(); // Recargar lista de pagos
            },
            onCancel: () {
              Navigator.pop(context); // Cerrar diálogo
            },
          ),
        ),
      ),
    );
  }

  double _getTotalPagado() {
    return _pagos.fold(0.0, (sum, pago) => sum + (pago['monto'] ?? 0));
  }

  double _getSaldo() {
    if (_totalOrden == null) return 0.0;
    return _totalOrden! - _getTotalPagado();
  }

  @override
  Widget build(BuildContext context) {
    final totalPagado = _getTotalPagado();
    final saldo = _getSaldo();

    return Scaffold(
      appBar: AppBar(
        title: Text('Pagos Orden #$_ordenId'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Resumen de pagos
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResumenItem('Total', _totalOrden ?? 0, Icons.receipt),
                    _buildResumenItem('Pagado', totalPagado, Icons.check_circle),
                    _buildResumenItem('Saldo', saldo, Icons.account_balance_wallet),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _mostrarDialogoPagoManual,
                      icon: const Icon(Icons.payment),
                      label: const Text('Pago Manual'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _procesarPagoStripe,
                      icon: const Icon(Icons.credit_card),
                      label: const Text('Pagar con Stripe'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Lista de pagos
          Expanded(
            child: _isLoading
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
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _pagos.length,
                            itemBuilder: (context, index) {
                              final pago = _pagos[index];
                              return _buildPagoCard(pago);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem(String label, double valor, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${valor.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPagoCard(Map<String, dynamic> pago) {
    final monto = (pago['monto'] ?? 0).toDouble();
    final metodo = pago['metodo_pago'] ?? 'N/A';
    final estado = pago['estado'] ?? 'pendiente';
    final fecha = pago['fecha_pago'] ?? pago['created_at'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: estado == 'completado'
              ? Colors.green.shade100
              : Colors.orange.shade100,
          child: Icon(
            Icons.payment,
            color: estado == 'completado'
                ? Colors.green.shade700
                : Colors.orange.shade700,
          ),
        ),
        title: Text(
          '\$${monto.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Método: $metodo'),
            Text('Fecha: ${fecha.split('T')[0]}'),
          ],
        ),
        trailing: Chip(
          label: Text(estado.toUpperCase()),
          backgroundColor: estado == 'completado'
              ? Colors.green.shade100
              : Colors.orange.shade100,
          labelStyle: TextStyle(
            color: estado == 'completado'
                ? Colors.green.shade800
                : Colors.orange.shade800,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
