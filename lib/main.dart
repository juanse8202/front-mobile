import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/perfil_page.dart';
import 'pages/registro_page.dart';
import 'pages/editar_perfil_page.dart';
import 'pages/cambiar_password_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDark = false;

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: "/",
      routes: {
        "/": (context) =>
            LoginPage(onToggleTheme: _toggleTheme, isDark: _isDark),
        "/perfil": (context) =>
            PerfilPage(onToggleTheme: _toggleTheme, isDark: _isDark),
        "/registro": (context) => const RegistroPage(),
        "/editar-perfil": (context) => const EditarPerfilPage(),
       "/cambiar-password": (context) => const CambiarPasswordPage(),
      },
    );
  }
}
