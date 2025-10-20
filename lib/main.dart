import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/login_page.dart';
import 'pages/perfil_page.dart';
import 'pages/registro_page.dart';
import 'pages/editar_perfil_page.dart';
import 'pages/cambiar_password_page.dart';
import 'pages/presupuestos_page.dart';
import 'pages/presupuesto_detail_page.dart';
import 'pages/generar_ordenes.dart';
import 'pages/vehiculos_page.dart';
import 'pages/vehiculo_form_page.dart';
import 'pages/vehiculo_detail_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Carga las variables del archivo .env con manejo de errores
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Error cargando .env: $e");
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
        "/presupuestos": (context) => PresupuestosPage(),
        "/presupuesto-detalle": (context) => const PresupuestoDetailPage(),
        "/generar-orden": (context) => const GenerarOrdenPage(),
        "/vehiculos": (context) => const VehiculosPage(),
        "/vehiculo-form": (context) => const VehiculoFormPage(),
        "/vehiculo-detalle": (context) => const VehiculoDetailPage(),
      },
    );
  }
}
