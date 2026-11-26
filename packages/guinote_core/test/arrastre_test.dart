import 'package:guinote_core/guinote_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  const triunfo = Palo.oros;

  /// Jugadas legales para el jugador al que le toca tras [enMesa],
  /// que ha salido [salida].
  List<Carta> legales({
    required String mano,
    required int salida,
    required String enMesa,
    bool arrastre = true,
  }) {
    final b = baza(salida, enMesa);
    return jugadasLegales(
      mano: cs(mano),
      baza: b,
      triunfo: triunfo,
      arrastre: arrastre,
      jugador: (salida + b.length) % numJugadores,
    );
  }

  group('Con mazo', () {
    test('se puede echar cualquier carta', () {
      expect(
        legales(mano: '1c 2o 3e', salida: 1, enMesa: '12c', arrastre: false),
        cs('1c 2o 3e'),
      );
    });
  });

  group('Arrastre', () {
    test('el que sale echa cualquier carta', () {
      expect(legales(mano: '1c 2o 3e', salida: 0, enMesa: ''), cs('1c 2o 3e'));
    });

    group('seguir el palo', () {
      test('si gana un rival hay que matar si se puede', () {
        // Sale el rival 1 con el rey de copas; juega 2.
        expect(
          legales(mano: '1c 4c 2o 3e', salida: 1, enMesa: '12c'),
          cs('1c'),
        );
      });

      test('si gana un rival y no se puede matar, cualquiera del palo', () {
        expect(
          legales(mano: '4c 2c 2o', salida: 1, enMesa: '12c'),
          cs('4c 2c'),
        );
      });

      test('si gana el compañero, cualquier carta del palo', () {
        // Compañero (0) sale con el 3 de copas, rival (1) echa el 2 de copas:
        // con el as de copas en la mano se puede echar el 5 de copas.
        expect(
          legales(mano: '1c 5c 2o', salida: 0, enMesa: '3c 2c'),
          cs('1c 5c'),
        );
      });

      test('si un rival ha fallado con triunfo, cualquiera del palo', () {
        expect(
          legales(mano: '1c 5c 2o', salida: 0, enMesa: '4c 2o'),
          cs('1c 5c'),
        );
      });

      test('si sale triunfo y gana un rival, hay que matar con triunfo', () {
        expect(legales(mano: '1o 4o 1c', salida: 1, enMesa: '12o'), cs('1o'));
      });

      test('si el rival supera al compañero, hay que matar al rival', () {
        // Sale el compañero (0) con la sota, el rival (1) echa el rey.
        expect(
          legales(mano: '1c 3c 4c', salida: 0, enMesa: '10c 12c'),
          cs('1c 3c'),
        );
      });
    });

    group('sin cartas del palo', () {
      test('si gana un rival hay que echar un triunfo que lo mate', () {
        expect(
          legales(mano: '2o 7o 1e', salida: 1, enMesa: '12c'),
          cs('2o 7o'),
        );
      });

      test(
        'si el rival ya ha fallado, hay que matarlo con un triunfo mayor',
        () {
          // Sale el compañero (0), el rival (1) falla con el 7 de oros.
          expect(
            legales(mano: '2o 10o 1e', salida: 0, enMesa: '12c 7o'),
            cs('10o'),
          );
        },
      );

      test('si no se puede matar el triunfo del rival, cualquier carta', () {
        expect(
          legales(mano: '2o 4o 1e', salida: 0, enMesa: '12c 7o'),
          cs('2o 4o 1e'),
        );
      });

      test('si gana el compañero, cualquier carta', () {
        expect(
          legales(mano: '2o 7o 1e', salida: 0, enMesa: '1c 4c'),
          cs('2o 7o 1e'),
        );
      });

      test('si el compañero ha fallado, cualquier carta', () {
        expect(
          legales(mano: '2o 1e', salida: 1, enMesa: '12c 3o 1c'),
          cs('2o 1e'),
        );
      });

      test('sin palo ni triunfo, cualquier carta', () {
        expect(legales(mano: '1e 4b', salida: 1, enMesa: '12c'), cs('1e 4b'));
      });
    });
  });
}
