import 'package:flutter/material.dart';
import 'package:guinote_core/guinote_core.dart';

import 'pintor_carta.dart';

/// Una carta de [ancho] dado, boca arriba (si hay [carta]) o boca abajo.
class CartaWidget extends StatelessWidget {
  const CartaWidget({
    super.key,
    required this.ancho,
    this.carta,
    this.atenuada = false,
    this.resaltada = false,
    this.onTap,
  });

  /// Carta boca abajo.
  const CartaWidget.dorso({super.key, required this.ancho})
    : carta = null,
      atenuada = false,
      resaltada = false,
      onTap = null;

  final double ancho;
  final Carta? carta;

  /// Se dibuja más apagada (por ejemplo, porque no se puede echar).
  final bool atenuada;

  /// Se dibuja con un halo (por ejemplo, la carta que gana la baza).
  final bool resaltada;
  final VoidCallback? onTap;

  double get alto => ancho / proporcionCarta;

  @override
  Widget build(BuildContext context) {
    final carta = this.carta;
    Widget dibujo = CustomPaint(
      size: Size(ancho, alto),
      painter: carta == null ? const PintorDorso() : PintorCarta(carta),
    );
    if (atenuada) {
      dibujo = ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Color(0x66000000),
          BlendMode.srcATop,
        ),
        child: dibujo,
      );
    }

    final contenido = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ancho * 0.08),
        boxShadow: [
          BoxShadow(
            color: resaltada
                ? const Color(0xCCFFD54F)
                : const Color(0x66000000),
            blurRadius: resaltada ? ancho * 0.2 : ancho * 0.06,
            spreadRadius: resaltada ? ancho * 0.03 : 0,
            offset: resaltada ? Offset.zero : Offset(0, ancho * 0.03),
          ),
        ],
      ),
      child: RepaintBoundary(child: dibujo),
    );

    return Semantics(
      label: carta?.toString() ?? 'carta boca abajo',
      button: onTap != null,
      child: onTap == null
          ? contenido
          : MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(onTap: onTap, child: contenido),
            ),
    );
  }
}
