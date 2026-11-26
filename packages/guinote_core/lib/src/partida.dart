import 'dart:math';

import 'estado_mano.dart';
import 'reglas.dart';

/// Marcador de una partida a [puntosParaGanar] puntos (50 malas + 51 buenas).
///
/// Inmutable: [registrarMano] devuelve la partida actualizada.
final class Partida {
  Partida({
    required List<int> puntos,
    required this.repartidor,
    this.manosJugadas = 0,
    this.ganador,
  }) : puntos = List.unmodifiable(puntos);

  /// Partida a cero con el primer repartidor elegido al azar.
  factory Partida.nueva(Random random) =>
      Partida(puntos: const [0, 0], repartidor: random.nextInt(numJugadores));

  /// Puntos que son «malas».
  static const int malas = 50;

  /// Puntos acumulados de cada pareja.
  final List<int> puntos;

  /// Quien reparte la próxima mano.
  final int repartidor;

  final int manosJugadas;

  /// Pareja ganadora, o `null` si la partida sigue.
  final int? ganador;

  bool get terminada => ganador != null;

  /// La próxima mano es «de vueltas»: ya se ha jugado al menos una y
  /// nadie ha ganado.
  bool get deVueltas => manosJugadas > 0 && !terminada;

  static int malasDe(int puntos) => min(puntos, malas);

  static int buenasDe(int puntos) => max(0, puntos - malas);

  /// Reparte la siguiente mano.
  EstadoMano repartir(Random random) {
    if (terminada) throw const AccionInvalida('La partida ha terminado.');
    return EstadoMano.repartir(
      repartidor: repartidor,
      random: random,
      puntosPartida: deVueltas ? puntos : null,
    );
  }

  /// Suma el [resultado] de una mano y decide si hay ganador. Si las dos
  /// parejas llegan a 101 en la misma mano, gana la de la última baza. (De
  /// vueltas no puede pasar: la mano se corta en cuanto llega una.)
  Partida registrarMano(ResultadoMano resultado) {
    if (terminada) throw const AccionInvalida('La partida ha terminado.');
    final nuevos = [
      for (var p = 0; p < 2; p++) puntos[p] + resultado.totalDe(p),
    ];
    final llegan = [
      for (var p = 0; p < 2; p++)
        if (nuevos[p] >= puntosParaGanar) p,
    ];
    return Partida(
      puntos: nuevos,
      repartidor: siguienteJugador(repartidor),
      manosJugadas: manosJugadas + 1,
      ganador: switch (llegan) {
        [] => null,
        [final unica] => unica,
        _ => resultado.parejaUltimaBaza ?? (nuevos[0] >= nuevos[1] ? 0 : 1),
      },
    );
  }
}
