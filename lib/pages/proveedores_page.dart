import 'package:flutter/material.dart';
import '../services/proveedor_service.dart';

class ProveedoresPage extends StatefulWidget {
  const ProveedoresPage({super.key});

  @override
  State<ProveedoresPage> createState() => _ProveedoresPageState();
}

class _ProveedoresPageState extends State<ProveedoresPage> {
  final ProveedorService _proveedorService = ProveedorService();
  List<dynamic> proveedores = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProveedores();
  }

  Future<void> _loadProveedores() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await _proveedorService.getProveedores();

    if (response['success']) {
      setState(() {
        proveedores = response['data'];
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
        title: const Text('Proveedores'),
        backgroundColor: Colors.teal,
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
                        onPressed: _loadProveedores,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : proveedores.isEmpty
                  ? const Center(child: Text('No hay proveedores disponibles'))
                  : RefreshIndicator(
                      onRefresh: _loadProveedores,
                      child: ListView.builder(
                        itemCount: proveedores.length,
                        itemBuilder: (context, index) {
                          final proveedor = proveedores[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal,
                                child: Icon(
                                  Icons.local_shipping,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                proveedor['nombre'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (proveedor['telefono'] != null)
                                    Text('Tel: ${proveedor['telefono']}'),
                                  if (proveedor['email'] != null)
                                    Text(proveedor['email']),
                                ],
                              ),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                // Navegar a detalle del proveedor si existe
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
