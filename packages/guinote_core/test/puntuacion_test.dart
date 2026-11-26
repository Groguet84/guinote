import 'dart:math';

import 'package:guinote_core/guinote_core.dart';
import 'package:test/test.dart';

ResultadoMano resultado(
  int bazas0,
  int bazas1, {
  int ultima = 0,
  List<int> cantes = const [0, 0],
}) => ResultadoMano(
  puntosBazas: [bazas0, bazas1],
  puntosCantes: cantes,
  parejaUltimaBaza: ultima,
);

Partida partida(int p0, int p1, {int manos = 1}) =>
    Partida(puntos: [p0, p1], repartidor: 0, manosJugadas: manos);

void main() {
  group('Recuento de la mano', () {
    test('bazas + cantes + 10 de últimas', () {
      final r = resultado(70, 50, ultima: 1, cantes: const [40, 20]);
      expect(r.totalDe(0), 110);
      expect(r.totalDe(1), 80);
    });

    test('una mano completa reparte 130 puntos más los cantes', () {
      final random = Random(3);
      var e = EstadoMano.repartir(repartidor: 0, random: random);
      while (e.fase != Fase.terminada) {
        e = e.fase == Fase.bazaCompleta
            ? e.recoger()
            : e.jugar(e.turno, e.jugadasLegalesDe(e.turno).first);
      }
      final r = e.resultado;
      expect(r.totalDe(0) + r.totalDe(1), 130);
      expect(r.parejaUltimaBaza, parejaDe(e.bazas.last.ganador));
    });

    test('no hay resultado hasta que termina la mano', () {
      final e = EstadoMano.repartir(repartidor: 0, random: Random(1));
      expect(() => e.resultado, throwsA(isA<AccionInvalida>()));
    });
  });

  group('Malas y buenas', () {
    test('los primeros 50 puntos son malas', () {
      expect(Partida.malasDe(30), 30);
      expect(Partida.buenasDe(30), 0);
      expect(Partida.malasDe(50), 50);
      expect(Partida.buenasDe(50), 0);
    });

    test('a partir de 50 se cuentan buenas', () {
      expect(Partida.malasDe(80), 50);
      expect(Partida.buenasDe(80), 30);
    });
  });

  group('Final de partida', () {
    test('con 100 puntos (50 buenas) no se gana', () {
      final p = partida(0, 0, manos: 0).registrarMano(resultado(90, 30));
      expect(p.puntos, [100, 30]);
      expect(p.terminada, isFalse);
    });

    test('con 101 puntos (51 buenas) se gana', () {
      final p = partida(0, 0, manos: 0).registrarMano(resultado(91, 29));
      expect(p.ganador, 0);
      expect(p.deVueltas, isFalse, reason: 'ya no se juegan más manos');
    });

    test('se puede ganar en la primera mano', () {
      final p = partida(
        0,
        0,
        manos: 0,
      ).registrarMano(resultado(80, 40, cantes: const [40, 0]));
      expect(p.ganador, 0);
    });

    test('las manos de vueltas suman a lo que ya se tenía', () {
      var p = partida(0, 0, manos: 0);
      expect(p.deVueltas, isFalse);
      p = p.registrarMano(resultado(70, 50, ultima: 1));
      expect(p.puntos, [70, 60]);
      expect(p.terminada, isFalse);
      expect(p.deVueltas, isTrue);
      p = p.registrarMano(resultado(20, 100));
      expect(p.puntos, [100, 160]);
      expect(p.ganador, 1);
    });

    test('si las dos llegan a 101, gana la que hace la última baza', () {
      final base = partida(80, 90);
      expect(base.registrarMano(resultado(60, 60, ultima: 0)).ganador, 0);
      expect(base.registrarMano(resultado(60, 60, ultima: 1)).ganador, 1);
    });

    test('el repartidor rota en sentido antihorario', () {
      final p = Partida(puntos: const [0, 0], repartidor: 3);
      final siguiente = p.registrarMano(resultado(60, 60));
      expect(siguiente.repartidor, 0);
      expect(siguiente.manosJugadas, 1);
    });

    test('el primer repartidor se elige al azar', () {
      final repartidores = {
        for (var s = 0; s < 50; s++) Partida.nueva(Random(s)).repartidor,
      };
      expect(repartidores, {0, 1, 2, 3});
    });

    test('no se juega después de terminar', () {
      final p = partida(0, 0).registrarMano(resultado(120, 0));
      expect(() => p.repartir(Random(1)), throwsA(isA<AccionInvalida>()));
      expect(
        () => p.registrarMano(resultado(0, 0)),
        throwsA(isA<AccionInvalida>()),
      );
    });
  });
}
