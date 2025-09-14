import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/perfil_page.dart';
import 'pages/registro_page.dart';
import 'pages/editar_perfil_page.dart';
import 'pages/cambiar_password_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 👉 Siempre inicia en LoginPage
      initialRoute: "/",
      routes: {
        "/": (context) => const LoginPage(),
        "/perfil": (context) => const PerfilPage(),
        "/registro": (context) => const RegistroPage(),
        "/editar-perfil": (context) => const EditarPerfilPage(),
        "/cambiar-password": (context) => const CambiarPasswordPage(),
      },
    );
  }
}
