import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:guinote/src/juego/controlador_partida.dart';
import 'package:guinote_core/guinote_core.dart';

const reyCopas = Carta(Valor.rey, Palo.copas);
const sotaCopas = Carta(Valor.sota, Palo.copas);
const sieteOros = Carta(Valor.siete, Palo.oros);
const asOros = Carta(Valor.as, Palo.oros);

/// Estado justo después de que [ganador] gane una baza, con triunfo de oros.
EstadoMano trasBaza({
  required int ganador,
  required List<List<Carta>> manos,
  Fase fase = Fase.jugando,
}) {
  Carta cBastos(Valor v) => Carta(v, Palo.bastos);
  final jugadas = [
    for (var i = 0; i < 4; i++)
      (jugador: (ganador + i) % 4, carta: Carta(Valor.values[i], Palo.espadas)),
  ];
  return EstadoMano(
    repartidor: 0,
    triunfo: Palo.oros,
    cartaTriunfo: asOros,
    mazo: [cBastos(Valor.dos), cBastos(Valor.cuatro), cBastos(Valor.cinco)],
    manos: manos,
    turno: ganador,
    baza: fase == Fase.bazaCompleta ? jugadas : const [],
    bazas: [Baza(jugadas: jugadas, ganador: ganador)],
    fase: fase,
  );
}

final cotoNuevo = Coto(
  partidasGanadas: const [0, 0],
  partida: Partida(puntos: const [0, 0], repartidor: 0),
);

