import 'dart:math';

import 'package:guinote_core/guinote_core.dart';
import 'package:test/test.dart';

/// Juega una mano con jugadores aleatorios que cantan y cambian el 7 cuando
/// pueden, comprobando invariantes en cada paso.
EstadoMano jugarManoAleatoria(EstadoMano e, Random random) {
  while (e.fase != Fase.terminada) {
    for (var j = 0; j < numJugadores; j++) {
      if (e.puedeCambiarSiete(j) && random.nextBool()) e = e.cambiarSiete(j);
      for (final palo in e.cantesPosibles(j)) {
        if (e.fase == Fase.terminada) break;
        e = e.cantar(j, palo);
      }
    }
    if (e.fase == Fase.terminada) break;
    if (e.fase == Fase.bazaCompleta) {
      e = e.recoger();
      continue;
    }
    final legales = e.jugadasLegalesDe(e.turno);
    expect(legales, isNotEmpty, reason: 'siempre hay alguna carta legal');
    expect(e.manos[e.turno], containsAll(legales));
    e = e.jugar(e.turno, legales[random.nextInt(legales.length)]);
    _compruebaCartas(e);
  }
  return e;
}

/// Las 40 cartas están siempre en algún sitio y ninguna está repetida.
void _compruebaCartas(EstadoMano e) {
  final enBazas = [for (final b in e.bazas) ...b.jugadas.map((j) => j.carta)];
  final enMesa = e.fase == Fase.jugando
      ? e.baza.map((j) => j.carta)
      : const <Carta>[];
  final todas = [
    ...e.manos.expand((m) => m),
    ...e.mazo,
    ?e.cartaTriunfo,
    ...enBazas,
    ...enMesa,
  ];
  expect(todas, hasLength(40));
  expect(todas.toSet(), hasLength(40));
}

void main() {
  test('500 manos aleatorias cumplen las reglas y reparten 130 + cantes', () {
    for (var semilla = 0; semilla < 500; semilla++) {
      final random = Random(semilla);
      final inicio = EstadoMano.repartir(
        repartidor: semilla % 4,
        random: random,
      );
      final fin = jugarManoAleatoria(inicio, random);
      final r = fin.resultado;
      final cantes = fin.cantes.fold(0, (s, c) => s + c.puntos);
      expect(fin.bazas, hasLength(10));
      expect(
        r.totalDe(0) + r.totalDe(1),
        130 + cantes,
        reason: 'semilla $semilla',
      );
    }
  });

  test('las partidas aleatorias terminan con un ganador', () {
    for (var semilla = 0; semilla < 50; semilla++) {
      final random = Random(semilla);
      var partida = Partida.nueva(random);
      while (!partida.terminada) {
        final fin = jugarManoAleatoria(partida.repartir(random), random);
        partida = partida.registrarMano(fin.resultado);
      }
      expect(partida.puntos[partida.ganador!], greaterThanOrEqualTo(101));
    }
  });
}
