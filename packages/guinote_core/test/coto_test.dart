import 'dart:math';

import 'package:guinote_core/guinote_core.dart';
import 'package:test/test.dart';

/// Mano que gana la pareja [p] con 130 puntos: basta para ganar la partida.
ResultadoMano manoPara(int p) => ResultadoMano(
  puntosBazas: [p == 0 ? 120 : 0, p == 1 ? 120 : 0],
  puntosCantes: const [0, 0],
  parejaUltimaBaza: p,
);

void main() {
  final inicio = Coto(
    partidasGanadas: const [0, 0],
    partida: Partida(puntos: const [0, 0], repartidor: 1),
  );

  test('un coto nuevo empieza 0-0 y sin ganador', () {
    final coto = Coto.nuevo(Random(1));
    expect(coto.partidasGanadas, [0, 0]);
    expect(coto.terminado, isFalse);
  });

  test('ganar una partida no gana el coto', () {
    final coto = inicio.registrarMano(manoPara(0));
    expect(coto.partida.ganador, 0);
    expect(coto.partidasGanadas, [1, 0]);
    expect(coto.terminado, isFalse);
  });

  test('gana el coto la pareja que gana dos partidas (2-0)', () {
    final coto = inicio
        .registrarMano(manoPara(1))
        .siguientePartida()
        .registrarMano(manoPara(1));
    expect(coto.partidasGanadas, [0, 2]);
    expect(coto.ganador, 1);
  });

  test('con 1-1 se juega una tercera partida', () {
    var coto = inicio
        .registrarMano(manoPara(0))
        .siguientePartida()
        .registrarMano(manoPara(1));
    expect(coto.partidasGanadas, [1, 1]);
    expect(coto.terminado, isFalse);
    coto = coto.siguientePartida().registrarMano(manoPara(0));
    expect(coto.ganador, 0);
  });

  test('la siguiente partida empieza a cero y el reparto sigue rotando', () {
    final acabada = inicio.registrarMano(manoPara(0));
    expect(acabada.partida.repartidor, 2);
    final siguiente = acabada.siguientePartida();
    expect(siguiente.partida.puntos, [0, 0]);
    expect(siguiente.partida.manosJugadas, 0);
    expect(siguiente.partida.repartidor, 2);
  });

  test('no se empieza otra partida si la actual no ha terminado', () {
    final coto = inicio.registrarMano(
      ResultadoMano(
        puntosBazas: const [60, 60],
        puntosCantes: const [0, 0],
        parejaUltimaBaza: 0,
      ),
    );
    expect(coto.siguientePartida, throwsA(isA<AccionInvalida>()));
  });

  test('no se juega después de terminar el coto', () {
    final coto = inicio
        .registrarMano(manoPara(0))
        .siguientePartida()
        .registrarMano(manoPara(0));
    expect(coto.siguientePartida, throwsA(isA<AccionInvalida>()));
    expect(
      () => coto.registrarMano(manoPara(1)),
      throwsA(isA<AccionInvalida>()),
    );
  });
}