void main() {
  testWidgets('la IA juega sola hasta que te toca', (tester) async {
    final c = ControladorPartida(random: Random(4));
    for (var i = 0; i < 20 && !c.turnoHumano; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(c.turnoHumano, isTrue);
    expect(c.jugablesHumano, isNotEmpty);
    c.dispose();
  });

  testWidgets('se juega un coto entero, al mejor de tres partidas', (
    tester,
  ) async {
    final c = ControladorPartida(random: Random(9));
    var pasos = 0;
    var partidas = 0;
    while (!(c.coto.terminado && c.resultado != null)) {
      expect(pasos++, lessThan(20000), reason: 'el coto no avanza');
      if (c.resultado != null) {
        final r = c.resultado!;
        if (!r.cortada) {
          expect(r.totalDe(0) + r.totalDe(1), greaterThanOrEqualTo(130));
        }
        if (c.partida.terminada) {
          partidas++;
          expect(
            c.partida.puntos[c.partida.ganador!],
            greaterThanOrEqualTo(101),
          );
        }
        c.continuar();
        if (c.resultado == null) {
          expect(c.partida.puntos, isNot(contains(greaterThanOrEqualTo(101))));
        }
      } else if (c.turnoHumano) {
        c.jugar(c.jugablesHumano.first);
      } else {
        await tester.pump(const Duration(milliseconds: 500));
      }
    }
    expect(c.coto.partidasGanadas[c.coto.ganador!], 2);
    expect(partidas + 1, c.coto.partidasGanadas.reduce((a, b) => a + b));
    expect(partidas + 1, inInclusiveRange(2, 3));
    c.dispose();
  });

  testWidgets('la baza completa se recoge sola a los 3 segundos', (
    tester,
  ) async {
    final c = ControladorPartida.desde(
      coto: cotoNuevo,
      mano: trasBaza(
        ganador: 1,
        manos: List.generate(4, (_) => const <Carta>[]),
        fase: Fase.bazaCompleta,
      ),
    );
    expect(c.mano.baza, hasLength(4));
    await tester.pump(const Duration(milliseconds: 2900));
    expect(c.mano.fase, Fase.bazaCompleta);
    await tester.pump(const Duration(milliseconds: 200));
    expect(c.mano.fase, Fase.jugando);
    expect(c.mano.baza, isEmpty);
    expect(c.mano.manos.every((m) => m.length == 1), isTrue);
    c.dispose();
  });

  group('cuando tu compañero gana la baza y tú puedes cantar', () {
    EstadoMano estado() => trasBaza(
      ganador: 2,
      manos: [
        [reyCopas, sotaCopas],
        [const Carta(Valor.dos, Palo.copas)],
        [const Carta(Valor.cuatro, Palo.copas)],
        [const Carta(Valor.cinco, Palo.copas)],
      ],
    );

    testWidgets('el compañero espera antes de salir', (tester) async {
      final c = ControladorPartida.desde(coto: cotoNuevo, mano: estado());
      await tester.pump(c.retardoIa + const Duration(milliseconds: 100));
      expect(c.mano.baza, isEmpty, reason: 'aún no ha salido');
      expect(c.cantesHumano, [Palo.copas]);

      c.cantar(Palo.copas);
      expect(c.mano.cantes.single.puntos, 20);
      expect(c.aviso, 'Cantas las 20 en copas');

      await tester.pump(c.esperaAnuncio);
      expect(c.mano.baza.first.jugador, 2, reason: 'ya ha salido');
      c.dispose();
    });

    testWidgets('la IA no canta por ti', (tester) async {
      final c = ControladorPartida.desde(coto: cotoNuevo, mano: estado());
      await tester.pump(const Duration(seconds: 4));
      expect(c.mano.baza, isNotEmpty);
      expect(c.mano.cantes, isEmpty);
      c.dispose();
    });
  });

  testWidgets('la IA cambia el 7 antes de robar', (tester) async {
    final c = ControladorPartida.desde(
      coto: cotoNuevo,
      mano: trasBaza(
        ganador: 1,
        manos: [
          const [],
          [sieteOros],
          const [],
          const [],
        ],
        fase: Fase.bazaCompleta,
      ),
    );
    expect(c.mano.cartaTriunfo, sieteOros);
    expect(c.mano.manos[1], [asOros]);
    expect(c.aviso, 'Rival derecho cambia el 7');
    c.dispose();
  });

  testWidgets('no se puede echar una carta que no toca', (tester) async {
    final c = ControladorPartida(random: Random(4));
    final antes = c.mano;
    if (!c.turnoHumano) {
      c.jugar(c.mano.manos[ControladorPartida.humano].first);
      expect(c.mano, same(antes));
    }
    c.dispose();
  });

  group('orden de tu mano', () {
    ControladorPartida enTuTurno() => ControladorPartida.desde(
      coto: cotoNuevo,
      mano: EstadoMano(
        repartidor: 3,
        triunfo: Palo.oros,
        cartaTriunfo: asOros,
        mazo: [
          const Carta(Valor.dos, Palo.bastos),
          const Carta(Valor.cuatro, Palo.bastos),
          const Carta(Valor.cinco, Palo.bastos),
        ],
        manos: [
          [reyCopas, sieteOros, const Carta(Valor.tres, Palo.espadas)],
          [const Carta(Valor.dos, Palo.copas)],
          [const Carta(Valor.cuatro, Palo.copas)],
          [const Carta(Valor.cinco, Palo.copas)],
        ],
        turno: 0,
      ),
    );

    testWidgets('al repartir, la mano sale agrupada por palos', (tester) async {
      final c = enTuTurno();
      expect(c.manoHumano, [
        sieteOros,
        reyCopas,
        const Carta(Valor.tres, Palo.espadas),
      ]);
      c.dispose();
    });

    testWidgets('puedes mover una carta de sitio', (tester) async {
      final c = enTuTurno();
      c.reordenar(2, 0);
      expect(c.manoHumano, [
        const Carta(Valor.tres, Palo.espadas),
        sieteOros,
        reyCopas,
      ]);
      c.ordenarMano();
      expect(c.manoHumano, [
        sieteOros,
        reyCopas,
        const Carta(Valor.tres, Palo.espadas),
      ]);
      c.dispose();
    });

    testWidgets('tu orden se mantiene al jugar y lo robado va al final', (
      tester,
    ) async {
      final c = enTuTurno();
      c.reordenar(2, 0); // 3 de espadas, 7 de oros, rey de copas
      c.jugar(sieteOros);
      expect(c.manoHumano, [const Carta(Valor.tres, Palo.espadas), reyCopas]);
      // Juegan los demás, se ve la baza 3 s y se roba.
      await tester.pump(const Duration(seconds: 7));
      expect(c.manoHumano, hasLength(3));
      expect(c.manoHumano.take(2), [
        const Carta(Valor.tres, Palo.espadas),
        reyCopas,
      ]);
      c.dispose();
    });

    testWidgets('al cambiar el 7, el triunfo ocupa su sitio', (tester) async {
      final c = ControladorPartida.desde(
        coto: cotoNuevo,
        mano: trasBaza(
          ganador: 0,
          manos: [
            [reyCopas, sieteOros, sotaCopas],
            const [],
            const [],
            const [],
          ],
        ),
      );
      // Repartida: 7 de oros, rey de copas, sota de copas. El 7 al medio.
      c.reordenar(0, 1);
      expect(c.manoHumano, [reyCopas, sieteOros, sotaCopas]);
      c.cambiarSiete();
      expect(c.manoHumano, [reyCopas, asOros, sotaCopas]);
      c.dispose();
    });
  });

  group('de vueltas', () {
    Coto cotoDeVueltas(List<int> puntos) => Coto(
      partidasGanadas: const [0, 0],
      partida: Partida(puntos: puntos, repartidor: 3, manosJugadas: 1),
    );

    EstadoMano manoDeVueltas(List<int> puntos, List<List<Carta>> manos) =>
        EstadoMano(
          repartidor: 3,
          triunfo: Palo.oros,
          cartaTriunfo: const Carta(Valor.seis, Palo.oros),
          mazo: const [
            Carta(Valor.dos, Palo.bastos),
            Carta(Valor.cuatro, Palo.bastos),
            Carta(Valor.cinco, Palo.bastos),
          ],
          manos: manos,
          turno: 0,
          bazas: [
            Baza(
              jugadas: [
                for (var j = 0; j < 4; j++)
                  (jugador: j, carta: Carta(Valor.values[j], Palo.espadas)),
              ],
              ganador: 0,
            ),
          ],
          puntosPartida: puntos,
        );

    testWidgets('el marcador suma los puntos en directo', (tester) async {
      final c = ControladorPartida.desde(
        coto: cotoDeVueltas([60, 30]),
        mano: manoDeVueltas(
          [60, 30],
          [
            [
              const Carta(Valor.as, Palo.copas),
              const Carta(Valor.dos, Palo.bastos),
            ],
            [
              const Carta(Valor.tres, Palo.copas),
              const Carta(Valor.cuatro, Palo.bastos),
            ],
            [
              const Carta(Valor.dos, Palo.copas),
              const Carta(Valor.cinco, Palo.bastos),
            ],
            [
              const Carta(Valor.cuatro, Palo.copas),
              const Carta(Valor.seis, Palo.bastos),
            ],
          ],
        ),
      );
      expect(c.puntosMarcador, [60, 30]);
      c.jugar(const Carta(Valor.as, Palo.copas));
      await tester.pump(const Duration(seconds: 3));
      final baza = c.mano.bazas.last;
      expect(baza.ganador, 0, reason: 'el as de copas gana');
      expect(baza.puntos, greaterThanOrEqualTo(11));
      expect(c.puntosMarcador, [
        60 + baza.puntos,
        30,
      ], reason: 'los puntos de la baza se suman al momento');
      c.dispose();
    });

    testWidgets('si tu cante da los 101, se acaba la partida', (tester) async {
      final c = ControladorPartida.desde(
        coto: cotoDeVueltas([70, 20]),
        mano: manoDeVueltas(
          [70, 20],
          [
            [
              const Carta(Valor.rey, Palo.oros),
              const Carta(Valor.sota, Palo.oros),
            ],
            [
              const Carta(Valor.dos, Palo.copas),
              const Carta(Valor.dos, Palo.espadas),
            ],
            [
              const Carta(Valor.cuatro, Palo.copas),
              const Carta(Valor.cuatro, Palo.espadas),
            ],
            [
              const Carta(Valor.cinco, Palo.copas),
              const Carta(Valor.cinco, Palo.espadas),
            ],
          ],
        ),
      );
      c.cantar(Palo.oros);
      expect(c.puntosMarcador, [110, 20]);
      expect(c.mano.fase, Fase.terminada);
      expect(c.aviso, '¡Llegáis a 51 buenas! Se acaba la partida');
      await tester.pump(c.retardoRecoger);
      expect(c.resultado!.cortada, isTrue);
      expect(c.partida.ganador, 0);
      expect(c.coto.partidasGanadas, [1, 0]);
      c.dispose();
    });

    testWidgets('en la ida el marcador no cambia hasta acabar la mano', (
      tester,
    ) async {
      final c = ControladorPartida(random: Random(4));
      for (var i = 0; i < 40 && c.mano.bazas.isEmpty; i++) {
        if (c.turnoHumano) c.jugar(c.jugablesHumano.first);
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(c.mano.bazas, isNotEmpty);
      expect(c.mano.esDeVueltas, isFalse);
      expect(c.puntosMarcador, [0, 0]);
      c.dispose();
    });
  });
}
