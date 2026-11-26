import 'package:flutter/material.dart';

import 'src/mesa/pantalla_mesa.dart';

void main() => runApp(const GuinoteApp());

class GuinoteApp extends StatelessWidget {
  const GuinoteApp({super.key, this.mesa = const PantallaMesa()});

  /// La mesa a mostrar; los tests pasan una con un controlador propio.
  final Widget mesa;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guiñote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1B5E20)),
      home: mesa,
    );
  }
}
