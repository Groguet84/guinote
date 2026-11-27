import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guinote_core/guinote_core.dart';

import '../cartas/carta_widget.dart';
import '../cartas/pintor_carta.dart';

/// Clave del montón de bazas de una pareja, para los tests.
Key claveMonton(int pareja) => ValueKey('monton-$pareja');

/// El montón de bazas ganadas por una pareja: cartas boca abajo, apiladas
/// un poco desordenadas, que crece con cada baza. Encima, boca arriba y
/// cruzadas, las cartas que marcan cada cante de 20.
class MontonBazas extends StatelessWidget {
  const MontonBazas({
    super.key,
    required this.nombre,
    required this.bazas,
    required this.marcas,
    required this.ancho,
  });

  /// Nombre de la pareja, para la accesibilidad.
  final String nombre;

  /// Bazas recogidas.
  final int bazas;

  /// Cartas boca arriba que marcan los cantes de 20.
  final List<Carta> marcas;
  final double ancho;

  /// Giros de cada carta del montón: fijos, para que no cambie al redibujar.
  static const List<double> _giros = [
    -0.35,
    0.2,
    -0.1,
    0.4,
    -0.25,
    0.1,
    0.3,
    -0.4,
    0.05,
    -0.15,
  ];

  @override
  Widget build(BuildContext context) {
    final alto = ancho / proporcionCarta;
    // Cuadrado: cabe la carta girada en cualquier ángulo.
    final lado = math.sqrt(ancho * ancho + alto * alto);
    return Semantics(
      label:
          '$nombre: $bazas ${bazas == 1 ? 'baza' : 'bazas'}'
          '${marcas.isEmpty ? '' : ', ${marcas.length} de 20 cantadas'}',
      child: SizedBox.square(
        dimension: lado,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < bazas; i++)
              Transform.translate(
                offset: Offset(0, -i * 1.5),
                child: Transform.rotate(
                  angle: _giros[i % _giros.length],
                  child: CartaWidget.dorso(ancho: ancho),
                ),
              ),
            for (var i = 0; i < marcas.length; i++)
              Transform.translate(
                offset: Offset(i * ancho * 0.18, -bazas * 1.5 - i * 4),
                child: Transform.rotate(
                  angle: math.pi / 2 - 0.15 + i * 0.12,
                  child: CartaWidget(carta: marcas[i], ancho: ancho),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
