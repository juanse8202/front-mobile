# Código Faltante para presupuestos_page.dart

## ⚠️ IMPORTANTE
El archivo `presupuestos_page.dart` está incompleto. Falta agregar el resto del método `build()`.

## 📋 Lo que ya está implementado:
- ✅ Imports y estructura de la clase
- ✅ Datos de ejemplo con 6 presupuestos
- ✅ Controladores y variables de estado
- ✅ Método `_applyFilters()` 
- ✅ Métodos `_clearFilters()` y `_hasActiveFilters()`
- ✅ Diálogo de creación `_showCreateDialog()`
- ✅ Badge de estado `_buildStatusBadge()`
- ✅ Inicio del `build()` con barra de búsqueda (línea 470)

## 🔧 Código que falta agregar

Agregar **DESPUÉS de la línea 470** (después del Row de búsqueda):

```dart
                      // Panel de filtros expandible
                      if (_showFilters) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              // Filtro por estado
                              DropdownButtonFormField<String>(
                                value: _selectedEstado.isEmpty ? null : _selectedEstado,
                                decoration: InputDecoration(
                                  labelText: 'Estado',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: '', child: Text('Todos los estados')),
                                  DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                                  DropdownMenuItem(value: 'aprobado', child: Text('Aprobado')),
                                  DropdownMenuItem(value: 'rechazado', child: Text('Rechazado')),
                                  DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedEstado = value ?? '';
                                  });
                                  _applyFilters();
                                },
                              ),
                              const SizedBox(height: 8),
                              // Filtro por cliente
                              TextField(
                                controller: _clienteFilterController,
                                decoration: InputDecoration(
                                  labelText: 'Cliente',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Filtro por vehículo
                              TextField(
                                controller: _vehiculoFilterController,
                                decoration: InputDecoration(
                                  labelText: 'Vehículo (placa, marca, modelo)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Filtros de fecha
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: _fechaDesde ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                        );
                                        if (date != null) {
                                          setState(() {
                                            _fechaDesde = date;
                                          });
                                          _applyFilters();
                                        }
                                      },
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: 'Desde',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          suffixIcon: _fechaDesde != null
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear, size: 18),
                                                  onPressed: () {
                                                    setState(() {
                                                      _fechaDesde = null;
                                                    });
                                                    _applyFilters();
                                                  },
                                                )
                                              : null,
                                        ),
                                        child: Text(
                                          _fechaDesde != null
                                              ? '${_fechaDesde!.day}/${_fechaDesde!.month}/${_fechaDesde!.year}'
                                              : 'Seleccionar',
                                          style: TextStyle(
                                            color: _fechaDesde != null ? Colors.black : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: _fechaHasta ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                        );
                                        if (date != null) {
                                          setState(() {
                                            _fechaHasta = date;
                                          });
                                          _applyFilters();
                                        }
                                      },
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: 'Hasta',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          suffixIcon: _fechaHasta != null
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear, size: 18),
                                                  onPressed: () {
                                                    setState(() {
                                                      _fechaHasta = null;
                                                    });
                                                    _applyFilters();
                                                  },
                                                )
                                              : null,
                                        ),
                                        child: Text(
                                          _fechaHasta != null
                                              ? '${_fechaHasta!.day}/${_fechaHasta!.month}/${_fechaHasta!.year}'
                                              : 'Seleccionar',
                                          style: TextStyle(
                                            color: _fechaHasta != null ? Colors.black : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Contador de resultados
                if (!loading && filteredPresupuestos.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    color: Colors.grey.shade100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Mostrando ${filteredPresupuestos.length} de ${allPresupuestos.length} presupuestos',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Lista de presupuestos
                Expanded(
                  child: filteredPresupuestos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron presupuestos',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                allPresupuestos.isEmpty
                                    ? 'Comience creando su primer presupuesto'
                                    : 'Intente ajustar los filtros de búsqueda',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredPresupuestos.length,
                          itemBuilder: (context, i) {
                            final p = filteredPresupuestos[i] as Map<String, dynamic>;
                            return Card(
                              color: Colors.deepPurple.shade600,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/presupuesto-detalle',
                                  arguments: {'presupuesto': p, 'token': token},
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.receipt_long,
                                            color: Colors.white70,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      '#${p['id'] ?? '?'}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    _buildStatusBadge(p['estado']),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  p['diagnostico'] ?? 'Sin diagnóstico',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white70,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orangeAccent.shade700,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Bs. ${_fmtNum(p['total'])}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.person, color: Colors.white70, size: 16),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              p['cliente_nombre'] ?? 'Sin cliente',
                                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.directions_car, color: Colors.white70, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${p['vehiculo']?['placa'] ?? 'N/A'} - ${p['vehiculo']?['marca'] ?? ''} ${p['vehiculo']?['modelo'] ?? ''}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
```

## 🎯 Resumen de Funcionalidades Implementadas

### ✅ Sistema de Filtros Completo:
1. **Búsqueda general** - Por número, ID, cliente, placa, marca, modelo
2. **Filtro por estado** - Dropdown con: Todos, Pendiente, Aprobado, Rechazado, Cancelado
3. **Filtro por cliente** - Campo de texto
4. **Filtro por vehículo** - Campo de texto (placa/marca/modelo)
5. **Rango de fechas** - Selectores "Desde" y "Hasta"
6. **Botón limpiar filtros** - Aparece cuando hay filtros activos
7. **Contador de resultados** - Muestra "X de Y presupuestos"
8. **Panel expandible** - Toggle para mostrar/ocultar filtros
9. **Badges de estado** - Con colores: Verde (Aprobado), Rojo (Rechazado), Amarillo (Pendiente), Gris (Cancelado)
10. **Mensaje sin resultados** - Con sugerencias

### 📱 Características de UI:
- Diseño responsivo y moderno
- Colores consistentes con el tema de la app
- Iconos descriptivos
- Cards con elevación y bordes redondeados
- Estados visuales claros
- Animaciones suaves (setState)

## 🚀 Prueba la App
Después de completar el código:
1. Guarda el archivo
2. Ejecuta: `flutter run`
3. Prueba los filtros con los 6 presupuestos de ejemplo
