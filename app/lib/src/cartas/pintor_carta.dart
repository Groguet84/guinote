import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guinote_core/guinote_core.dart';

/// Proporción ancho / alto de una carta (la de las imágenes de la baraja).
const double proporcionCarta = 208 / 319;

/// Colores de cada palo.
Color colorPalo(Palo palo) => switch (palo) {
  Palo.oros => const Color(0xFFD9A400),
  Palo.copas => const Color(0xFFC62828),
  Palo.espadas => const Color(0xFF1E5AA8),
  Palo.bastos => const Color(0xFF2E7D32),
};

const _papel = Color(0xFFFFFBF0);
const _tinta = Color(0xFF3A2A1A);

/// Dibuja la cara de una carta de la baraja española, toda por código.
///
/// Es el respaldo de las imágenes de `assets/cartas/` si alguna no carga.
class PintorCarta extends CustomPainter {
  const PintorCarta(this.carta);

  final Carta carta;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final borde = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(borde, Paint()..color = _papel);
    canvas.drawRRect(
      borde.deflate(w * 0.035),
      Paint()
        ..color = colorPalo(carta.palo).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012,
    );

    _indice(canvas, size);
    canvas.save();
    canvas.translate(w, h);
    canvas.rotate(math.pi);
    _indice(canvas, size);
    canvas.restore();

