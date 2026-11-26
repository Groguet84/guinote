import 'package:guinote_core/guinote_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  const triunfo = Palo.oros;
  int ganador(String codigos) => indiceGanador(cs(codigos), triunfo);

  group('Ganador de la baza', () {
    test('sin triunfo gana la más alta del palo de salida', () {
      expect(ganador('4c 1c 3c 12c'), 1);
      expect(ganador('11c 10c 2c 7c'), 1, reason: 'sota mata caballo');
    });

    test('una carta alta de otro palo no gana', () {
      expect(ganador('2c 1e 1b 4c'), 3);
      expect(ganador('2c 1e 1b 3e'), 0);
    });

    test('un triunfo gana a cualquier carta de otro palo', () {
      expect(ganador('1c 3c 2o 12c'), 2);
    });

    test('con varios triunfos gana el más alto', () {
      expect(ganador('1c 2o 10o 11o'), 2);
      expect(ganador('1c 3o 1o 12o'), 2);
    });

    test('si sale triunfo gana el triunfo más alto', () {
      expect(ganador('4o 1c 7o 3e'), 2);
    });

    test('baza en curso: va ganando la primera si nadie la supera', () {
      expect(jugadaGanadora(baza(2, '12c 11c'), triunfo).jugador, 2);
    });
  });
}
