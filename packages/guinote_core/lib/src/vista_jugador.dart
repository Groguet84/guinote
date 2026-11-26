import 'carta.dart';
import 'estado_mano.dart';
import 'reglas.dart';

/// Lo que un jugador sabe de la mano: su propia mano y lo que se ve en la
/// mesa. No incluye las manos de los demás ni el orden del mazo, así que una
/// estrategia que solo use la vista no puede hacer trampas.
final class VistaJugador {
  VistaJugador._({
    required this.jugador,
    required this.mano,
    required this.baza,
    required this.triunfo,
    required this.cartaTriunfo,
    required this.cartasPorRobar,
    required this.legales,
    required this.jugadas,
    required this.palosCantados,
    required this.cantesPosibles,
    required this.puedeCambiarSiete,
  });

  factory VistaJugador.de(EstadoMano estado, int jugador) => VistaJugador._(
    jugador: jugador,
    mano: estado.manos[jugador],
    baza: estado.fase == Fase.jugando ? estado.baza : const [],
    triunfo: estado.triunfo,
    cartaTriunfo: estado.cartaTriunfo,
    cartasPorRobar: estado.cartasPorRobar,
    legales: estado.jugadasLegalesDe(jugador),
    jugadas: Set.unmodifiable({
      for (final b in estado.bazas) ...b.jugadas.map((j) => j.carta),
      ...estado.baza.map((j) => j.carta),
    }),
    palosCantados: Set.unmodifiable(estado.palosCantados),
    cantesPosibles: estado.cantesPosibles(jugador),
    puedeCambiarSiete: estado.puedeCambiarSiete(jugador),
  );

  final int jugador;
  final List<Carta> mano;

  /// Cartas en la mesa de la baza en curso.
  final List<Jugada> baza;
  final Palo triunfo;
  final Carta? cartaTriunfo;
  final int cartasPorRobar;

  /// Cartas que puede echar ahora (vacío si no le toca).
  final List<Carta> legales;

  /// Cartas que ya han salido en esta mano, incluidas las de la mesa.
  final Set<Carta> jugadas;
  final Set<Palo> palosCantados;
  final List<Palo> cantesPosibles;
  final bool puedeCambiarSiete;

  bool get esArrastre => cartasPorRobar == 0;

  /// Cartas cuyo paradero no conoce: en otras manos o en el mazo.
  Set<Carta> get noVistas => {
    for (final c in Carta.baraja)
      if (!mano.contains(c) && !jugadas.contains(c) && c != cartaTriunfo) c,
  };

  /// Jugadores que aún tienen que echar carta en esta baza después de él.
  int get faltanPorJugar => numJugadores - 1 - baza.length;
}