    switch (carta.valor) {
      case Valor.sota || Valor.caballo || Valor.rey:
        // Más estrecho que las numeradas para no pisar el índice de dos cifras.
        _figura(canvas, Rect.fromLTRB(w * 0.25, h * 0.13, w * 0.75, h * 0.87));
      default:
        _simbolos(canvas, Rect.fromLTRB(w * 0.2, h * 0.12, w * 0.8, h * 0.88));
    }
  }

  void _indice(Canvas canvas, Size size) {
    final texto = TextPainter(
      text: TextSpan(
        text: '${carta.valor.numero}',
        style: TextStyle(
          color: colorPalo(carta.palo),
          fontSize: size.width * 0.17,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    texto.paint(canvas, Offset(size.width * 0.06, size.height * 0.04));
    texto.dispose();
  }

  /// Cartas numeradas: tantos símbolos del palo como indica el número.
  void _simbolos(Canvas canvas, Rect zona) {
    final n = carta.valor.numero;
    final posiciones = _posiciones[n]!;
    final tamano = zona.width * (n == 1 ? 0.95 : (n <= 3 ? 0.55 : 0.44));
    for (final p in posiciones) {
      pintarSimbolo(
        canvas,
        carta.palo,
        Offset(zona.left + p.dx * zona.width, zona.top + p.dy * zona.height),
        tamano,
      );
    }
  }

  static const Map<int, List<Offset>> _posiciones = {
    1: [Offset(0.5, 0.5)],
    2: [Offset(0.5, 0.22), Offset(0.5, 0.78)],
    3: [Offset(0.5, 0.17), Offset(0.5, 0.5), Offset(0.5, 0.83)],
    4: [
      Offset(0.25, 0.2),
      Offset(0.75, 0.2),
      Offset(0.25, 0.8),
      Offset(0.75, 0.8),
    ],
    5: [
      Offset(0.25, 0.17),
      Offset(0.75, 0.17),
      Offset(0.5, 0.5),
      Offset(0.25, 0.83),
      Offset(0.75, 0.83),
    ],
    6: [
      Offset(0.25, 0.17),
      Offset(0.75, 0.17),
      Offset(0.25, 0.5),
      Offset(0.75, 0.5),
      Offset(0.25, 0.83),
      Offset(0.75, 0.83),
    ],
    7: [
      Offset(0.25, 0.15),
      Offset(0.75, 0.15),
      Offset(0.5, 0.33),
      Offset(0.25, 0.52),
      Offset(0.75, 0.52),
      Offset(0.25, 0.85),
      Offset(0.75, 0.85),
    ],
  };

  /// Figuras: retrato estilizado con el símbolo del palo. Sin nombre: se
  /// reconocen por el número y el dibujo, como en la baraja de verdad.
  void _figura(Canvas canvas, Rect zona) {
    final color = colorPalo(carta.palo);
    final marco = RRect.fromRectAndRadius(
      zona,
      Radius.circular(zona.width * 0.08),
    );
    canvas.drawRRect(marco, Paint()..color = color.withValues(alpha: 0.12));
    canvas.drawRRect(
      marco,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = zona.width * 0.03,
    );

    final cx = zona.center.dx;
    final u = zona.width;
    final cabeza = Offset(cx, zona.top + zona.height * 0.3);
    final relleno = Paint()..color = color;
    final piel = Paint()..color = const Color(0xFFF2D3B0);
    final contorno = Paint()
      ..color = _tinta
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.025;

    // Cuerpo: túnica trapezoidal.
    final cuerpo = Path()
      ..moveTo(cx - u * 0.14, cabeza.dy + u * 0.14)
      ..lineTo(cx + u * 0.14, cabeza.dy + u * 0.14)
      ..lineTo(cx + u * 0.32, zona.top + zona.height * 0.72)
      ..lineTo(cx - u * 0.32, zona.top + zona.height * 0.72)
      ..close();
    canvas.drawPath(cuerpo, relleno);
    canvas.drawPath(cuerpo, contorno);

    canvas.drawCircle(cabeza, u * 0.13, piel);
    canvas.drawCircle(cabeza, u * 0.13, contorno);

    switch (carta.valor) {
      case Valor.rey:
        final corona = Path()
          ..moveTo(cx - u * 0.15, cabeza.dy - u * 0.1)
          ..lineTo(cx - u * 0.15, cabeza.dy - u * 0.26)
          ..lineTo(cx - u * 0.075, cabeza.dy - u * 0.17)
          ..lineTo(cx, cabeza.dy - u * 0.29)
          ..lineTo(cx + u * 0.075, cabeza.dy - u * 0.17)
          ..lineTo(cx + u * 0.15, cabeza.dy - u * 0.26)
          ..lineTo(cx + u * 0.15, cabeza.dy - u * 0.1)
          ..close();
        canvas.drawPath(corona, Paint()..color = const Color(0xFFE8B923));
        canvas.drawPath(corona, contorno);
      case Valor.caballo:
        // Herradura sobre la cabeza.
        canvas.drawArc(
          Rect.fromCircle(
            center: cabeza.translate(0, -u * 0.2),
            radius: u * 0.09,
          ),
          math.pi * 0.15,
          -math.pi * 1.3,
          false,
          contorno..strokeWidth = u * 0.045,
        );
      default:
        // Sota: gorro con pluma.
        final gorro = Rect.fromCenter(
          center: cabeza.translate(0, -u * 0.12),
          width: u * 0.3,
          height: u * 0.1,
        );
        canvas.drawOval(gorro, relleno);
        canvas.drawOval(gorro, contorno);
        canvas.drawLine(
          gorro.centerRight.translate(-u * 0.04, 0),
          gorro.centerRight.translate(u * 0.06, -u * 0.14),
          contorno..strokeWidth = u * 0.04,
        );
    }

    pintarSimbolo(
      canvas,
      carta.palo,
      Offset(cx, zona.top + zona.height * 0.72),
      u * 0.42,
    );
  }

  @override
  bool shouldRepaint(PintorCarta oldDelegate) => oldDelegate.carta != carta;
}

/// Dorso de las cartas: trama de rombos.
class PintorDorso extends CustomPainter {
  const PintorDorso();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final borde = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(borde, Paint()..color = _papel);
    final interior = borde.deflate(w * 0.06);
    canvas.drawRRect(interior, Paint()..color = const Color(0xFF8E1B1B));

    canvas.save();
    canvas.clipRRect(interior);
    final linea = Paint()
      ..color = const Color(0x55FFD580)
      ..strokeWidth = math.max(1, w * 0.015);
    final paso = w * 0.16;
    for (var x = -size.height; x < size.width + size.height; x += paso) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        linea,
      );
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        linea,
      );
    }
    canvas.restore();

    canvas.drawRRect(
      interior,
      Paint()
        ..color = const Color(0xFFE8B923)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.02,
    );
  }

  @override
  bool shouldRepaint(PintorDorso oldDelegate) => false;
}

