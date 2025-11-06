import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/reporte_service.dart';

class ReportesEstaticosPage extends StatefulWidget {
  const ReportesEstaticosPage({super.key});

  @override
  State<ReportesEstaticosPage> createState() => _ReportesEstaticosPageState();
}

class _ReportesEstaticosPageState extends State<ReportesEstaticosPage> {
  final _storage = const FlutterSecureStorage();
  final _reporteService = ReporteService();
  
  bool _isLoading = false;
  bool _isLoadingReportes = true;
  String? _token;
  
  List<dynamic> _reportesDisponibles = [];
  List<dynamic> _historialReportes = [];
  
  String? _tipoReporteSeleccionado;
  String _formatoSeleccionado = 'PDF';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    _token = await _storage.read(key: 'access_token');
    await _cargarReportesDisponibles();
    await _cargarHistorial();
  }

  Future<void> _cargarReportesDisponibles() async {
    setState(() => _isLoadingReportes = true);
    
    final resultado = await _reporteService.obtenerReportesDisponibles(token: _token);
    
    if (resultado['success']) {
      setState(() {
        _reportesDisponibles = resultado['reportes'] ?? [];
        _isLoadingReportes = false;
      });
    } else {
      setState(() => _isLoadingReportes = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado['message'] ?? 'Error al cargar reportes')),
        );
      }
    }
  }

  Future<void> _cargarHistorial() async {
    final resultado = await _reporteService.obtenerHistorialReportes(token: _token);
    
    if (resultado['success']) {
      setState(() {
        _historialReportes = resultado['reportes'] ?? [];
      });
    }
  }

  Future<void> _generarReporte() async {
    if (_tipoReporteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un tipo de reporte')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await _reporteService.generarReporteEstatico(
      tipoReporte: _tipoReporteSeleccionado!,
      formato: _formatoSeleccionado,
      fechaInicio: _fechaInicio?.toIso8601String().split('T')[0],
      fechaFin: _fechaFin?.toIso8601String().split('T')[0],
      token: _token,
    );

    setState(() => _isLoading = false);

    if (resultado['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['message'] ?? 'Reporte generado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recargar historial
        await _cargarHistorial();
        
        // Mostrar opción de descargar
        if (resultado['reporte'] != null && resultado['reporte']['id'] != null) {
          _mostrarDialogoDescarga(resultado['reporte']);
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['message'] ?? 'Error al generar reporte'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoDescarga(Map<String, dynamic> reporte) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reporte Generado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${reporte['nombre'] ?? 'Sin nombre'}'),
            const SizedBox(height: 8),
            Text('Registros: ${reporte['registros_procesados'] ?? 0}'),
            const SizedBox(height: 8),
            Text('Formato: ${reporte['formato'] ?? 'PDF'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _descargarReporte(reporte['id']);
            },
            icon: const Icon(Icons.download),
            label: const Text('Descargar'),
          ),
        ],
      ),
    );
  }

  Future<void> _descargarReporte(int reporteId) async {
    try {
      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Descargando reporte...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Solicitar permisos de almacenamiento (solo para Android < 13)
      if (Platform.isAndroid) {
        // Para Android 13+ no necesitamos permiso para escribir en Downloads
        // Para Android 10-12 necesitamos WRITE_EXTERNAL_STORAGE
        final androidInfo = await Permission.storage.status;
        if (!androidInfo.isGranted && !androidInfo.isPermanentlyDenied) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Permiso de almacenamiento denegado. Los archivos se guardarán en la carpeta de la app.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );
            }
            // Continuar de todas formas, guardar en directorio de la app
          }
        }
      }

      // Descargar el archivo
      final resultado = await _reporteService.descargarReporte(
        reporteId: reporteId,
        token: _token,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (resultado['success']) {
        // Obtener directorio de descargas
        Directory? directory;
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else if (Platform.isIOS) {
          directory = await getApplicationDocumentsDirectory();
        } else {
          directory = await getDownloadsDirectory();
        }

        if (directory == null) {
          throw Exception('No se pudo acceder al directorio de descargas');
        }

        // Determinar extensión del archivo
        final contentType = resultado['contentType'] as String;
        final extension = contentType.contains('pdf') ? 'pdf' : 'xlsx';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'reporte_$reporteId\_$timestamp.$extension';
        final filePath = '${directory.path}/$fileName';

        // Guardar el archivo
        final file = File(filePath);
        await file.writeAsBytes(resultado['bytes']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reporte descargado: $fileName'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Abrir',
                textColor: Colors.white,
                onPressed: () async {
                  await OpenFile.open(filePath);
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }

        // Intentar abrir el archivo automáticamente
        await OpenFile.open(filePath);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado['message'] ?? 'Error al descargar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fechaSeleccionada;
        } else {
          _fechaFin = fechaSeleccionada;
        }
      });
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar';
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Estáticos'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoadingReportes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sección de generación
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Generar Nuevo Reporte',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Tipo de reporte
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Reporte',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.insert_chart),
                            ),
                            value: _tipoReporteSeleccionado,
                            isExpanded: true,
                            items: _reportesDisponibles.map((reporte) {
                              return DropdownMenuItem<String>(
                                value: reporte['id'],
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 280),
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        reporte['nombre'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      if (reporte['descripcion'] != null)
                                        Text(
                                          reporte['descripcion'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _tipoReporteSeleccionado = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Formato
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Formato',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.picture_as_pdf),
                            ),
                            value: _formatoSeleccionado,
                            items: const [
                              DropdownMenuItem(value: 'PDF', child: Text('PDF')),
                              DropdownMenuItem(value: 'XLSX', child: Text('Excel (XLSX)')),
                            ],
                            onChanged: (value) {
                              setState(() => _formatoSeleccionado = value!);
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Filtros de fecha (opcional)
                          const Text(
                            'Filtros de Fecha (Opcional)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _seleccionarFecha(true),
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(_formatearFecha(_fechaInicio)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _seleccionarFecha(false),
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(_formatearFecha(_fechaFin)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_fechaInicio != null || _fechaFin != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _fechaInicio = null;
                                    _fechaFin = null;
                                  });
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Limpiar fechas'),
                              ),
                            ),
                          const SizedBox(height: 24),
                          
                          // Botón generar
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _generarReporte,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.play_arrow),
                              label: Text(_isLoading ? 'Generando...' : 'Generar Reporte'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Historial de reportes
                  const Text(
                    'Historial de Reportes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  _historialReportes.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.inbox, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'No hay reportes generados',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _historialReportes.length,
                          itemBuilder: (context, index) {
                            final reporte = _historialReportes[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: reporte['formato'] == 'PDF'
                                      ? Colors.red
                                      : Colors.green,
                                  child: Icon(
                                    reporte['formato'] == 'PDF'
                                        ? Icons.picture_as_pdf
                                        : Icons.table_chart,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(reporte['nombre'] ?? 'Sin nombre'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (reporte['descripcion'] != null)
                                      Text(reporte['descripcion']),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Generado: ${_formatearFechaCompleta(reporte['fecha_generacion'])}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Registros: ${reporte['registros_procesados'] ?? 0}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () => _descargarReporte(reporte['id']),
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  String _formatearFechaCompleta(String? fecha) {
    if (fecha == null) return 'N/A';
    try {
      final dt = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return fecha;
    }
  }
}
