import 'dart:math';

import 'package:guinote_core/guinote_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Mano con triunfo de oros en la que sale el jugador 0. [puntosPartida] es
/// `null` en la ida y los puntos previos de cada pareja de vueltas.
EstadoMano mano({
  required List<String> manos,
  List<int>? puntosPartida,
  String mazo = '2b 4b 5b',
  String? cartaTriunfo = '6o',
  int ganadorAnterior = 0,
  bool conBazaAnterior = false,
}) => EstadoMano(
  repartidor: 3,
  triunfo: Palo.oros,
  cartaTriunfo: cartaTriunfo == null ? null : c(cartaTriunfo),
  mazo: cs(mazo),
  manos: [for (final m in manos) cs(m)],
  turno: ganadorAnterior,
  bazas: conBazaAnterior
      ? [
          Baza(
            jugadas: baza(ganadorAnterior, '2e 4e 5e 6e'),
            ganador: ganadorAnterior,
          ),
        ]
      : const [],
  puntosPartida: puntosPartida,
);

/// Juegan 0, 1, 2 y 3 sus cartas en orden.
EstadoMano bazaDe(EstadoMano e, String cartas) {
  final lista = cs(cartas);
  for (var i = 0; i < 4; i++) {
    e = e.jugar((e.turno), lista[i]);
  }
  return e;
}

void main() {
  group('De vueltas, los puntos cuentan en directo', () {
    test('los puntos de cada baza se suman al momento', () {
      final e = bazaDe(
        mano(
          manos: ['1c 4b', '3c 5b', '2c 6b', '4c 7b'],
          puntosPartida: [60, 30],
        ),
        '1c 3c 2c 4c',
      );
      expect(e.puntosEnJuego, [21, 0]);
      expect(e.fase, Fase.bazaCompleta, reason: '60 + 21 = 81, no llega');
    });

    test('al llegar a 101 la partida se acaba sin jugar el resto', () {
      // Nosotros llevamos 90 (40 buenas) y ganamos una baza de 21 puntos.
      var e = mano(
        manos: ['1c 4b', '3c 5b', '2c 6b', '4c 7b'],
        puntosPartida: [90, 40],
      );
      e = bazaDe(e, '1c 3c 2c 4c');
      expect(e.fase, Fase.terminada);
      expect(
        e.manos.every((m) => m.length == 1),
        isTrue,
        reason: 'quedan cartas',
      );
      expect(e.parejaQueLlega, 0);

      final r = e.resultado;
      expect(r.cortada, isTrue);
      expect(r.totalDe(0), 21, reason: 'sin diez de últimas');
      expect(r.totalDe(1), 0);

      final partida = Partida(
        puntos: const [90, 40],
        repartidor: 3,
        manosJugadas: 1,
      ).registrarMano(r);
      expect(partida.puntos, [111, 40]);
      expect(partida.ganador, 0);
    });

    test('también se acaba si llegan los rivales', () {
      final e = bazaDe(
        mano(
          manos: ['4c 7b', '1c 6b', '5c 5b', '3c 4b'],
          puntosPartida: [40, 85],
          mazo: '',
          cartaTriunfo: null,
        ),
        '4c 1c 5c 3c',
      );
      expect(e.fase, Fase.terminada);
      expect(
        e.manos.every((m) => m.length == 1),
        isTrue,
        reason: 'quedan cartas',
      );
      expect(e.parejaQueLlega, 1);
      expect(e.resultado.cortada, isTrue);
    });

    test('un cante que da los 101 acaba la partida al momento', () {
      // Llevamos 70 y cantamos las 40.
      final e = mano(
        manos: ['12o 10o 2b', '4c', '5c', '6c'],
        puntosPartida: [70, 20],
        conBazaAnterior: true,
      ).cantar(0, Palo.oros);
      expect(e.fase, Fase.terminada);
      expect(e.resultado.totalDe(0), 40);
      expect(e.cantesPosibles(2), isEmpty, reason: 'ya no se canta más');
      expect(() => e.jugar(0, c('2b')), throwsA(isA<AccionInvalida>()));
    });

    test(
      'si nadie llega antes, la mano se juega entera con diez de últimas',
      () {
        // Última baza sin puntos: llevamos 95 y solo las diez de últimas dan los 101.
        final e = bazaDe(
          mano(
            manos: ['7c', '2c', '4c', '5c'],
            puntosPartida: [95, 50],
            mazo: '',
            cartaTriunfo: null,
          ),
          '7c 2c 4c 5c',
        );
        expect(e.fase, Fase.terminada);
        final r = e.resultado;
        expect(r.cortada, isFalse);
        expect(r.totalDe(0), 10);
        final partida = Partida(
          puntos: const [95, 50],
          repartidor: 3,
          manosJugadas: 1,
        ).registrarMano(r);
        expect(partida.ganador, 0);
      },
    );
  });

  group('En la ida', () {
    test('no se corta la mano: se cuenta al final', () {
      final e = bazaDe(
        mano(manos: ['1c 4b', '3c 5b', '2c 6b', '4c 7b']),
        '1c 3c 2c 4c',
      );
      expect(e.esDeVueltas, isFalse);
      expect(e.parejaQueLlega, isNull);
      expect(e.fase, Fase.bazaCompleta);
    });

    test(
      'la primera mano de la partida es la ida; las siguientes, de vueltas',
      () {
        final ida = Partida(puntos: const [0, 0], repartidor: 0);
        expect(ida.repartir(Random(1)).esDeVueltas, isFalse);
        final vueltas = Partida(
          puntos: const [70, 60],
          repartidor: 0,
          manosJugadas: 1,
        );
        final e = vueltas.repartir(Random(1));
        expect(e.esDeVueltas, isTrue);
        expect(e.puntosPartida, [70, 60]);
      },
    );
  });

  test(
    'en partidas aleatorias, una mano de vueltas cortada siempre da los 101',
    () {
      var cortadas = 0;
      for (var s = 0; s < 200; s++) {
        final random = Random(s);
        var partida = Partida(
          puntos: [random.nextInt(100), random.nextInt(100)],
          repartidor: 0,
          manosJugadas: 1,
        );
        var e = partida.repartir(random);
        while (e.fase != Fase.terminada) {
          if (e.fase == Fase.bazaCompleta) {
            e = e.recoger();
            continue;
          }
          final legales = e.jugadasLegalesDe(e.turno);
          e = e.jugar(e.turno, legales[random.nextInt(legales.length)]);
        }
        final r = e.resultado;
        partida = partida.registrarMano(r);
        if (r.cortada) {
          cortadas++;
          expect(partida.puntos[partida.ganador!], greaterThanOrEqualTo(101));
          expect(partida.puntos[1 - partida.ganador!], lessThan(101));
        }
      }
      expect(cortadas, greaterThan(50), reason: 'el caso se da a menudo');
    },
  );
}
