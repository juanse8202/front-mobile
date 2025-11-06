# Implementación de Reportes en Flutter - Parte 1: Reportes Estáticos

## 📋 Descripción General

Se ha implementado el sistema de reportes en la aplicación móvil Flutter, comenzando con los **reportes estáticos** (Parte 1 de 3). Este sistema replica la funcionalidad existente en la versión web.

## 🎯 Tipos de Reportes (Planificación Completa)

1. ✅ **Reportes Estáticos** - IMPLEMENTADO (Parte 1)
2. ⏳ **Reportes Personalizados** - Pendiente (Parte 2)
3. ⏳ **Reportes con IA (Lenguaje Natural)** - Pendiente (Parte 3)

---

## 📁 Archivos Creados/Modificados

### Archivos Nuevos

1. **`lib/services/reporte_service.dart`**
   - Servicio de API para comunicación con el backend
   - Funciones implementadas:
     - `obtenerReportesDisponibles()`: Obtiene lista de reportes estáticos disponibles
     - `generarReporteEstatico()`: Genera un reporte estático con parámetros
     - `obtenerHistorialReportes()`: Obtiene historial de reportes del usuario
     - `descargarReporte()`: Descarga un reporte generado
     - `obtenerUrlDescarga()`: Genera URL de descarga
     - `obtenerReportes()`: Lista todos los reportes del usuario

2. **`lib/pages/reportes_estaticos_page.dart`**
   - Interfaz completa para generación de reportes estáticos
   - Características:
     - Selector de tipo de reporte (dropdown con descripción)
     - Selector de formato (PDF/XLSX)
     - Filtros de fecha opcionales (inicio/fin)
     - Historial de reportes generados
     - Función de descarga directa
     - Indicadores de carga y mensajes de error/éxito

### Archivos Modificados

3. **`lib/pages/reportes_page.dart`**
   - Página principal de reportes con 3 opciones
   - Muestra tarjetas para cada tipo de reporte
   - Indica cuáles están disponibles y cuáles "próximamente"
   - Navegación funcional a Reportes Estáticos

4. **`pubspec.yaml`**
   - Agregada dependencia: `url_launcher: ^6.3.1`
   - Necesaria para abrir URLs de descarga

---

## 🔧 Endpoints del Backend Utilizados

Base URL: `http://192.168.0.3:8000/api/ia/reportes/`

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/disponibles/` | GET | Lista reportes estáticos disponibles |
| `/generar_estatico/` | POST | Genera un reporte estático |
| `/historial/` | GET | Historial de reportes del usuario |
| `/{id}/descargar/` | GET | Descarga un reporte específico |
| `/` | GET | Lista todos los reportes |

---

## 📊 Tipos de Reportes Estáticos Disponibles

Según el backend (`backend-git/servicios_IA/viewsReportes.py`):

1. **ordenes_estado** - Distribución de órdenes por estado
2. **ordenes_pendientes** - Órdenes pendientes actuales
3. **ordenes_completadas_mes** - Órdenes completadas del mes
4. **ingresos_mensual** - Análisis de ingresos mensuales
5. **items_criticos** - Items de inventario crítico

---

## 🎨 Interfaz de Usuario

### Página Principal (`reportes_page.dart`)

```
┌─────────────────────────────────────┐
│    Reportes y Análisis              │
├─────────────────────────────────────┤
│                                     │
│  📊 Reportes Estáticos              │
│  └─ Reportes predefinidos           │
│     [FUNCIONAL]                     │
│                                     │
│  🎛️ Reportes Personalizados         │
│  └─ Campos y filtros custom         │
│     [Próximamente]                  │
│                                     │
│  💬 Reportes con IA                 │
│  └─ Lenguaje natural                │
│     [Próximamente]                  │
│                                     │
└─────────────────────────────────────┘
```

### Página de Reportes Estáticos (`reportes_estaticos_page.dart`)

```
┌─────────────────────────────────────┐
│    Reportes Estáticos               │
├─────────────────────────────────────┤
│                                     │
│  📝 Generar Nuevo Reporte           │
│  ┌─────────────────────────────┐   │
│  │ Tipo de Reporte ▼           │   │
│  │ • Órdenes por Estado        │   │
│  │ • Órdenes Pendientes        │   │
│  │ • Órdenes Completadas Mes   │   │
│  │ • Ingresos Mensual          │   │
│  │ • Items Críticos            │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Formato ▼                   │   │
│  │ • PDF                       │   │
│  │ • Excel (XLSX)              │   │
│  └─────────────────────────────┘   │
│                                     │
│  Filtros de Fecha (Opcional)       │
│  [📅 Fecha Inicio] [📅 Fecha Fin]  │
│                                     │
│  [▶️ Generar Reporte]               │
│                                     │
├─────────────────────────────────────┤
│  📋 Historial de Reportes           │
│  ┌─────────────────────────────┐   │
│  │ 📄 Órdenes por Estado       │   │
│  │    Generado: 15/01/24 10:30 │ ⬇️ │
│  │    Registros: 45            │   │
│  ├─────────────────────────────┤   │
│  │ 📊 Ingresos Mensual         │   │
│  │    Generado: 14/01/24 15:20 │ ⬇️ │
│  │    Registros: 120           │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

