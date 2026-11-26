import 'package:flutter/material.dart';
import 'package:guinote_core/guinote_core.dart';

import '../cartas/pintor_carta.dart';

/// Texto de malas y buenas: «32 malas» o «14 buenas».
String textoMalasBuenas(int puntos) => puntos <= Partida.malas
    ? '$puntos ${puntos == 1 ? 'mala' : 'malas'}'
    : '${Partida.buenasDe(puntos)} ${Partida.buenasDe(puntos) == 1 ? 'buena' : 'buenas'}';

const List<String> nombresParejas = ['Nosotros', 'Ellos'];

/// Marcador del coto y de la partida, triunfo de la mano y menú.
class Marcador extends StatelessWidget {
  const Marcador({
    super.key,
    required this.coto,
    required this.triunfo,
    required this.onNuevoCoto,
  });

  final Coto coto;
  final Palo triunfo;
  final VoidCallback onNuevoCoto;

  @override
  Widget build(BuildContext context) {
    final partida = coto.partida;
    final estilo = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: const Color(0xCC0B2E13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x55FFFFFF)),
      ),
      child: DefaultTextStyle(
        style: estilo.bodyMedium!.copyWith(color: Colors.white),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Coto (al mejor de 3): '
                  '${coto.partidasGanadas[0]} - ${coto.partidasGanadas[1]}',
                  key: const ValueKey('marcador-coto'),
                  style: const TextStyle(color: Color(0xFFFFD54F)),
                ),
                for (var p = 0; p < 2; p++)
                  Text.rich(
                    key: ValueKey('marcador-$p'),
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${nombresParejas[p]}  ${partida.puntos[p]}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: '  ${textoMalasBuenas(partida.puntos[p])}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Triunfo: ${triunfo.nombre}'),
                    const SizedBox(width: 6),
                    SimboloPalo(triunfo, tamano: 18),
                  ],
                ),
                if (partida.deVueltas)
                  const Text(
                    'De vueltas',
                    style: TextStyle(color: Color(0xFFFFD54F)),
                  ),
              ],
            ),
            PopupMenuButton<void>(
              tooltip: 'Menú',
              iconColor: Colors.white,
              itemBuilder: (_) => [
                PopupMenuItem(
                  onTap: onNuevoCoto,
                  child: const Text('Nuevo coto'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// El símbolo de un palo como widget.
class SimboloPalo extends StatelessWidget {
  const SimboloPalo(this.palo, {super.key, required this.tamano});

  final Palo palo;
  final double tamano;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(tamano), painter: _PintorSimbolo(palo));
}

class _PintorSimbolo extends CustomPainter {
  const _PintorSimbolo(this.palo);

  final Palo palo;

  @override
  void paint(Canvas canvas, Size size) =>
      pintarSimbolo(canvas, palo, size.center(Offset.zero), size.height);

  @override
  bool shouldRepaint(_PintorSimbolo oldDelegate) => oldDelegate.palo != palo;
}
