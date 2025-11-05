import 'package:flutter/material.dart';
import '../services/area_service.dart';

class AreasPage extends StatefulWidget {
  const AreasPage({super.key});

  @override
  State<AreasPage> createState() => _AreasPageState();
}

class _AreasPageState extends State<AreasPage> {
  final AreaService _areaService = AreaService();
  List<dynamic> areas = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await _areaService.getAreas();

    if (response['success']) {
      setState(() {
        areas = response['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = response['message'];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Áreas'),
        backgroundColor: Colors.cyan,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAreas,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : areas.isEmpty
                  ? const Center(child: Text('No hay áreas disponibles'))
                  : RefreshIndicator(
                      onRefresh: _loadAreas,
                      child: ListView.builder(
                        itemCount: areas.length,
                        itemBuilder: (context, index) {
                          final area = areas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.cyan,
                                child: Icon(
                                  Icons.category,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                area['nombre'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: area['descripcion'] != null
                                  ? Text(area['descripcion'])
                                  : null,
                              trailing: Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                // Navegar a detalle del área si existe
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
