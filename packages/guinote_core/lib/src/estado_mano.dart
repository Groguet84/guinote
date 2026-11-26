import 'dart:math';

import 'carta.dart';
import 'reglas.dart';

/// Cartas que se reparten a cada jugador.
const int cartasPorJugador = 6;

/// Puntos extra de la última baza («las diez de últimas»).
const int puntosUltimaBaza = 10;

/// Se lanza al intentar una acción que las reglas no permiten.
final class AccionInvalida implements Exception {
  const AccionInvalida(this.mensaje);

  final String mensaje;

  @override
  String toString() => 'AccionInvalida: $mensaje';
}

/// Momento de la mano.
enum Fase {
  /// Se están echando cartas.
  jugando,

  /// Las cuatro cartas siguen en la mesa; falta recogerlas y robar.
  bazaCompleta,

  /// Se ha jugado la última baza.
  terminada,
}

/// Un cante de rey y caballo del mismo palo.
final class Cante {
  const Cante({
    required this.jugador,
    required this.palo,
    required this.puntos,
  });

  /// Puntos del cante: 40 si el palo es de triunfo, 20 si no.
  static int puntosDe(Palo palo, Palo triunfo) => palo == triunfo ? 40 : 20;

  final int jugador;
  final Palo palo;
  final int puntos;

  @override
  bool operator ==(Object other) =>
      other is Cante &&
      other.jugador == jugador &&
      other.palo == palo &&
      other.puntos == puntos;

  @override
  int get hashCode => Object.hash(jugador, palo, puntos);

  @override
  String toString() => 'Jugador $jugador canta $puntos en ${palo.nombre}';
}

/// Una baza ya jugada.
final class Baza {
  Baza({required List<Jugada> jugadas, required this.ganador})
    : jugadas = List.unmodifiable(jugadas);

  final List<Jugada> jugadas;
  final int ganador;

  int get puntos => jugadas.fold(0, (s, j) => s + j.carta.puntos);
}

/// Recuento de una mano terminada, por pareja (índices 0 y 1).
final class ResultadoMano {
  ResultadoMano({
    required List<int> puntosBazas,
    required List<int> puntosCantes,
    required this.parejaUltimaBaza,
  }) : puntosBazas = List.unmodifiable(puntosBazas),
       puntosCantes = List.unmodifiable(puntosCantes);

  final List<int> puntosBazas;
  final List<int> puntosCantes;
  final int parejaUltimaBaza;

  /// Bazas + cantes + 10 de últimas.
  int totalDe(int pareja) =>
      puntosBazas[pareja] +
      puntosCantes[pareja] +
      (pareja == parejaUltimaBaza ? puntosUltimaBaza : 0);
}

/// Estado inmutable de una mano de guiñote.
///
/// Cada acción devuelve un estado nuevo o lanza [AccionInvalida].
final class EstadoMano {
  EstadoMano({
    required this.repartidor,
    required this.triunfo,
    required this.cartaTriunfo,
    required List<Carta> mazo,
    required List<List<Carta>> manos,
    required this.turno,
    List<Jugada> baza = const [],
    List<Baza> bazas = const [],
    List<Cante> cantes = const [],
    this.fase = Fase.jugando,
  }) : mazo = List.unmodifiable(mazo),
       manos = List.unmodifiable([
         for (final m in manos) List<Carta>.unmodifiable(m),
       ]),
       baza = List.unmodifiable(baza),
       bazas = List.unmodifiable(bazas),
       cantes = List.unmodifiable(cantes) {
    if (manos.length != numJugadores) {
      throw ArgumentError('Hacen falta $numJugadores manos.');
    }
  }

  /// Baraja con [random] y reparte: 6 cartas a cada jugador empezando por
  /// la derecha del repartidor, la siguiente es el triunfo y el resto el mazo.
  factory EstadoMano.repartir({
    required int repartidor,
    required Random random,
  }) {
    final cartas = [...Carta.baraja]..shuffle(random);
    final manos = List.generate(numJugadores, (_) => <Carta>[]);
    var siguiente = 0;
    for (var ronda = 0; ronda < cartasPorJugador; ronda++) {
      var jugador = siguienteJugador(repartidor);
      for (var i = 0; i < numJugadores; i++) {
        manos[jugador].add(cartas[siguiente++]);
        jugador = siguienteJugador(jugador);
      }
    }
    final cartaTriunfo = cartas[siguiente++];
    return EstadoMano(
      repartidor: repartidor,
      triunfo: cartaTriunfo.palo,
      cartaTriunfo: cartaTriunfo,
      mazo: cartas.sublist(siguiente),
      manos: manos,
      turno: siguienteJugador(repartidor),
    );
  }

