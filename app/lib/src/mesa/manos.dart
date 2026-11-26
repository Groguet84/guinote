import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guinote_core/guinote_core.dart';

import '../cartas/carta_widget.dart';
import '../cartas/pintor_carta.dart';

/// Clave de una carta de la mano del humano, para encontrarla en los tests.
Key claveCartaMano(Carta carta) => ValueKey('mano-$carta');

/// Ordena una mano por palo y, dentro del palo, de mayor a menor.
List<Carta> ordenarMano(List<Carta> mano) => [...mano]
  ..sort(
    (a, b) => a.palo != b.palo
        ? a.palo.index.compareTo(b.palo.index)
        : b.valor.fuerza.compareTo(a.valor.fuerza),
  );

/// La mano del humano, boca arriba. En su turno, las cartas que se pueden
/// echar suben un poco y las demás se atenúan.
class ManoHumano extends StatelessWidget {
  const ManoHumano({
    super.key,
    required this.cartas,
    required this.jugables,
    required this.ancho,
    required this.anchoMaximo,
    required this.onJugar,
  });

  final List<Carta> cartas;

  /// Cartas que se pueden echar ahora; vacío si no es su turno.
  final List<Carta> jugables;
  final double ancho;
  final double anchoMaximo;
  final ValueChanged<Carta> onJugar;

  @override
  Widget build(BuildContext context) {
    final ordenadas = ordenarMano(cartas);
    final n = ordenadas.length;
    final alto = ancho / proporcionCarta;
    final subida = ancho * 0.22;
    final paso = n <= 1
        ? 0.0
        : math.min(ancho * 1.08, (anchoMaximo - ancho) / (n - 1));
    final enTurno = jugables.isNotEmpty;

    return SizedBox(
      width: n == 0 ? ancho : ancho + paso * (n - 1),
      height: alto + subida,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < n; i++)
            AnimatedPositioned(
              key: ValueKey(ordenadas[i]),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              left: i * paso,
              top: enTurno && jugables.contains(ordenadas[i]) ? 0 : subida,
              child: CartaWidget(
                key: claveCartaMano(ordenadas[i]),
                carta: ordenadas[i],
                ancho: ancho,
                atenuada: enTurno && !jugables.contains(ordenadas[i]),
                onTap: jugables.contains(ordenadas[i])
                    ? () => onJugar(ordenadas[i])
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

/// Las cartas de un jugador del ordenador, boca abajo y solapadas.
class ManoOculta extends StatelessWidget {
  const ManoOculta({
    super.key,
    required this.numero,
    required this.ancho,
    this.vertical = false,
  });

  final int numero;
  final double ancho;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final paso = ancho * 0.38;
    final fila = SizedBox(
      width: numero == 0 ? 0 : ancho + paso * (numero - 1),
      height: ancho / proporcionCarta,
      child: Stack(
        children: [
          for (var i = 0; i < numero; i++)
            Positioned(
              left: i * paso,
              child: CartaWidget.dorso(ancho: ancho),
            ),
        ],
      ),
    );
    return vertical ? RotatedBox(quarterTurns: 1, child: fila) : fila;
  }
}
