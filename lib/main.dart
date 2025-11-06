import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/login_page.dart';
import 'pages/perfil_page.dart';
import 'pages/registro_page.dart';
import 'pages/editar_perfil_page.dart';
import 'pages/cambiar_password_page.dart';
import 'pages/presupuestos_page.dart';
import 'pages/presupuesto_detalle_page.dart';
import 'pages/presupuesto_form_page.dart';
import 'pages/generar_ordenes.dart';
import 'pages/vehiculos_page.dart';
import 'pages/vehiculo_form_page.dart';
import 'pages/vehiculo_detail_page.dart';
import 'pages/mis_citas_page.dart';
import 'pages/nueva_cita_page.dart';
import 'pages/reconocimiento_page.dart';
import 'pages/ordenes_page.dart';
import 'pages/crear_orden_page.dart';
import 'pages/mis_ordenes_page.dart';
import 'pages/citas_page.dart';
import 'pages/pagos_page.dart';
import 'pages/pagos_orden_page.dart';
import 'pages/items_page.dart';
import 'pages/facturas_page.dart';
import 'pages/bitacora_page.dart';
import 'pages/roles_page.dart';
import 'pages/usuarios_page.dart';
import 'pages/empleados_page.dart';
import 'pages/cargos_page.dart';
import 'pages/asistencias_page.dart';
import 'pages/nominas_page.dart';
import 'pages/asistente_virtual_page.dart';
import 'pages/historial_page.dart';
import 'pages/inventario_page.dart';
import 'pages/servicios_page.dart';
import 'pages/areas_page.dart';
import 'pages/proveedores_page.dart';
import 'pages/reportes_page.dart';
import 'pages/facturas_proveedor_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Carga las variables del archivo .env con manejo de errores
  try {
    await dotenv.load(fileName: ".env");
    
    // 🔹 NO inicializamos Stripe SDK ya que usamos la API REST del backend
    // Esto evita los overlays de debug de Stripe en la UI
    debugPrint('✅ Variables de entorno cargadas');
  } catch (e) {
    debugPrint("❌ Error cargando .env: $e");
    // Continuar sin .env, usar valores por defecto
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDark = false;

  // 🔹 Cambia entre tema claro y oscuro
  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      debugShowCheckedModeBanner: false,

      // 🔹 Tema claro
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        brightness: Brightness.light,
        useMaterial3: true,
      ),

      // 🔹 Tema oscuro
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,

      // 🔹 Rutas de la aplicación
      initialRoute: "/",
      routes: {
        "/": (context) =>
            LoginPage(onToggleTheme: _toggleTheme, isDark: _isDark),
        "/perfil": (context) =>
            PerfilPage(onToggleTheme: _toggleTheme, isDark: _isDark),
        "/registro": (context) => const RegistroPage(),
        "/editar-perfil": (context) => const EditarPerfilPage(),
        "/cambiar-password": (context) => const CambiarPasswordPage(),
        "/presupuestos": (context) => const PresupuestosPage(),
        "/presupuesto-form": (context) => const PresupuestoFormPage(),
        "/presupuesto-detalle": (context) => const PresupuestoDetallePage(),
        "/generar-orden": (context) => const GenerarOrdenPage(),
        "/vehiculos": (context) => const VehiculosPage(),
        "/vehiculo-form": (context) => const VehiculoFormPage(),
        "/vehiculo-detalle": (context) => const VehiculoDetailPage(),
<<<<<<< HEAD
        "/mis-citas": (context) => const MisCitasPage(),
=======
        "/reconocimiento": (context) => const ReconocimientoPage(),
        "/ordenes": (context) => const OrdenesPage(),
        "/crear-orden": (context) => const CrearOrdenPage(),
        "/mis-ordenes": (context) => const MisOrdenesPage(),
        "/citas": (context) => const CitasPage(),
        "/pagos": (context) => const PagosPage(),
        "/pagos-orden": (context) => const PagosOrdenPage(),
        "/items": (context) => const ItemsPage(),
        "/facturas": (context) => const FacturasPage(),
        "/bitacora": (context) => const BitacoraPage(),
        "/roles": (context) => const RolesPage(),
        "/usuarios": (context) => const UsuariosPage(),
        "/empleados": (context) => const EmpleadosPage(),
        "/cargos": (context) => const CargosPage(),
        "/asistencias": (context) => const AsistenciasPage(),
        "/nominas": (context) => const NominasPage(),
        "/clientes": (context) => const CitasPage(), // Reutilizamos por ahora
        "/asistente-virtual": (context) => const AsistenteVirtualPage(),
        "/historial": (context) => const HistorialPage(),
        "/inventario": (context) => const InventarioPage(),
        "/servicios": (context) => const ServiciosPage(),
        "/areas": (context) => const AreasPage(),
        "/proveedores": (context) => const ProveedoresPage(),
        "/reportes": (context) => const ReportesPage(),
        "/facturas-proveedor": (context) => const FacturasProveedorPage(),
>>>>>>> 30306e978f6867493307b0a96d480d93af18fc58
      },
    );
  }
}
