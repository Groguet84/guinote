import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guinote_core/guinote_core.dart';

import '../cartas/carta_widget.dart';
import '../cartas/pintor_carta.dart';

/// Clave de una carta de la mano del humano, para encontrarla en los tests.
Key claveCartaMano(Carta carta) => ValueKey('mano-$carta');

/// La mano del humano, boca arriba y en el orden que él elija.
///
/// - Un toque echa la carta (si se puede).
/// - Arrastrar una carta a izquierda o derecha la cambia de sitio.
/// - En su turno, las cartas que se pueden echar suben y las demás se atenúan.
class ManoHumano extends StatefulWidget {
  const ManoHumano({
    super.key,
    required this.cartas,
    required this.jugables,
    required this.ancho,
    required this.anchoMaximo,
    required this.onJugar,
    required this.onReordenar,
  });

  /// Cartas en el orden en que se muestran.
  final List<Carta> cartas;

  /// Cartas que se pueden echar ahora; vacío si no es su turno.
  final List<Carta> jugables;
  final double ancho;
  final double anchoMaximo;
  final ValueChanged<Carta> onJugar;

  /// Mueve la carta de la posición `desde` a la posición `hasta`.
  final void Function(int desde, int hasta) onReordenar;

  @override
  State<ManoHumano> createState() => _ManoHumanoState();
}

class _ManoHumanoState extends State<ManoHumano> {
  /// Posición de la carta que se está arrastrando, si hay alguna.
  int? _arrastrada;

  /// Desplazamiento horizontal acumulado del arrastre.
  double _dx = 0;

  @override
  void didUpdateWidget(ManoHumano anterior) {
    super.didUpdateWidget(anterior);
    // Si cambian las cartas a mitad de un arrastre (se roba o se echa una),
    // el arrastre ya no tiene sentido.
    if (anterior.cartas.length != widget.cartas.length) {
      _arrastrada = null;
      _dx = 0;
    }
  }

  double get _paso {
    final n = widget.cartas.length;
    if (n <= 1) return widget.ancho;
    return math.min(
      widget.ancho * 1.08,
      (widget.anchoMaximo - widget.ancho) / (n - 1),
    );
  }

  /// Posición en la que caería la carta arrastrada si se soltara ahora.
  int get _destino =>
      (_arrastrada! + (_dx / _paso).round()).clamp(0, widget.cartas.length - 1);

  void _soltar() {
    final desde = _arrastrada;
    if (desde == null) return;
    final hasta = _destino;
    setState(() {
      _arrastrada = null;
      _dx = 0;
    });
    if (desde != hasta) widget.onReordenar(desde, hasta);
  }

  @override
  Widget build(BuildContext context) {
    final cartas = widget.cartas;
    final n = cartas.length;
    final ancho = widget.ancho;
    final paso = _paso;
    final alto = ancho / proporcionCarta;
    final subida = ancho * 0.22;
    final enTurno = widget.jugables.isNotEmpty;
    final arrastrada = _arrastrada;

    // Orden visual: la carta arrastrada ocupa el hueco de destino y las
    // demás se apartan.
    final visual = List.generate(n, (i) => i);
    if (arrastrada != null) {
      visual
        ..remove(arrastrada)
        ..insert(_destino, arrastrada);
    }

    Widget carta(int i) {
      final c = cartas[i];
      final jugable = widget.jugables.contains(c);
      final moviendo = i == arrastrada;
      final izquierda = moviendo
          ? (i * paso + _dx).clamp(-paso / 2, (n - 1) * paso + paso / 2)
          : visual.indexOf(i) * paso;
      return AnimatedPositioned(
        key: ValueKey(c),
        duration: moviendo ? Duration.zero : const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        left: izquierda,
        top: moviendo || (enTurno && jugable) ? 0 : subida,
        child: GestureDetector(
          onHorizontalDragStart: (_) => setState(() {
            _arrastrada = i;
            _dx = 0;
          }),
          onHorizontalDragUpdate: (d) => setState(() => _dx += d.delta.dx),
          onHorizontalDragEnd: (_) => _soltar(),
          onHorizontalDragCancel: _soltar,
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: CartaWidget(
              key: claveCartaMano(c),
              carta: c,
              ancho: ancho,
              atenuada: enTurno && !jugable && !moviendo,
              resaltada: moviendo,
              onTap: jugable ? () => widget.onJugar(c) : null,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: n == 0 ? ancho : ancho + paso * (n - 1),
      height: alto + subida,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // La carta arrastrada se pinta la última, por encima de las demás.
          for (var i = 0; i < n; i++)
            if (i != arrastrada) carta(i),
          if (arrastrada != null) carta(arrastrada),
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
