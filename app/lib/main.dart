import 'package:flutter/material.dart';

import 'src/inicio/pantalla_inicio.dart';

void main() => runApp(const GuinoteApp());

class GuinoteApp extends StatelessWidget {
  const GuinoteApp({super.key, this.inicio = const PantallaInicio()});

  /// La primera pantalla; los tests pasan una mesa con su controlador.
  final Widget inicio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guiñote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1B5E20)),
      home: inicio,
    );
  }
}