/// Dibuja el símbolo de [palo] centrado en [centro] y de alto [tamano].
void pintarSimbolo(Canvas canvas, Palo palo, Offset centro, double tamano) {
  canvas.save();
  canvas.translate(centro.dx, centro.dy);
  canvas.scale(tamano);
  final color = colorPalo(palo);
  final relleno = Paint()..color = color;
  final contorno = Paint()
    ..color = _tinta
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.035
    ..strokeJoin = StrokeJoin.round;

  switch (palo) {
    case Palo.oros:
      canvas.drawCircle(Offset.zero, 0.42, relleno);
      canvas.drawCircle(Offset.zero, 0.42, contorno);
      canvas.drawCircle(Offset.zero, 0.3, contorno);
      canvas.drawCircle(Offset.zero, 0.09, Paint()..color = _tinta);
    case Palo.copas:
      final copa = Path()
        ..moveTo(-0.36, -0.42)
        ..lineTo(0.36, -0.42)
        ..quadraticBezierTo(0.36, 0.02, 0.07, 0.08)
        ..lineTo(0.07, 0.28)
        ..quadraticBezierTo(0.28, 0.32, 0.3, 0.44)
        ..lineTo(-0.3, 0.44)
        ..quadraticBezierTo(-0.28, 0.32, -0.07, 0.28)
        ..lineTo(-0.07, 0.08)
        ..quadraticBezierTo(-0.36, 0.02, -0.36, -0.42)
        ..close();
      canvas.drawPath(copa, relleno);
      canvas.drawPath(copa, contorno);
      canvas.drawLine(
        const Offset(-0.3, -0.3),
        const Offset(0.3, -0.3),
        contorno,
      );
    case Palo.espadas:
      canvas.rotate(-math.pi / 9);
      final hoja = Path()
        ..moveTo(0, -0.5)
        ..lineTo(0.07, -0.38)
        ..lineTo(0.07, 0.18)
        ..lineTo(-0.07, 0.18)
        ..lineTo(-0.07, -0.38)
        ..close();
      canvas.drawPath(hoja, Paint()..color = const Color(0xFFD9DEE5));
      canvas.drawPath(hoja, contorno);
      final guarda = RRect.fromLTRBR(
        -0.27,
        0.17,
        0.27,
        0.25,
        const Radius.circular(0.04),
      );
      canvas.drawRRect(guarda, relleno);
      canvas.drawRRect(guarda, contorno);
      final empunadura = Rect.fromLTRB(-0.045, 0.25, 0.045, 0.41);
      canvas.drawRect(empunadura, relleno);
      canvas.drawRect(empunadura, contorno);
      canvas.drawCircle(const Offset(0, 0.45), 0.055, relleno);
      canvas.drawCircle(const Offset(0, 0.45), 0.055, contorno);
    case Palo.bastos:
      canvas.rotate(math.pi / 9);
      final palo = Path()
        ..moveTo(-0.13, -0.42)
        ..quadraticBezierTo(0, -0.52, 0.13, -0.42)
        ..lineTo(0.07, 0.44)
        ..quadraticBezierTo(0, 0.5, -0.07, 0.44)
        ..close();
      canvas.drawPath(palo, relleno);
      canvas.drawPath(palo, contorno);
      // Nudos de la madera.
      for (final (y, lado) in [(-0.22, 1.0), (0.02, -1.0), (0.24, 1.0)]) {
        final x = lado * (0.11 - (y + 0.42) * 0.06);
        canvas.drawCircle(Offset(x, y), 0.045, relleno);
        canvas.drawCircle(Offset(x, y), 0.045, contorno);
      }
  }
  canvas.restore();
}
