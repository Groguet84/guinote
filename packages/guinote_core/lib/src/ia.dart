import 'carta.dart';
import 'estado_mano.dart';
import 'reglas.dart';
import 'vista_jugador.dart';

/// IA heurística para los jugadores del ordenador.
///
/// Sencilla pero razonable: carga puntos cuando la baza es de su pareja, mata
/// con la carta más barata que gane, no gasta triunfos en bazas pobres,
/// guarda las parejas de rey y caballo para cantar y, en el arrastre, lleva
/// la cuenta de las cartas que han salido. Solo usa la [VistaJugador], así
/// que no ve las cartas de los demás.
final class Ia {
  const Ia();

  /// Puntos en la mesa a partir de los cuales merece la pena fallar con un
  /// triunfo con puntos, o matar sin ser el último en echar carta.
  static const int bazaRica = 10;

  /// Cambia el 7 si la carta destapada es mejor que el 7.
  bool quiereCambiarSiete(VistaJugador v) =>
      v.puedeCambiarSiete && v.cartaTriunfo!.valor.fuerza > Valor.siete.fuerza;

  /// Siempre canta todo lo que puede.
  List<Palo> cantes(VistaJugador v) => v.cantesPosibles;

  /// Aplica sobre [estado] el cambio del 7 y los cantes que quiera hacer
  /// [jugador]. Primero cambia el 7: la carta que recoge puede dar las 40.
  EstadoMano anunciar(EstadoMano estado, int jugador) {
    var e = estado;
    if (quiereCambiarSiete(VistaJugador.de(e, jugador))) {
      e = e.cambiarSiete(jugador);
    }
    for (final palo in cantes(VistaJugador.de(e, jugador))) {
      e = e.cantar(jugador, palo);
    }
    return e;
  }

  /// Elige la carta que echa. Siempre es una de [VistaJugador.legales].
  Carta elegirCarta(VistaJugador v) {
    final legales = v.legales;
    if (legales.isEmpty) {
      throw StateError('El jugador ${v.jugador} no puede echar carta.');
    }
    if (legales.length == 1) return legales.single;
    return v.baza.isEmpty ? _salir(v) : _responder(v);
  }

  Carta _salir(VistaJugador v) {
    if (v.esArrastre) {
      // Con el triunfo más alto se arrastran los triunfos de los rivales; sin
      // triunfos fuera, la más alta de un palo gana seguro.
      final seguras = v.legales.where((c) => _ganaSeguro(c, v));
      if (seguras.isNotEmpty) return _maxPor(seguras, (c) => c.puntos);
    }
    return _descarte(v.legales, v);
  }

  Carta _responder(VistaJugador v) {
    final ganadora = jugadaGanadora(v.baza, v.triunfo);
    final ultimo = v.faltanPorJugar == 0;

    if (sonCompaneros(ganadora.jugador, v.jugador)) {
      final segura = ultimo || _ganaSeguro(ganadora.carta, v);
      return segura ? _cargar(v.legales, v) : _descarte(v.legales, v);
    }

    final matan = v.legales
        .where((c) => mata(c, ganadora.carta, v.triunfo))
        .toList();
    if (matan.isEmpty) return _descarte(v.legales, v);

    final barata = _minPor(matan, (c) => _coste(c, v));
    final puntosMesa = v.baza.fold(0, (s, j) => s + j.carta.puntos);
    final conTriunfo =
        barata.palo == v.triunfo && ganadora.carta.palo != v.triunfo;

    final merece = conTriunfo
        ? puntosMesa >= bazaRica || (barata.puntos == 0 && puntosMesa > 0)
        : ultimo ||
              _ganaSeguro(barata, v) ||
              puntosMesa + barata.puntos >= bazaRica;
    return merece ? barata : _descarte(v.legales, v);
  }

  /// Echa la carta con más puntos que no sea triunfo ni parte de un cante.
  Carta _cargar(List<Carta> legales, VistaJugador v) {
    final candidatas = legales
        .where((c) => c.palo != v.triunfo && !_guardaParaCantar(c, v))
        .toList();
    if (candidatas.isEmpty) return _descarte(legales, v);
    return _maxPor(candidatas, (c) => c.puntos * 100 - c.valor.fuerza);
  }

  /// Echa la carta que menos se pierde.
  Carta _descarte(List<Carta> legales, VistaJugador v) =>
      _minPor(legales, (c) => _coste(c, v));

  /// Lo que cuesta desprenderse de una carta: puntos, fuerza, si es triunfo
  /// y si hace falta para un cante.
  int _coste(Carta c, VistaJugador v) =>
      (c.palo == v.triunfo ? 100 : 0) +
      (_guardaParaCantar(c, v) ? 50 : 0) +
      c.puntos * 3 +
      c.valor.fuerza;

  /// Rey o caballo de un palo sin cantar cuando se tienen los dos.
  bool _guardaParaCantar(Carta c, VistaJugador v) {
    if (c.valor != Valor.rey && c.valor != Valor.caballo) return false;
    if (v.palosCantados.contains(c.palo)) return false;
    final pareja = c.valor == Valor.rey ? Valor.caballo : Valor.rey;
    return v.mano.contains(Carta(pareja, c.palo));
  }

  /// Ninguna carta por ver la supera: ni una más alta del palo ni, si no es
  /// triunfo, un triunfo con el que fallarla.
  bool _ganaSeguro(Carta carta, VistaJugador v) => !v.noVistas.any(
    (c) => c.palo == carta.palo ? c.superaEnPalo(carta) : c.palo == v.triunfo,
  );

  static Carta _minPor(List<Carta> cartas, int Function(Carta) clave) =>
      cartas.reduce((a, b) => clave(b) < clave(a) ? b : a);

  static Carta _maxPor(Iterable<Carta> cartas, int Function(Carta) clave) =>
      cartas.reduce((a, b) => clave(b) > clave(a) ? b : a);
}
