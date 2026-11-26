import 'package:flutter/material.dart';

void main() => runApp(const GuinoteApp());

class GuinoteApp extends StatelessWidget {
  const GuinoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guiñote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1B5E20)),
      home: const Scaffold(body: Center(child: Text('Guiñote'))),
    );
  }
}
