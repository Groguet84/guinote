import 'package:guinote_core/guinote_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('Baraja', () {
    test('tiene 40 cartas distintas', () {
      expect(Carta.baraja, hasLength(40));
      expect(Carta.baraja.toSet(), hasLength(40));
    });

    test('suma 120 puntos', () {
      expect(Carta.baraja.fold(0, (s, c) => s + c.puntos), 120);
    });

    test('no tiene ochos ni nueves', () {
      final numeros = {for (final c in Carta.baraja) c.valor.numero};
      expect(numeros, {1, 2, 3, 4, 5, 6, 7, 10, 11, 12});
    });
  });

  group('Puntos de las cartas', () {
    test('as 11, 3 10, rey 4, sota 3, caballo 2', () {
      expect(c('1o').puntos, 11);
      expect(c('3o').puntos, 10);
      expect(c('12o').puntos, 4);
      expect(c('10o').puntos, 3);
      expect(c('11o').puntos, 2);
    });

    test('7, 6, 5, 4 y 2 no valen puntos', () {
      for (final codigo in ['7o', '6o', '5o', '4o', '2o']) {
        expect(c(codigo).puntos, 0, reason: codigo);
      }
    });
  });

  group('Orden de las cartas', () {
    test('as > 3 > rey > sota > caballo > 7 > 6 > 5 > 4 > 2', () {
      final orden = cs('1c 3c 12c 10c 11c 7c 6c 5c 4c 2c');
      for (var i = 0; i < orden.length - 1; i++) {
        expect(
          orden[i].superaEnPalo(orden[i + 1]),
          isTrue,
          reason: '${orden[i]} debe superar a ${orden[i + 1]}',
        );
        expect(orden[i + 1].superaEnPalo(orden[i]), isFalse);
      }
    });

    test('la sota es más alta que el caballo', () {
      expect(c('10e').superaEnPalo(c('11e')), isTrue);
    });

    test('cartas de distinto palo no se comparan', () {
      expect(c('1o').superaEnPalo(c('2c')), isFalse);
    });
  });

  test('igualdad por valor y palo', () {
    expect(c('12b'), Carta(Valor.rey, Palo.bastos));
    expect(c('12b'), isNot(c('12o')));
    expect(c('12b').toString(), 'rey de bastos');
  });
}
