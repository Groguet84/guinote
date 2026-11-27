import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:guinote/src/juego/jugadores.dart';

void main() {
  test('se sortean tres rivales con nombres distintos del tuyo', () {
    for (var semilla = 0; semilla < 200; semilla++) {
      final random = Random(semilla);
      final tu = Jugador('pilar', Avatar.aleatorio(random));
      final jugadores = sortearJugadores(random, tu: tu);
      expect(jugadores, hasLength(4));
      expect(jugadores.first, same(tu));
      final nombres = jugadores.map((j) => j.nombre.toLowerCase()).toSet();
      expect(nombres, hasLength(4));
    }
  });

  test('con la misma semilla salen los mismos jugadores', () {
    final a = sortearJugadores(Random(7));
    final b = sortearJugadores(Random(7));
    expect(a.map((j) => j.nombre), b.map((j) => j.nombre));
    expect(a.first.nombre, nombrePorDefecto);
  });
}
