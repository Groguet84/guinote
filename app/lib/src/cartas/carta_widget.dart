import 'package:flutter/material.dart';
import 'package:guinote_core/guinote_core.dart';

import 'pintor_carta.dart';

/// Ruta de la imagen de [carta], o del dorso si es `null`.
String rutaCarta(Carta? carta) => carta == null
    ? 'assets/cartas/dorso.png'
    : 'assets/cartas/${carta.valor.numero}_${carta.palo.nombre}.png';

/// Carga de antemano las imágenes de la baraja para que no parpadeen la
/// primera vez que aparecen.
Future<void> precargarCartas(BuildContext context) => Future.wait([
  for (final ruta in [rutaCarta(null), ...Carta.baraja.map(rutaCarta)])
    precacheImage(AssetImage(ruta), context),
]);

/// Una carta de [ancho] dado, boca arriba (si hay [carta]) o boca abajo.
///
/// Usa las imágenes de la baraja «Naipes libres» (`assets/cartas/`); si una
/// no se puede cargar, dibuja la carta por código.
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
    Widget dibujo = Image.asset(
      rutaCarta(carta),
      width: ancho,
      height: alto,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => CustomPaint(
        size: Size(ancho, alto),
        painter: carta == null ? const PintorDorso() : PintorCarta(carta),
      ),
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
