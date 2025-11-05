import 'package:flutter/material.dart';
import '../services/cita_service.dart';
import '../widgets/custom_text_field.dart';

class CitasPage extends StatefulWidget {
  const CitasPage({super.key});

  @override
  State<CitasPage> createState() => _CitasPageState();
}

class _CitasPageState extends State<CitasPage> {
  final CitaService _citaService = CitaService();
  List<dynamic> citas = [];
  bool loading = true;
  String? token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    token = args?['token'] as String?;
    if (token != null) {
      _cargarCitas();
    }
  }

  Future<void> _cargarCitas() async {
    setState(() => loading = true);
    final result = await _citaService.getCitas(token: token);
    
    if (result['success']) {
      setState(() {
        citas = result['data'] as List<dynamic>;
        loading = false;
      });
    } else {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Error al cargar citas')),
        );
      }
    }
  }

  Future<void> _mostrarDialogoNuevaCita() async {
    final fechaController = TextEditingController();
    final horaController = TextEditingController();
    final motivoController = TextEditingController();
    final vehiculoController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          decoration: const BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: const Center(
            child: Text(
              'Nueva Cita',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: fechaController,
                label: 'Fecha (YYYY-MM-DD)',
                prefixIcon: Icons.calendar_today,
                filled: true,
                validator: (v) => null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: horaController,
                label: 'Hora (HH:MM)',
                prefixIcon: Icons.access_time,
                filled: true,
                validator: (v) => null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: motivoController,
                label: 'Motivo',
                prefixIcon: Icons.description,
                filled: true,
                validator: (v) => null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: vehiculoController,
                label: 'ID Vehículo',
                prefixIcon: Icons.directions_car,
                filled: true,
                validator: (v) => null,
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.deepPurple.shade700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              child: Text('Crear'),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await _crearCita(
        fechaController.text,
        horaController.text,
        motivoController.text,
        vehiculoController.text,
      );
    }
  }

  Future<void> _crearCita(
      String fecha, String hora, String motivo, String vehiculoId) async {
    final citaData = {
      'fecha': fecha,
      'hora': hora,
      'motivo': motivo,
      'vehiculo': int.tryParse(vehiculoId) ?? 0,
      'estado': 'pendiente',
    };

    final result = await _citaService.crearCita(citaData, token: token);

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita creada exitosamente')),
        );
      }
      _cargarCitas();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al crear cita'),
          ),
        );
      }
    }
  }

  Future<void> _cancelarCita(int citaId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar cancelación'),
        content: const Text('¿Estás seguro de cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final result = await _citaService.cancelarCita(citaId, token: token);
      
      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cita cancelada')),
          );
        }
        _cargarCitas();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Error')),
          );
        }
      }
    }
  }

  String _getEstadoColor(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'confirmada':
        return '🟢';
      case 'pendiente':
        return '🟡';
      case 'cancelada':
        return '🔴';
      default:
        return '⚪';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Mis Citas'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orangeAccent.shade700,
        onPressed: _mostrarDialogoNuevaCita,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : citas.isEmpty
              ? const Center(
                  child: Text('No tienes citas programadas'),
                )
              : RefreshIndicator(
                  onRefresh: _cargarCitas,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: citas.length,
                    itemBuilder: (context, i) {
                      final cita = citas[i] as Map<String, dynamic>;
                      return Card(
                        color: Colors.deepPurple.shade600,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.calendar_today,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                          title: Text(
                            '${_getEstadoColor(cita['estado'])} ${cita['motivo'] ?? 'Sin motivo'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '📅 ${cita['fecha']} ${cita['hora']}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                'Estado: ${cita['estado'] ?? 'Pendiente'}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          trailing: cita['estado']?.toLowerCase() != 'cancelada'
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _cancelarCita(cita['id']),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
