import 'carta.dart';

/// Número de jugadores de la mesa.
const int numJugadores = 4;

/// Puntos para ganar una partida: 50 malas + 51 buenas.
const int puntosParaGanar = 101;

/// Los jugadores se numeran 0-3 en sentido antihorario. Los compañeros
/// se sientan enfrente: la pareja 0 la forman 0 y 2, y la pareja 1, 1 y 3.
int parejaDe(int jugador) => jugador % 2;

/// Siguiente jugador en sentido antihorario.
int siguienteJugador(int jugador) => (jugador + 1) % numJugadores;

/// Si dos jugadores son compañeros (o el mismo jugador).
bool sonCompaneros(int a, int b) => parejaDe(a) == parejaDe(b);

/// Una carta echada en una baza por un jugador.
typedef Jugada = ({int jugador, Carta carta});

/// Si [nueva] supera a [actual], la carta que va ganando la baza.
///
/// Gana la del mismo palo más alta, o cualquier triunfo sobre una carta que
/// no sea de triunfo. Una carta de otro palo que no es triunfo nunca gana.
bool mata(Carta nueva, Carta actual, Palo triunfo) {
  if (nueva.palo == actual.palo) return nueva.superaEnPalo(actual);
  return nueva.palo == triunfo;
}

/// Índice, dentro de [cartas] (en orden de juego), de la carta que gana.
int indiceGanador(List<Carta> cartas, Palo triunfo) {
  if (cartas.isEmpty) throw ArgumentError('Una baza vacía no tiene ganador.');
  var ganador = 0;
  for (var i = 1; i < cartas.length; i++) {
    if (mata(cartas[i], cartas[ganador], triunfo)) ganador = i;
  }
  return ganador;
}

/// La jugada que va ganando una baza (completa o en curso).
Jugada jugadaGanadora(List<Jugada> baza, Palo triunfo) =>
    baza[indiceGanador([for (final j in baza) j.carta], triunfo)];

/// Cartas de [mano] que [jugador] puede echar sobre [baza].
///
/// Mientras quede mazo se puede echar cualquier carta. En el arrastre:
/// 1. Hay que seguir el palo de salida; si gana un rival y se puede, matando.
/// 2. Sin cartas del palo, hay que echar triunfo solo si gana un rival y se
///    tiene un triunfo que lo supere.
/// 3. En cualquier otro caso, cualquier carta.
List<Carta> jugadasLegales({
  required List<Carta> mano,
  required List<Jugada> baza,
  required Palo triunfo,
  required bool arrastre,
  required int jugador,
}) {
  if (!arrastre || baza.isEmpty) return List.unmodifiable(mano);

  final paloSalida = baza.first.carta.palo;
  final ganadora = jugadaGanadora(baza, triunfo);
  final ganaRival = !sonCompaneros(ganadora.jugador, jugador);
  bool superaAGanadora(Carta c) => mata(c, ganadora.carta, triunfo);

  final delPalo = mano.where((c) => c.palo == paloSalida).toList();
  if (delPalo.isNotEmpty) {
    if (ganaRival) {
      final queMatan = delPalo.where(superaAGanadora).toList();
      if (queMatan.isNotEmpty) return List.unmodifiable(queMatan);
    }
    return List.unmodifiable(delPalo);
  }

  if (ganaRival) {
    final triunfosQueMatan = mano
        .where((c) => c.palo == triunfo && superaAGanadora(c))
        .toList();
    if (triunfosQueMatan.isNotEmpty) {
      return List.unmodifiable(triunfosQueMatan);
    }
  }
  return List.unmodifiable(mano);
}