---

## 🔐 Autenticación

El servicio utiliza JWT tokens almacenados en `flutter_secure_storage`:
- Token obtenido de: `access_token` (storage key)
- Enviado en headers: `Authorization: Bearer {token}`

---

## 📱 Flujo de Usuario

1. **Acceso**
   - Usuario va a Perfil > Finanzas > Reportes
   - Se muestra página con 3 tipos (solo Estáticos funcional)

2. **Selección**
   - Usuario toca "Reportes Estáticos"
   - Se carga lista de reportes disponibles desde backend

3. **Configuración**
   - Selecciona tipo de reporte del dropdown
   - Elige formato (PDF o XLSX)
   - Opcionalmente agrega filtros de fecha

4. **Generación**
   - Presiona "Generar Reporte"
   - Backend procesa la solicitud
   - Se muestra mensaje de éxito/error

5. **Descarga**
   - Aparece diálogo con detalles del reporte
   - Usuario puede descargar inmediatamente
   - También aparece en historial para descargas futuras

6. **Historial**
   - Lista de reportes generados anteriormente
   - Cada uno con botón de descarga
   - Muestra fecha, registros procesados y formato

---

## 🛠️ Instalación de Dependencias

```bash
cd front-mobile
flutter pub get
```

Las dependencias necesarias ya están agregadas en `pubspec.yaml`:
- `http: ^1.2.2` (ya existía)
- `flutter_dotenv: ^6.0.0` (ya existía)
- `flutter_secure_storage: ^9.0.0` (ya existía)
- `intl: ^0.19.0` (ya existía)
- `url_launcher: ^6.3.1` (NUEVO)

---

## 🚀 Próximos Pasos (Parte 2 y 3)

### Parte 2: Reportes Personalizados
- [ ] Crear `reportes_personalizados_page.dart`
- [ ] Implementar selector dinámico de campos
- [ ] Implementar filtros personalizados
- [ ] Agregar función `generarReportePersonalizado()` al servicio

### Parte 3: Reportes con IA (Lenguaje Natural)
- [ ] Crear `reportes_natural_page.dart`
- [ ] Implementar input de texto para consulta
- [ ] Integrar procesamiento de lenguaje natural del backend
- [ ] Agregar función `generarReporteNatural()` al servicio
- [ ] Mostrar preview de consulta interpretada

---

## 🐛 Manejo de Errores

El sistema incluye manejo robusto de errores:

1. **Errores de Red**
   - Catch en try/catch con mensajes descriptivos
   - SnackBar para feedback al usuario

2. **Errores de Backend**
   - Parseo de respuestas de error
   - Mostrar mensajes específicos del servidor

3. **Validaciones**
   - Verificar selección de tipo de reporte antes de generar
   - Validar formato de fechas
   - Comprobar disponibilidad de token

---

## 📝 Notas Técnicas

### Formato de Fechas
- Entrada: `DateTime` de Flutter
- Envío al backend: ISO 8601 (`YYYY-MM-DD`)
- Mostrar al usuario: `dd/MM/yyyy` o `dd/MM/yyyy HH:mm`

### Descarga de Archivos
- Usa `url_launcher` para abrir URL en navegador/app externa
- El backend genera URL con token en query params
- Formato: `/api/ia/reportes/{id}/descargar/?token={token}`

### Estado de Carga
- `_isLoading`: Para el botón de generar
- `_isLoadingReportes`: Para carga inicial de datos
- Muestra `CircularProgressIndicator` durante operaciones

---

## ✅ Testing

### Tests Manuales Recomendados

1. **Generación Básica**
   - [ ] Seleccionar cada tipo de reporte
   - [ ] Generar en formato PDF
   - [ ] Generar en formato XLSX
   - [ ] Verificar que aparece en historial

2. **Filtros de Fecha**
   - [ ] Generar sin fechas (todos los datos)
   - [ ] Generar con fecha inicio solamente
   - [ ] Generar con fecha fin solamente
   - [ ] Generar con ambas fechas
   - [ ] Limpiar fechas seleccionadas

3. **Descarga**
   - [ ] Descargar desde diálogo de confirmación
   - [ ] Descargar desde historial
   - [ ] Verificar que archivo se abre/descarga correctamente

4. **Errores**
   - [ ] Intentar generar sin seleccionar tipo
   - [ ] Simular error de red (modo avión)
   - [ ] Verificar mensajes de error apropiados

---

## 📚 Referencias

- **Backend**: `backend-git/servicios_IA/viewsReportes.py`
- **Modelo**: `backend-git/servicios_IA/models.py` (Reporte)
- **Serializers**: `backend-git/servicios_IA/serializersReporte.py`
- **Web API**: `frontend-git/src/api/reportesApi.jsx`

---

## 🎉 Estado Actual

✅ **Parte 1 COMPLETADA**: Reportes Estáticos totalmente funcionales
- Servicio de API creado
- Interfaz de usuario implementada
- Integración con backend validada
- Descarga de reportes funcionando
- Historial implementado

⏳ **Pendiente**: Partes 2 y 3 (Personalizados y Lenguaje Natural)

---

## 👤 Autor

Implementado como parte del sistema de gestión de taller mecánico.
Fecha: Enero 2024
