import 'package:flutter/material.dart';
import 'package:guinote_core/guinote_core.dart';

import '../cartas/carta_widget.dart';
import '../cartas/pintor_carta.dart';

/// Las cartas de la baza en curso, cada una delante de quien la ha echado.
/// Al aparecer, cada carta llega desde el lado de su jugador.
class CentroMesa extends StatelessWidget {
  const CentroMesa({
    super.key,
    required this.baza,
    required this.ancho,
    this.ganador,
  });

  final List<Jugada> baza;
  final double ancho;

  /// Jugador cuya carta se resalta (la baza ya está completa).
  final int? ganador;

  /// Tamaño que ocupa la baza, en anchos y altos de carta.
  static const double anchosOcupados = 3.3;
  static const double altosOcupados = 1.9;

  double get _alto => ancho / proporcionCarta;

  /// Desplazamiento desde el centro según el asiento: 0 abajo, 1 derecha,
  /// 2 arriba, 3 izquierda.
  Offset _posicion(int jugador) => switch (jugador) {
    0 => Offset(0, _alto * 0.45),
    1 => Offset(ancho * 1.15, 0),
    2 => Offset(0, -_alto * 0.45),
    _ => Offset(-ancho * 1.15, 0),
  };

  @override
  Widget build(BuildContext context) {
    final tamano = Size(ancho * anchosOcupados, _alto * altosOcupados);
    final centro = tamano.center(Offset.zero) - Offset(ancho / 2, _alto / 2);
    return SizedBox.fromSize(
      size: tamano,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final jugada in baza)
            TweenAnimationBuilder<double>(
              key: ValueKey(jugada.carta),
              tween: Tween(begin: 3, end: 1),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              builder: (context, t, hijo) {
                final p = centro + _posicion(jugada.jugador) * t;
                return Positioned(left: p.dx, top: p.dy, child: hijo!);
              },
              child: CartaWidget(
                carta: jugada.carta,
                ancho: ancho,
                resaltada: jugada.jugador == ganador,
              ),
            ),
        ],
      ),
    );
  }
}

/// El mazo boca abajo con el triunfo destapado debajo, cruzado.
class MazoYTriunfo extends StatelessWidget {
  const MazoYTriunfo({
    super.key,
    required this.cartaTriunfo,
    required this.cartasMazo,
    required this.ancho,
  });

  final Carta? cartaTriunfo;
  final int cartasMazo;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    final alto = ancho / proporcionCarta;
    final triunfo = cartaTriunfo;
    if (triunfo == null && cartasMazo == 0) return const SizedBox.shrink();
    return SizedBox(
      width: alto + ancho * 0.65,
      height: alto + ancho * 0.1,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (triunfo != null)
            Positioned(
              left: ancho * 0.6,
              child: RotatedBox(
                quarterTurns: 1,
                child: CartaWidget(
                  key: const ValueKey('carta-triunfo'),
                  carta: triunfo,
                  ancho: ancho,
                ),
              ),
            ),
          for (var i = 0; i < (cartasMazo / 4).ceil().clamp(0, 3); i++)
            Positioned(
              left: i * 2.0,
              top: ancho * 0.05 - i * 2.0,
              child: CartaWidget.dorso(ancho: ancho),
            ),
          if (cartasMazo > 0)
            Positioned(
              left: ancho * 0.12,
              bottom: ancho * 0.12,
              child: _Contador(cartasMazo),
            ),
        ],
      ),
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador(this.numero);

  final int numero;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      '$numero',
      key: const ValueKey('cartas-mazo'),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    ),
  );
}
