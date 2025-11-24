import 'package:flutter/material.dart';
import '../api/presupuestos_api.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class PresupuestoDetallePage extends StatefulWidget {
  const PresupuestoDetallePage({super.key});

  @override
  State<PresupuestoDetallePage> createState() => _PresupuestoDetallePageState();
}

class _PresupuestoDetallePageState extends State<PresupuestoDetallePage>
    with SingleTickerProviderStateMixin {
  int? _presupuestoId;
  Map<String, dynamic>? _presupuesto;
  List<dynamic> _detalles = [];
  bool _loading = true;
  String? _error;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['id'] != null) {
      _presupuestoId = args['id'] as int;
      _loadPresupuesto();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPresupuesto() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await PresupuestosApi.fetchPresupuestoById(_presupuestoId!);
      setState(() {
        _presupuesto = data;
        _detalles = data['detalles'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el presupuesto: $e';
        _loading = false;
      });
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Está seguro de que desea eliminar este presupuesto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PresupuestosApi.deletePresupuesto(_presupuestoId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Presupuesto eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() => _error = 'Error al eliminar: $e');
      }
    }
  }

  Future<void> _handleEdit() async {
    final result = await Navigator.pushNamed(
      context,
      '/presupuesto-form',
      arguments: {'id': _presupuestoId},
    );

    if (result == true) {
      _loadPresupuesto();
    }
  }

  void _exportPDF() async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando PDF...')),
    );

    try {
      final bytes = await PresupuestosApi.exportPresupuestoPDF(_presupuestoId!);

      if (!mounted) return;

      // Usar directorio de la aplicación
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'presupuesto_$_presupuestoId.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ PDF guardado correctamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'ABRIR',
            textColor: Colors.white,
            onPressed: () {
              OpenFile.open(file.path);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportExcel() async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando Excel...')),
    );

    try {
      final bytes = await PresupuestosApi.exportPresupuestoExcel(_presupuestoId!);

      if (!mounted) return;

      // Usar directorio de la aplicación
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'presupuesto_$_presupuestoId.xlsx';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Excel guardado correctamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'ABRIR',
            textColor: Colors.white,
            onPressed: () {
              OpenFile.open(file.path);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'Bs. 0,00';
    final value = (amount is num)
        ? amount.toDouble()
        : double.parse(amount.toString());
    return 'Bs. ${value.toStringAsFixed(2)}';
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildStatusBadge(String? estado) {
    final estadoLower = (estado ?? 'pendiente').toLowerCase();
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (estadoLower) {
      case 'aprobado':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = 'Aprobado';
        icon = Icons.check_circle;
        break;
      case 'rechazado':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = 'Rechazado';
        icon = Icons.cancel;
        break;
      case 'cancelado':
        bgColor = Colors.grey.shade300;
        textColor = Colors.grey.shade800;
        label = 'Cancelado';
        icon = Icons.block;
        break;
      case 'pendiente':
      default:
        bgColor = Colors.yellow.shade100;
        textColor = Colors.yellow.shade900;
        label = 'Pendiente';
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_presupuesto == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Presupuesto no encontrado'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Presupuesto #${_presupuesto!['id']}'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar',
            onPressed: _handleEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Eliminar',
            onPressed: _handleDelete,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: _exportPDF,
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Exportar Excel',
            onPressed: _exportExcel,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con estado y fecha
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fecha: ${_formatDate(_presupuesto!['fecha_inicio'])}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    _buildStatusBadge(_presupuesto!['estado']),
                  ],
                ),
              ],
            ),
          ),

          // Cards de información
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _buildClienteCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildVehiculoCard()),
              ],
            ),
          ),

          // Resumen financiero
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildResumenCard(),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
            tabs: const [
              Tab(text: 'Detalles', icon: Icon(Icons.list)),
              Tab(text: 'Diagnóstico', icon: Icon(Icons.description)),
            ],
          ),

          // Contenido de tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildDetallesTab(), _buildDiagnosticoTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  'Cliente',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _presupuesto!['cliente_nombre'] ?? 'Sin cliente',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiculoCard() {
    final vehiculo = _presupuesto!['vehiculo'];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.directions_car, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'Vehículo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (vehiculo != null) ...[
              Text(
                'Placa: ${vehiculo['placa'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Marca: ${vehiculo['marca'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Modelo: ${vehiculo['modelo'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 12),
              ),
            ] else
              const Text(
                'Sin vehículo',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCard() {
    return Card(
      elevation: 2,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text(_formatCurrency(_presupuesto!['subtotal'])),
              ],
            ),
            if ((double.tryParse(
                      _presupuesto!['total_descuentos']?.toString() ?? '0.0',
                    ) ??
                    0.0) >
                0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Descuentos:',
                    style: TextStyle(color: Colors.red),
                  ),
                  Text(
                    '-${_formatCurrency(_presupuesto!['total_descuentos'])}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ],
            if (_presupuesto!['con_impuestos'] == true &&
                (double.tryParse(
                          _presupuesto!['monto_impuesto']?.toString() ?? '0.0',
                        ) ??
                        0.0) >
                    0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'IVA (${_presupuesto!['impuestos']}%):',
                    style: const TextStyle(color: Colors.blue),
                  ),
                  Text(
                    _formatCurrency(_presupuesto!['monto_impuesto']),
                    style: const TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  _formatCurrency(_presupuesto!['total']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetallesTab() {
    if (_detalles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay detalles registrados'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _detalles.length,
      itemBuilder: (context, index) {
        final detalle = _detalles[index];
        final cantidad =
            double.tryParse(detalle['cantidad']?.toString() ?? '0') ?? 0.0;
        final precio =
            double.tryParse(detalle['precio_unitario']?.toString() ?? '0') ??
            0.0;
        final desc =
            double.tryParse(
              detalle['descuento_porcentaje']?.toString() ?? '0',
            ) ??
            0.0;
        final subtotalSinDesc = cantidad * precio;
        final descMonto = subtotalSinDesc * (desc / 100);
        final subtotalFinal = subtotalSinDesc - descMonto;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              detalle['item']?['nombre'] ?? 'Item no especificado',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cantidad: ${cantidad.toStringAsFixed(2)}'),
                Text('Precio unit.: ${_formatCurrency(precio)}'),
                if (desc > 0)
                  Text(
                    'Descuento: $desc%',
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
            trailing: Text(
              _formatCurrency(subtotalFinal),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiagnosticoTab() {
    final diagnostico = _presupuesto!['diagnostico'];

    if (diagnostico == null || diagnostico.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay diagnóstico registrado'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            diagnostico,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ),
    );
  }
}
