import 'dart:math';

import 'package:guinote_core/guinote_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Una baza ya jugada que ha ganado [ganador] (sin puntos).
Baza bazaGanadaPor(int ganador) =>
    Baza(jugadas: baza(ganador, '2e 4e 5e 6e'), ganador: ganador);

/// Estado tras una baza ganada por [ganador], con mazo y triunfo de oros.
EstadoMano trasBaza({
  required int ganador,
  required List<String> manos,
  Fase fase = Fase.jugando,
  String mazo = '2b 4b 5b',
  String? cartaTriunfo = '1o',
}) => EstadoMano(
  repartidor: 3,
  triunfo: Palo.oros,
  cartaTriunfo: cartaTriunfo == null ? null : c(cartaTriunfo),
  mazo: cs(mazo),
  manos: [for (final m in manos) cs(m)],
  turno: ganador,
  baza: fase == Fase.bazaCompleta ? baza(ganador, '2c 4c 5c 6c') : const [],
  bazas: [bazaGanadaPor(ganador)],
  fase: fase,
);

void main() {
  group('Reparto', () {
    final estado = EstadoMano.repartir(repartidor: 2, random: Random(1));

    test('6 cartas a cada jugador, triunfo destapado y 15 en el mazo', () {
      for (final mano in estado.manos) {
        expect(mano, hasLength(6));
      }
      expect(estado.cartaTriunfo, isNotNull);
      expect(estado.triunfo, estado.cartaTriunfo!.palo);
      expect(estado.mazo, hasLength(15));
      final todas = {
        ...estado.manos.expand((m) => m),
        ...estado.mazo,
        estado.cartaTriunfo!,
      };
      expect(todas, hasLength(40));
    });

    test('sale el jugador a la derecha del repartidor', () {
      expect(estado.turno, 3);
      expect(EstadoMano.repartir(repartidor: 3, random: Random(1)).turno, 0);
    });

    test('al principio no es arrastre y nadie puede cantar ni cambiar', () {
      expect(estado.esArrastre, isFalse);
      for (var j = 0; j < 4; j++) {
        expect(estado.cantesPosibles(j), isEmpty);
        expect(estado.puedeCambiarSiete(j), isFalse);
      }
    });
  });

  group('Turnos y bazas', () {
    final inicio = EstadoMano(
      repartidor: 3,
      triunfo: Palo.oros,
      cartaTriunfo: c('1o'),
      mazo: cs('2b 4b 5b'),
      manos: [cs('1c'), cs('3c'), cs('2o'), cs('12c')],
      turno: 0,
    );

    test('solo puede jugar quien tiene el turno', () {
      expect(() => inicio.jugar(1, c('3c')), throwsA(isA<AccionInvalida>()));
      expect(inicio.jugadasLegalesDe(1), isEmpty);
    });

    test('no se puede jugar una carta que no se tiene', () {
      expect(() => inicio.jugar(0, c('3c')), throwsA(isA<AccionInvalida>()));
    });

    test('se juega en sentido antihorario y gana la baza el triunfo', () {
      var e = inicio.jugar(0, c('1c'));
      expect(e.turno, 1);
      e = e.jugar(1, c('3c')).jugar(2, c('2o')).jugar(3, c('12c'));
      expect(e.fase, Fase.bazaCompleta);
      expect(e.baza, hasLength(4), reason: 'las cartas siguen en la mesa');
      expect(e.bazas.single.ganador, 2);
      expect(e.bazas.single.puntos, 25);
      expect(e.turno, 2);
    });
  });

  group('Robos', () {
    final completa = EstadoMano(
      repartidor: 0,
      triunfo: Palo.oros,
      cartaTriunfo: c('1o'),
      mazo: cs('2b 4b 5b'),
      manos: [cs('1c'), cs('3c'), cs('2o'), cs('12c')],
      turno: 1,
    ).jugar(1, c('3c')).jugar(2, c('2o')).jugar(3, c('12c')).jugar(0, c('1c'));

    test('roba primero el ganador y el último se lleva el triunfo', () {
      expect(completa.bazas.single.ganador, 2);
      final e = completa.recoger();
      expect(e.manos[2], cs('2b'));
      expect(e.manos[3], cs('4b'));
      expect(e.manos[0], cs('5b'));
      expect(e.manos[1], cs('1o'));
      expect(e.cartaTriunfo, isNull);
      expect(e.mazo, isEmpty);
      expect(e.baza, isEmpty);
      expect(e.fase, Fase.jugando);
      expect(e.turno, 2, reason: 'sale el ganador');
      expect(e.esArrastre, isTrue);
    });

    test('en una mano completa hay 4 robos y 6 bazas de arrastre', () {
      var e = EstadoMano.repartir(repartidor: 0, random: Random(7));
      var robos = 0;
      var bazasArrastre = 0;
      while (e.fase != Fase.terminada) {
        if (e.fase == Fase.bazaCompleta) {
          final antes = e.cartasPorRobar;
          e = e.recoger();
          if (e.cartasPorRobar < antes) robos++;
          continue;
        }
        if (e.baza.isEmpty && e.esArrastre) bazasArrastre++;
        e = e.jugar(e.turno, e.jugadasLegalesDe(e.turno).first);
      }
      expect(robos, 4);
      expect(bazasArrastre, 6);
      expect(e.bazas, hasLength(10));
    });
  });

  group('Cantar', () {
    const manos = ['12c 11c 2b', '12e 11e', '12o 11o 12b 11b', '3e'];

    test('rey y caballo: 20 en un palo cualquiera', () {
      final e = trasBaza(ganador: 0, manos: manos).cantar(0, Palo.copas);
      expect(e.cantes.single.puntos, 20);
    });

    test('rey y caballo de triunfo: 40', () {
      final e = trasBaza(ganador: 0, manos: manos).cantar(2, Palo.oros);
      expect(e.cantes.single.puntos, 40);
    });

    test('rey y sota no es cante', () {
      final e = trasBaza(ganador: 0, manos: ['12c 10c', '', '', '']);
      expect(e.cantesPosibles(0), isEmpty);
    });

    test('solo si la última baza la ha ganado su pareja', () {
      final e = trasBaza(ganador: 3, manos: manos);
      expect(e.cantesPosibles(0), isEmpty);
      expect(e.cantesPosibles(2), isEmpty);
      expect(e.cantesPosibles(1), [Palo.espadas]);
      expect(() => e.cantar(0, Palo.copas), throwsA(isA<AccionInvalida>()));
    });

    test('puede cantar el compañero del que ha ganado la baza', () {
      final e = trasBaza(ganador: 0, manos: manos);
      expect(e.cantesPosibles(2), [Palo.oros, Palo.bastos]);
    });

    test('se puede cantar antes de robar', () {
      final e = trasBaza(ganador: 0, manos: manos, fase: Fase.bazaCompleta);
      expect(e.cantesPosibles(0), [Palo.copas]);
      expect(e.cantar(0, Palo.copas).recoger().cantes, hasLength(1));
    });

    test('se puede cantar después de robar con la carta robada', () {
      final e = trasBaza(
        ganador: 0,
        manos: ['12c 2b', '4b', '5b', '6b'],
        fase: Fase.bazaCompleta,
        mazo: '11c 7b 7e',
      );
      expect(e.cantesPosibles(0), isEmpty);
      expect(e.recoger().cantesPosibles(0), [Palo.copas]);
    });

    test('la pareja puede cantar todo lo que tenga en la misma baza', () {
      final e = trasBaza(
        ganador: 0,
        manos: manos,
      ).cantar(0, Palo.copas).cantar(2, Palo.oros).cantar(2, Palo.bastos);
      expect(e.cantes.map((c) => c.puntos), [20, 40, 20]);
    });

    test('cada palo se canta una vez por mano', () {
      final e = trasBaza(ganador: 0, manos: manos).cantar(0, Palo.copas);
      expect(e.cantesPosibles(0), isEmpty);
      expect(() => e.cantar(0, Palo.copas), throwsA(isA<AccionInvalida>()));
    });

    test('no se puede cantar una vez echada la primera carta', () {
      final e = trasBaza(ganador: 0, manos: manos).jugar(0, c('2b'));
      expect(e.cantesPosibles(0), isEmpty);
      expect(e.cantesPosibles(2), isEmpty);
    });

    test('se puede cantar en el arrastre', () {
      final e = trasBaza(
        ganador: 0,
        manos: manos,
        mazo: '',
        cartaTriunfo: null,
      );
      expect(e.esArrastre, isTrue);
      expect(e.cantar(0, Palo.copas).cantes, hasLength(1));
    });

    test('no se canta después de la última baza', () {
      final e = EstadoMano(
        repartidor: 0,
        triunfo: Palo.oros,
        cartaTriunfo: null,
        mazo: const [],
        manos: [cs('2c'), cs('4c'), cs('5c'), cs('6c')],
        turno: 1,
        bazas: [bazaGanadaPor(1)],
      ).jugar(1, c('4c')).jugar(2, c('5c')).jugar(3, c('6c')).jugar(0, c('2c'));
      expect(e.fase, Fase.terminada);
      expect(e.cantesPosibles(3), isEmpty);
    });
  });

  group('Cambiar el 7', () {
    const manos = ['7o 2c', '4c', '5c', '6c'];

    test('el 7 de triunfo se cambia por la carta destapada', () {
      final e = trasBaza(ganador: 2, manos: manos).cambiarSiete(0);
      expect(e.manos[0], cs('1o 2c'));
      expect(e.cartaTriunfo, c('7o'));
    });

    test('solo si la última baza la ha ganado su pareja', () {
      expect(trasBaza(ganador: 1, manos: manos).puedeCambiarSiete(0), isFalse);
      expect(
        () => trasBaza(ganador: 1, manos: manos).cambiarSiete(0),
        throwsA(isA<AccionInvalida>()),
      );
    });

    test('hace falta tener el 7 de triunfo', () {
      final e = trasBaza(ganador: 0, manos: ['7c', '', '', '']);
      expect(e.puedeCambiarSiete(0), isFalse);
    });

    test('antes del último robo sí; el que roba el último se lleva el 7', () {
      final e = trasBaza(
        ganador: 0,
        manos: manos,
        fase: Fase.bazaCompleta,
      ).cambiarSiete(0);
      final robado = e.recoger();
      expect(robado.manos[3].last, c('7o'));
      expect(robado.cartaTriunfo, isNull);
    });

    test('cuando ya no hay triunfo en la mesa, no', () {
      final e = trasBaza(
        ganador: 0,
        manos: manos,
        mazo: '',
        cartaTriunfo: null,
      );
      expect(e.puedeCambiarSiete(0), isFalse);
    });
  });
}
