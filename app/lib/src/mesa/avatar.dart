import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../juego/jugadores.dart';

/// Avatar redondo de un jugador, dibujado por código. Si es su turno, el
/// borde se ilumina.
class AvatarJugador extends StatelessWidget {
  const AvatarJugador({
    super.key,
    required this.avatar,
    required this.tamano,
    this.activo = false,
  });

  final Avatar avatar;
  final double tamano;
  final bool activo;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: tamano,
    height: tamano,
    padding: EdgeInsets.all(tamano * 0.05),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: activo ? const Color(0xFFFFD54F) : const Color(0x88000000),
    ),
    child: ClipOval(child: CustomPaint(painter: PintorAvatar(avatar))),
  );
}

/// Dibuja una cara sencilla con los rasgos de [avatar] sobre un círculo.
class PintorAvatar extends CustomPainter {
  const PintorAvatar(this.avatar);

  final Avatar avatar;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.scale(s);
    final a = avatar;
    final piel = Paint()..color = a.piel;
    final pelo = Paint()..color = a.pelo;
    final trazo = Paint()
      ..color = const Color(0xFF2B2B2B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.025
      ..strokeCap = StrokeCap.round;

    canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint()..color = a.fondo);

    // Pelo por detrás de la cabeza.
    switch (a.peinado) {
      case Peinado.largo:
        canvas.drawRRect(
          RRect.fromLTRBR(0.24, 0.2, 0.76, 0.82, const Radius.circular(0.2)),
          pelo,
        );
      case Peinado.mono:
        canvas.drawCircle(const Offset(0.5, 0.15), 0.11, pelo);
      case Peinado.corto ||
          Peinado.rizado ||
          Peinado.calvo ||
          Peinado.flequillo:
        break;
    }

    // Hombros y cuello.
    canvas
      ..drawOval(
        const Rect.fromLTRB(0.14, 0.74, 0.86, 1.3),
        Paint()..color = a.ropa,
      )
      ..drawRect(const Rect.fromLTRB(0.43, 0.6, 0.57, 0.78), piel)
      // Orejas y cabeza.
      ..drawCircle(const Offset(0.285, 0.47), 0.045, piel)
      ..drawCircle(const Offset(0.715, 0.47), 0.045, piel)
      ..drawOval(const Rect.fromLTRB(0.29, 0.21, 0.71, 0.7), piel);

    // Pelo por encima.
    const coronilla = Rect.fromLTRB(0.27, 0.17, 0.73, 0.6);
    switch (a.peinado) {
      case Peinado.corto || Peinado.largo || Peinado.mono:
        canvas.drawArc(coronilla, math.pi, math.pi, true, pelo);
      case Peinado.flequillo:
        canvas
          ..drawArc(coronilla, math.pi, math.pi, true, pelo)
          ..drawRRect(
            RRect.fromLTRBR(0.3, 0.3, 0.66, 0.4, const Radius.circular(0.05)),
            pelo,
          );
      case Peinado.rizado:
        for (var i = 0; i <= 6; i++) {
          final angulo = math.pi + i * math.pi / 6;
          canvas.drawCircle(
            Offset(0.5 + 0.22 * math.cos(angulo), 0.4 + 0.2 * math.sin(angulo)),
            0.075,
            pelo,
          );
        }
      case Peinado.calvo:
        // Un poco de pelo sobre las orejas.
        canvas
          ..drawOval(const Rect.fromLTRB(0.28, 0.36, 0.33, 0.48), pelo)
          ..drawOval(const Rect.fromLTRB(0.67, 0.36, 0.72, 0.48), pelo);
    }

    // Ojos y sonrisa.
    final ojos = Paint()..color = const Color(0xFF2B2B2B);
    canvas
      ..drawCircle(const Offset(0.42, 0.47), 0.026, ojos)
      ..drawCircle(const Offset(0.58, 0.47), 0.026, ojos)
      ..drawArc(
        const Rect.fromLTRB(0.43, 0.5, 0.57, 0.61),
        0.15 * math.pi,
        0.7 * math.pi,
        false,
        trazo,
      );

    if (a.gafas) {
      final montura = Paint()
        ..color = const Color(0xFF1A1A1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.02;
      canvas
        ..drawCircle(const Offset(0.42, 0.47), 0.06, montura)
        ..drawCircle(const Offset(0.58, 0.47), 0.06, montura)
        ..drawLine(const Offset(0.48, 0.47), const Offset(0.52, 0.47), montura);
    }
  }

  @override
  bool shouldRepaint(PintorAvatar oldDelegate) => oldDelegate.avatar != avatar;
}