  final int repartidor;

  /// Palo de triunfo de la mano.
  final Palo triunfo;

  /// Carta de triunfo destapada en la mesa; `null` cuando ya se ha robado.
  final Carta? cartaTriunfo;

  /// Mazo boca abajo; se roba desde el principio.
  final List<Carta> mazo;

  /// Mano de cada jugador.
  final List<List<Carta>> manos;

  /// Jugador que debe echar carta (o el ganador, si la baza está completa).
  final int turno;

  /// Cartas en la mesa de la baza actual.
  final List<Jugada> baza;

  /// Bazas ya ganadas, en orden.
  final List<Baza> bazas;

  /// Cantes hechos en esta mano.
  final List<Cante> cantes;

  final Fase fase;

  /// Cartas que quedan por robar, incluido el triunfo destapado.
  int get cartasPorRobar => mazo.length + (cartaTriunfo == null ? 0 : 1);

  /// Sin mazo ni triunfo en la mesa rigen las obligaciones del arrastre.
  bool get esArrastre => cartasPorRobar == 0;

  /// Ganador de la última baza, o `null` si aún no se ha jugado ninguna.
  int? get ultimoGanador => bazas.isEmpty ? null : bazas.last.ganador;

  Set<Palo> get palosCantados => {for (final c in cantes) c.palo};

  /// Cartas que [jugador] puede echar ahora (vacío si no le toca).
  List<Carta> jugadasLegalesDe(int jugador) {
    if (fase != Fase.jugando || turno != jugador) return const [];
    return jugadasLegales(
      mano: manos[jugador],
      baza: baza,
      triunfo: triunfo,
      arrastre: esArrastre,
      jugador: jugador,
    );
  }

  /// Si la pareja de [jugador] puede cantar o cambiar el 7 en este momento:
  /// ganó la última baza y aún no se ha echado carta en la siguiente.
  bool _enVentanaDePareja(int jugador) {
    final ganador = ultimoGanador;
    if (ganador == null || !sonCompaneros(ganador, jugador)) return false;
    return fase == Fase.bazaCompleta || (fase == Fase.jugando && baza.isEmpty);
  }

  /// Palos que [jugador] puede cantar ahora.
  List<Palo> cantesPosibles(int jugador) {
    if (!_enVentanaDePareja(jugador)) return const [];
    final mano = manos[jugador];
    final cantados = palosCantados;
    return [
      for (final palo in Palo.values)
        if (!cantados.contains(palo) &&
            mano.contains(Carta(Valor.rey, palo)) &&
            mano.contains(Carta(Valor.caballo, palo)))
          palo,
    ];
  }

  /// Si [jugador] puede cambiar el 7 de triunfo por la carta destapada.
  bool puedeCambiarSiete(int jugador) =>
      cartaTriunfo != null &&
      _enVentanaDePareja(jugador) &&
      manos[jugador].contains(Carta(Valor.siete, triunfo));

  /// [jugador] echa [carta].
  EstadoMano jugar(int jugador, Carta carta) {
    if (fase != Fase.jugando) {
      throw const AccionInvalida('No se puede echar carta ahora.');
    }
    if (turno != jugador) {
      throw AccionInvalida('No es el turno del jugador $jugador.');
    }
    if (!jugadasLegalesDe(jugador).contains(carta)) {
      throw AccionInvalida('No se puede echar el $carta.');
    }

    final nuevaBaza = [...baza, (jugador: jugador, carta: carta)];
    final nuevasManos = _manosCon(jugador, (m) => m..remove(carta));

    if (nuevaBaza.length < numJugadores) {
      return _copia(
        manos: nuevasManos,
        baza: nuevaBaza,
        turno: siguienteJugador(jugador),
      );
    }

    final ganador = jugadaGanadora(nuevaBaza, triunfo).jugador;
    final ultima = cartasPorRobar == 0 && nuevasManos.every((m) => m.isEmpty);
    return _copia(
      manos: nuevasManos,
      baza: nuevaBaza,
      bazas: [
        ...bazas,
        Baza(jugadas: nuevaBaza, ganador: ganador),
      ],
      turno: ganador,
      fase: ultima ? Fase.terminada : Fase.bazaCompleta,
    );
  }

