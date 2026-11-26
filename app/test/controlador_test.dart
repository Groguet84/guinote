import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:guinote/src/juego/controlador_partida.dart';
import 'package:guinote_core/guinote_core.dart';

const reyCopas = Carta(Valor.rey, Palo.copas);
const caballoCopas = Carta(Valor.caballo, Palo.copas);
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

final partidaNueva = Partida(puntos: const [0, 0], repartidor: 0);

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

  testWidgets('se juega una partida entera hasta el final', (tester) async {
    final c = ControladorPartida(random: Random(9));
    var pasos = 0;
    while (!c.partida.terminada) {
      expect(pasos++, lessThan(5000), reason: 'la partida no avanza');
      if (c.resultado != null) {
        final r = c.resultado!;
        expect(r.totalDe(0) + r.totalDe(1), greaterThanOrEqualTo(130));
        c.siguienteMano();
      } else if (c.turnoHumano) {
        c.jugar(c.jugablesHumano.first);
      } else {
        await tester.pump(const Duration(milliseconds: 500));
      }
    }
    expect(c.partida.puntos[c.partida.ganador!], greaterThanOrEqualTo(101));
    c.dispose();
  });

  testWidgets('la baza completa se recoge sola a los 3 segundos', (
    tester,
  ) async {
    final c = ControladorPartida.desde(
      partida: partidaNueva,
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
        [reyCopas, caballoCopas],
        [const Carta(Valor.dos, Palo.copas)],
        [const Carta(Valor.cuatro, Palo.copas)],
        [const Carta(Valor.cinco, Palo.copas)],
      ],
    );

    testWidgets('el compañero espera antes de salir', (tester) async {
      final c = ControladorPartida.desde(partida: partidaNueva, mano: estado());
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
      final c = ControladorPartida.desde(partida: partidaNueva, mano: estado());
      await tester.pump(const Duration(seconds: 4));
      expect(c.mano.baza, isNotEmpty);
      expect(c.mano.cantes, isEmpty);
      c.dispose();
    });
  });

  testWidgets('la IA cambia el 7 antes de robar', (tester) async {
    final c = ControladorPartida.desde(
      partida: partidaNueva,
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
}
