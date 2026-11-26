import 'dart:math';

import 'package:guinote_core/guinote_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

const ia = Ia();

/// Estado en el que le toca a [jugador] tras las cartas [enMesa] (salió
/// [salida]). Triunfo de oros. Con [arrastre], sin mazo ni triunfo.
EstadoMano mesa({
  required int jugador,
  required String mano,
  required int salida,
  String enMesa = '',
  bool arrastre = false,
  String jugadas = '',
}) {
  final enLaMesa = baza(salida, enMesa);
  assert((salida + enLaMesa.length) % 4 == jugador, 'turno incoherente');
  return EstadoMano(
    repartidor: 0,
    triunfo: Palo.oros,
    cartaTriunfo: arrastre ? null : c('6o'),
    mazo: arrastre ? const [] : cs('2b 4b 5b'),
    manos: [
      for (var j = 0; j < 4; j++) j == jugador ? cs(mano) : const <Carta>[],
    ],
    turno: jugador,
    baza: enLaMesa,
    bazas: jugadas.isEmpty
        ? const []
        : [Baza(jugadas: baza(0, jugadas), ganador: 0)],
  );
}

Carta elige(EstadoMano e) => ia.elegirCarta(VistaJugador.de(e, e.turno));

/// Juega una mano en la que la pareja 0 usa la IA y la 1 [otra] (o la IA).
EstadoMano jugarMano(
  EstadoMano e,
  Random random, {
  bool rivalesAleatorios = false,
}) {
  bool usaIa(int j) => !rivalesAleatorios || parejaDe(j) == 0;
  while (e.fase != Fase.terminada) {
    for (var j = 0; j < 4; j++) {
      if (usaIa(j)) e = ia.anunciar(e, j);
    }
    if (e.fase == Fase.bazaCompleta) {
      e = e.recoger();
      continue;
    }
    final j = e.turno;
    final legales = e.jugadasLegalesDe(j);
    final carta = usaIa(j)
        ? ia.elegirCarta(VistaJugador.de(e, j))
        : legales[random.nextInt(legales.length)];
    expect(legales, contains(carta));
    e = e.jugar(j, carta);
  }
  return e;
}

void main() {
  group('Responder a una baza', () {
    test('carga puntos si la baza es del compañero y es el último', () {
      // Sale el rival 3, el compañero (0) echa el as de copas y el rival 1 el 5:
      // la baza es del compañero y el jugador 2 es el último.
      final e = mesa(
        jugador: 2,
        mano: '3e 2b 12o',
        salida: 3,
        enMesa: '4c 1c 5c',
      );
      expect(elige(e), c('3e'));
    });

    test('no carga si un rival puede superar al compañero', () {
      final e = mesa(
        jugador: 2,
        mano: '1e 4b 12o',
        salida: 0,
        enMesa: '12c 2c',
      );
      expect(elige(e), c('4b'));
    });

    test('mata con la carta más barata que gana', () {
      final e = mesa(
        jugador: 2,
        mano: '1c 3c 4b',
        salida: 3,
        enMesa: '12c 2c 4c',
      );
      expect(elige(e), c('3c'));
    });

    test('no gasta un triunfo en una baza sin puntos', () {
      final e = mesa(jugador: 2, mano: '2o 5e', salida: 1, enMesa: '4c');
      expect(elige(e), c('5e'));
    });

    test('falla con el triunfo más bajo si la baza tiene puntos', () {
      final e = mesa(jugador: 2, mano: '1o 2o 5e', salida: 1, enMesa: '1c');
      expect(elige(e), c('2o'));
    });

    test('no se deshace del rey ni del caballo si puede cantarlos', () {
      final e = mesa(jugador: 2, mano: '12e 11e 10b', salida: 1, enMesa: '4c');
      expect(elige(e), c('10b'));
    });
  });

  group('Salir', () {
    test('con mazo sale con la carta más pobre que no es triunfo', () {
      final e = mesa(jugador: 0, mano: '1c 7o 4e 10b', salida: 0);
      expect(elige(e), c('4e'));
    });

    test('en el arrastre sale con el triunfo más alto si quedan triunfos', () {
      final e = mesa(jugador: 0, mano: '1o 4c 5e', salida: 0, arrastre: true);
      expect(elige(e), c('1o'));
    });

    test('sin triunfos fuera, sale con la carta que gana seguro', () {
      // Ya han salido todos los triunfos que no tiene.
      final e = mesa(
        jugador: 0,
        mano: '4c 1e',
        salida: 0,
        arrastre: true,
        jugadas: '1o 3o 12o 10o 11o 7o 6o 5o 4o 2o',
      );
      expect(elige(e), c('1e'));
    });
  });

  group('Cantes y cambio del 7', () {
    EstadoMano tras(String mano, {String destapada = '1o'}) => EstadoMano(
      repartidor: 0,
      triunfo: Palo.oros,
      cartaTriunfo: c(destapada),
      mazo: cs('2b 4b 5b'),
      manos: [cs(mano), const [], const [], const []],
      turno: 0,
      bazas: [Baza(jugadas: baza(0, '2e 4e 5e 6e'), ganador: 0)],
    );

    test('cambia el 7 si la carta destapada es mejor', () {
      expect(ia.quiereCambiarSiete(VistaJugador.de(tras('7o'), 0)), isTrue);
      expect(
        ia.quiereCambiarSiete(VistaJugador.de(tras('7o', destapada: '2o'), 0)),
        isFalse,
      );
    });

    test('cambia el 7 antes de cantar: la carta recogida puede dar las 40', () {
      final e = ia.anunciar(tras('7o 11o 12c 11c', destapada: '12o'), 0);
      expect(e.cartaTriunfo, c('7o'));
      expect(e.cantes.map((c) => c.puntos), [40, 20]);
    });
  });

  group('Partidas completas', () {
    test('la IA siempre hace jugadas legales', () {
      for (var s = 0; s < 300; s++) {
        final random = Random(s);
        final fin = jugarMano(
          EstadoMano.repartir(repartidor: s % 4, random: random),
          random,
        );
        final cantes = fin.cantes.fold(0, (t, c) => t + c.puntos);
        expect(
          fin.resultado.totalDe(0) + fin.resultado.totalDe(1),
          130 + cantes,
        );
      }
    });

    test('la IA gana claramente a jugadores aleatorios', () {
      const partidas = 300;
      var ganadas = 0;
      for (var s = 0; s < partidas; s++) {
        final random = Random(s);
        var partida = Partida.nueva(random);
        while (!partida.terminada) {
          final fin = jugarMano(
            partida.repartir(random),
            random,
            rivalesAleatorios: true,
          );
          partida = partida.registrarMano(fin.resultado);
        }
        if (partida.ganador == 0) ganadas++;
      }
      printOnFailure('La IA gana $ganadas de $partidas');
      expect(ganadas / partidas, greaterThan(0.75));
    });
  });
}