  /// Recoge la baza completa y, si queda mazo, roba cada jugador una carta
  /// empezando por el ganador. La última carta que se roba es el triunfo.
  EstadoMano recoger() {
    if (fase != Fase.bazaCompleta) {
      throw const AccionInvalida('No hay baza que recoger.');
    }
    final ganador = turno;
    var nuevasManos = manos;
    var nuevoMazo = mazo;
    var nuevaCartaTriunfo = cartaTriunfo;

    if (cartasPorRobar > 0) {
      assert(cartasPorRobar >= numJugadores, 'Robos incompletos');
      final porRobar = [...mazo, ?cartaTriunfo];
      final robadas = <List<Carta>>[
        for (final m in manos) [...m],
      ];
      var jugador = ganador;
      for (var i = 0; i < numJugadores; i++) {
        robadas[jugador].add(porRobar[i]);
        jugador = siguienteJugador(jugador);
      }
      nuevasManos = robadas;
      final delMazo = min(numJugadores, mazo.length);
      nuevoMazo = mazo.sublist(delMazo);
      if (delMazo < numJugadores) nuevaCartaTriunfo = null;
    }

    return _copia(
      manos: nuevasManos,
      mazo: nuevoMazo,
      cartaTriunfo: () => nuevaCartaTriunfo,
      baza: const [],
      fase: Fase.jugando,
    );
  }

  /// [jugador] canta las 20 o las 40 en [palo].
  EstadoMano cantar(int jugador, Palo palo) {
    if (!cantesPosibles(jugador).contains(palo)) {
      throw AccionInvalida(
        'El jugador $jugador no puede cantar en ${palo.nombre}.',
      );
    }
    final cante = Cante(
      jugador: jugador,
      palo: palo,
      puntos: Cante.puntosDe(palo, triunfo),
    );
    return _copia(cantes: [...cantes, cante]);
  }

  /// [jugador] cambia el 7 de triunfo por la carta de triunfo destapada.
  EstadoMano cambiarSiete(int jugador) {
    if (!puedeCambiarSiete(jugador)) {
      throw AccionInvalida('El jugador $jugador no puede cambiar el 7.');
    }
    final siete = Carta(Valor.siete, triunfo);
    final destapada = cartaTriunfo!;
    return _copia(
      manos: _manosCon(jugador, (m) => m..[m.indexOf(siete)] = destapada),
      cartaTriunfo: () => siete,
    );
  }

  /// Recuento de la mano; solo cuando ha terminado.
  ResultadoMano get resultado {
    if (fase != Fase.terminada) {
      throw const AccionInvalida('La mano no ha terminado.');
    }
    final puntosBazas = [0, 0];
    for (final b in bazas) {
      puntosBazas[parejaDe(b.ganador)] += b.puntos;
    }
    final puntosCantes = [0, 0];
    for (final c in cantes) {
      puntosCantes[parejaDe(c.jugador)] += c.puntos;
    }
    return ResultadoMano(
      puntosBazas: puntosBazas,
      puntosCantes: puntosCantes,
      parejaUltimaBaza: parejaDe(bazas.last.ganador),
    );
  }

  List<List<Carta>> _manosCon(
    int jugador,
    List<Carta> Function(List<Carta>) cambio,
  ) => [
    for (var i = 0; i < numJugadores; i++)
      i == jugador ? cambio([...manos[i]]) : manos[i],
  ];

  EstadoMano _copia({
    Carta? Function()? cartaTriunfo,
    List<Carta>? mazo,
    List<List<Carta>>? manos,
    int? turno,
    List<Jugada>? baza,
    List<Baza>? bazas,
    List<Cante>? cantes,
    Fase? fase,
  }) => EstadoMano(
    repartidor: repartidor,
    triunfo: triunfo,
    cartaTriunfo: cartaTriunfo != null ? cartaTriunfo() : this.cartaTriunfo,
    mazo: mazo ?? this.mazo,
    manos: manos ?? this.manos,
    turno: turno ?? this.turno,
    baza: baza ?? this.baza,
    bazas: bazas ?? this.bazas,
    cantes: cantes ?? this.cantes,
    fase: fase ?? this.fase,
  );
}
