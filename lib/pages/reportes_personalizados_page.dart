import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/reporte_service.dart';

class ReportesPersonalizadosPage extends StatefulWidget {
  const ReportesPersonalizadosPage({super.key});

  @override
  State<ReportesPersonalizadosPage> createState() => _ReportesPersonalizadosPageState();
}

class _ReportesPersonalizadosPageState extends State<ReportesPersonalizadosPage> {
  final _storage = const FlutterSecureStorage();
  final _reporteService = ReporteService();
  final _nombreController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _token;
  
  List<dynamic> _entidades = [];
  List<dynamic> _camposDisponibles = [];
  List<dynamic> _filtrosDisponibles = [];
  
  String? _entidadSeleccionada;
  String _formatoSeleccionado = 'PDF';
  List<String> _camposSeleccionados = [];
  Map<String, TextEditingController> _filtrosControllers = {};
  Map<String, dynamic> _filtrosValores = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    for (var controller in _filtrosControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    _token = await _storage.read(key: 'access_token');
    await _cargarEntidades();
  }

  Future<void> _cargarEntidades() async {
    setState(() => _isLoadingData = true);
    
    try {
      final resultado = await _reporteService.obtenerEntidadesDisponibles(token: _token);
      
      if (resultado['success']) {
        setState(() {
          // Asegurar que siempre sea una lista
          final entidadesData = resultado['entidades'];
          if (entidadesData is List) {
            _entidades = List<Map<String, dynamic>>.from(
              entidadesData.map((e) => Map<String, dynamic>.from(e))
            );
          } else if (entidadesData is Map) {
            _entidades = List<Map<String, dynamic>>.from(
              entidadesData.values.map((e) => Map<String, dynamic>.from(e))
            );
          } else {
            _entidades = [];
          }
          _isLoadingData = false;
        });
      } else {
        setState(() {
          _entidades = [];
          _isLoadingData = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resultado['message'] ?? 'Error al cargar entidades')),
          );
        }
      }
    } catch (e) {
      print('Error al cargar entidades: $e');
      setState(() {
        _entidades = [];
        _isLoadingData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _cargarCamposYFiltros(String entidadId) async {
    setState(() => _isLoadingData = true);
    
    try {
      final resultado = await _reporteService.obtenerCamposEntidad(
        entidadId: entidadId,
        token: _token,
      );
      
      if (resultado['success']) {
        setState(() {
          final campos = resultado['campos'];
          final filtros = resultado['filtros'];
          
          _camposDisponibles = campos is List ? List<Map<String, dynamic>>.from(
            campos.map((e) => Map<String, dynamic>.from(e))
          ) : [];
          
          _filtrosDisponibles = filtros is List ? List<Map<String, dynamic>>.from(
            filtros.map((e) => Map<String, dynamic>.from(e))
          ) : [];
          
          _camposSeleccionados.clear();
          _filtrosValores.clear();
          _filtrosControllers.clear();
          _isLoadingData = false;
        });
      } else {
        setState(() {
          _camposDisponibles = [];
          _filtrosDisponibles = [];
          _isLoadingData = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resultado['message'] ?? 'Error al cargar campos')),
          );
        }
      }
    } catch (e) {
      print('Error al cargar campos y filtros: $e');
      setState(() {
        _camposDisponibles = [];
        _filtrosDisponibles = [];
        _isLoadingData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _generarReporte() async {
    if (_entidadSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una entidad')),
      );
      return;
    }

    if (_camposSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un campo')),
      );
      return;
    }

    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre para el reporte')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Preparar filtros (solo los que tienen valor)
    final filtrosActivos = <String, dynamic>{};
    _filtrosValores.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        filtrosActivos[key] = value;
      }
    });

    final resultado = await _reporteService.generarReportePersonalizado(
      nombre: _nombreController.text.trim(),
      entidad: _entidadSeleccionada!,
      campos: _camposSeleccionados,
      formato: _formatoSeleccionado,
      filtros: filtrosActivos.isNotEmpty ? filtrosActivos : null,
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

      if (Platform.isAndroid) {
        final androidInfo = await Permission.storage.status;
        if (!androidInfo.isGranted && !androidInfo.isPermanentlyDenied) {
          await Permission.storage.request();
        }
      }

      final resultado = await _reporteService.descargarReporte(
        reporteId: reporteId,
        token: _token,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (resultado['success']) {
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

        final contentType = resultado['contentType'] as String;
        final extension = contentType.contains('pdf') ? 'pdf' : 'xlsx';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'reporte_$reporteId\_$timestamp.$extension';
        final filePath = '${directory.path}/$fileName';

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

  Widget _buildFiltro(Map<String, dynamic> filtro) {
    final tipo = filtro['tipo'] as String;
    final id = filtro['id'] as String;
    final label = filtro['label'] as String;

    switch (tipo) {
      case 'choice':
        final opciones = filtro['opciones'] as List;
        final valorActual = _filtrosValores[id]?.toString();
        
        // Encontrar la opción seleccionada
        final opcionSeleccionada = valorActual != null
            ? opciones.firstWhere(
                (opt) => opt['value'].toString() == valorActual,
                orElse: () => null,
              )
            : null;
        
        return InkWell(
          onTap: () async {
            final seleccion = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(label),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('(Sin filtro)'),
                      onTap: () => Navigator.pop(context, '__CLEAR__'),
                    ),
                    const Divider(),
                    ...opciones.map((opt) => ListTile(
                      title: Text(opt['label'].toString()),
                      selected: opt['value'].toString() == valorActual,
                      onTap: () => Navigator.pop(context, opt['value'].toString()),
                    )),
                  ],
                ),
              ),
            );
            
            if (seleccion != null) {
              setState(() {
                if (seleccion == '__CLEAR__') {
                  _filtrosValores.remove(id);
                } else {
                  _filtrosValores[id] = seleccion;
                }
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              opcionSeleccionada != null
                  ? opcionSeleccionada['label'].toString()
                  : '(Opcional)',
              style: TextStyle(
                color: opcionSeleccionada != null ? Colors.black : Colors.grey,
              ),
            ),
          ),
        );

      case 'date':
        _filtrosControllers[id] ??= TextEditingController();
        return TextFormField(
          controller: _filtrosControllers[id],
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (fecha != null) {
                  final fechaStr = fecha.toIso8601String().split('T')[0];
                  _filtrosControllers[id]!.text = fechaStr;
                  setState(() {
                    _filtrosValores[id] = fechaStr;
                  });
                }
              },
            ),
          ),
          readOnly: true,
        );

      case 'number':
        _filtrosControllers[id] ??= TextEditingController();
        return TextFormField(
          controller: _filtrosControllers[id],
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {
              _filtrosValores[id] = value.isEmpty ? null : double.tryParse(value);
            });
          },
        );

      case 'text':
      default:
        _filtrosControllers[id] ??= TextEditingController();
        return TextFormField(
          controller: _filtrosControllers[id],
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
            hintText: filtro['placeholder'],
          ),
          onChanged: (value) {
            setState(() {
              _filtrosValores[id] = value.isEmpty ? null : value;
            });
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Personalizados'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nombre del reporte
                  TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Reporte *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                      hintText: 'Ej: Órdenes del mes de enero',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selección de entidad
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Entidad *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.table_chart),
                    ),
                    value: _entidadSeleccionada,
                    hint: const Text('Selecciona una entidad'),
                    isExpanded: true,
                    items: _entidades.map((entidad) {
                      return DropdownMenuItem<String>(
                        value: entidad['id']?.toString(),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                entidad['nombre']?.toString() ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${entidad['total_campos']} campos - ${entidad['total_filtros']} filtros',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _entidadSeleccionada = value;
                        _camposSeleccionados.clear();
                        _filtrosValores.clear();
                        _filtrosControllers.clear();
                      });
                      if (value != null) {
                        _cargarCamposYFiltros(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_entidadSeleccionada != null) ...[
                    // Selección de campos
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Campos a Incluir *',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _camposDisponibles.map((campo) {
                                final isSelected = _camposSeleccionados.contains(campo['id']);
                                return FilterChip(
                                  label: Text(campo['label']),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _camposSeleccionados.add(campo['id']);
                                      } else {
                                        _camposSeleccionados.remove(campo['id']);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filtros
                    if (_filtrosDisponibles.isNotEmpty) ...[
                      ExpansionTile(
                        title: const Text(
                          'Filtros (Opcional)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        leading: const Icon(Icons.filter_list),
                        children: _filtrosDisponibles.map((filtro) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: _buildFiltro(filtro),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

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
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
