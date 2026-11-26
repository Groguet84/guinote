import 'dart:math';

import 'estado_mano.dart';
import 'partida.dart';

/// Un coto: se juega al mejor de tres partidas. Gana la pareja que gana
/// [partidasParaGanar] partidas.
///
/// Inmutable: cada método devuelve el coto actualizado.
final class Coto {
  Coto({required List<int> partidasGanadas, required this.partida})
    : partidasGanadas = List.unmodifiable(partidasGanadas);

  /// Coto a cero; el primer repartidor se elige al azar.
  factory Coto.nuevo(Random random) =>
      Coto(partidasGanadas: const [0, 0], partida: Partida.nueva(random));

  static const int partidasParaGanar = 2;

  /// Partidas ganadas por cada pareja.
  final List<int> partidasGanadas;

  /// La partida en curso (o la última, si ha terminado).
  final Partida partida;

  /// Pareja ganadora del coto, o `null` si sigue.
  int? get ganador {
    for (var p = 0; p < 2; p++) {
      if (partidasGanadas[p] >= partidasParaGanar) return p;
    }
    return null;
  }

  bool get terminado => ganador != null;

  /// Reparte la siguiente mano de la partida en curso.
  EstadoMano repartir(Random random) => partida.repartir(random);

  /// Suma una mano a la partida en curso y, si la partida acaba, apunta la
  /// partida a su ganador.
  Coto registrarMano(ResultadoMano resultado) {
    if (terminado) throw const AccionInvalida('El coto ha terminado.');
    final nueva = partida.registrarMano(resultado);
    return Coto(
      partidasGanadas: [
        for (var p = 0; p < 2; p++)
          partidasGanadas[p] + (nueva.ganador == p ? 1 : 0),
      ],
      partida: nueva,
    );
  }

  /// Empieza la siguiente partida, a cero. El reparto sigue rotando.
  Coto siguientePartida() {
    if (!partida.terminada) {
      throw const AccionInvalida('La partida no ha terminado.');
    }
    if (terminado) throw const AccionInvalida('El coto ha terminado.');
    return Coto(
      partidasGanadas: partidasGanadas,
      partida: Partida(puntos: const [0, 0], repartidor: partida.repartidor),
    );
  }
}
