import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:guinote_core/guinote_core.dart';

/// Conecta el motor con la pantalla: guarda la partida y la mano en curso,
/// hace jugar a la IA con pausas para que se vea y recoge las bazas solas.
///
/// El humano es siempre el jugador [humano] (abajo); su compañero es el 2.
class ControladorPartida extends ChangeNotifier {
  /// Empieza una partida nueva.
  ControladorPartida({
    Random? random,
    this._ia = const Ia(),
    this.retardoIa = const Duration(milliseconds: 900),
    this.retardoRecoger = const Duration(seconds: 3),
    this.esperaAnuncio = const Duration(milliseconds: 2500),
    this.duracionAviso = const Duration(milliseconds: 3500),
  }) : _random = random ?? Random() {
    _partida = Partida.nueva(_random);
    _repartir();
  }

  /// Continúa desde una partida y una mano dadas (para tests).
  @visibleForTesting
  ControladorPartida.desde({
    required this._partida,
    required this._mano,
    Random? random,
    this._ia = const Ia(),
    this.retardoIa = const Duration(milliseconds: 900),
    this.retardoRecoger = const Duration(seconds: 3),
    this.esperaAnuncio = const Duration(milliseconds: 2500),
    this.duracionAviso = const Duration(milliseconds: 3500),
  }) : _random = random ?? Random() {
    _programar();
  }

  static const int humano = 0;

  static const List<String> nombres = [
    'Tú',
    'Rival derecho',
    'Compañero',
    'Rival izquierdo',
  ];

  /// Pausa antes de que eche carta un jugador del ordenador.
  final Duration retardoIa;

  /// Tiempo que se ve la baza completa antes de recogerla.
  final Duration retardoRecoger;

  /// Pausa extra antes de salir si el humano puede cantar o cambiar el 7.
  final Duration esperaAnuncio;

  /// Tiempo que se muestra un aviso.
  final Duration duracionAviso;

  final Random _random;
  final Ia _ia;
  late Partida _partida;
  late EstadoMano _mano;
  ResultadoMano? _resultado;
  String? _aviso;
  Timer? _timer;
  Timer? _timerAviso;

  Partida get partida => _partida;
  EstadoMano get mano => _mano;

  /// Recuento de la mano recién terminada; `null` mientras se juega.
  ResultadoMano? get resultado => _resultado;

  /// Último aviso de la mesa («Compañero canta las 40»), si sigue visible.
  String? get aviso => _aviso;

  List<Carta> get jugablesHumano => _mano.jugadasLegalesDe(humano);
  List<Palo> get cantesHumano => _mano.cantesPosibles(humano);
  bool get puedeCambiarSieteHumano => _mano.puedeCambiarSiete(humano);
  bool get turnoHumano => _mano.fase == Fase.jugando && _mano.turno == humano;

  void nuevaPartida() {
    _partida = Partida.nueva(_random);
    _repartir();
  }

  void siguienteMano() {
    if (_resultado == null || _partida.terminada) return;
    _repartir();
  }

  void jugar(Carta carta) {
    if (!jugablesHumano.contains(carta)) return;
    _cambiar(_mano.jugar(humano, carta));
  }

  void cantar(Palo palo) {
    if (!cantesHumano.contains(palo)) return;
    _mano = _mano.cantar(humano, palo);
    _avisar(textoCante(humano, _mano.cantes.last));
    notifyListeners();
  }

  void cambiarSiete() {
    if (!puedeCambiarSieteHumano) return;
    _mano = _mano.cambiarSiete(humano);
    _avisar('Cambias el 7 de ${_mano.triunfo.nombre}');
    notifyListeners();
  }

  static String textoCante(int jugador, Cante cante) {
    final quien = jugador == humano ? 'Cantas' : '${nombres[jugador]} canta';
    return cante.puntos == 40
        ? '$quien las 40'
        : '$quien las 20 en ${cante.palo.nombre}';
  }

  void _repartir() {
    _timer?.cancel();
    _resultado = null;
    _mano = _partida.repartir(_random);
    _avisar(
      _partida.deVueltas
          ? 'De vueltas · reparte ${nombres[_mano.repartidor]}'
          : 'Reparte ${nombres[_mano.repartidor]}',
    );
    notifyListeners();
    _programar();
  }

  void _cambiar(EstadoMano nueva) {
    _mano = nueva;
    notifyListeners();
    _programar();
  }

  /// Programa el siguiente paso automático según la fase de la mano.
  void _programar() {
    _timer?.cancel();
    switch (_mano.fase) {
      case Fase.terminada:
        _avisarGanadorBaza();
        _timer = Timer(retardoRecoger, _terminarMano);
      case Fase.bazaCompleta:
        _avisarGanadorBaza();
        // El 7 se cambia antes de robar: en el último robo es la última ocasión.
        _anunciarIa(soloSiete: true);
        _timer = Timer(retardoRecoger, _recoger);
      case Fase.jugando:
        if (_mano.turno == humano) return;
        final daTiempo =
            _mano.baza.isEmpty &&
            (cantesHumano.isNotEmpty || puedeCambiarSieteHumano);
        _timer = Timer(daTiempo ? esperaAnuncio : retardoIa, _jugarIa);
    }
  }

  void _recoger() {
    _mano = _mano.recoger();
    // Lo habitual es cantar después de robar.
    _anunciarIa();
    notifyListeners();
    _programar();
  }

  void _jugarIa() {
    final jugador = _mano.turno;
    final carta = _ia.elegirCarta(VistaJugador.de(_mano, jugador));
    _cambiar(_mano.jugar(jugador, carta));
  }

  void _terminarMano() {
    _resultado = _mano.resultado;
    _partida = _partida.registrarMano(_resultado!);
    notifyListeners();
  }

  /// Los jugadores del ordenador cambian el 7 y cantan si les conviene.
  void _anunciarIa({bool soloSiete = false}) {
    final avisos = <String>[];
    for (var j = 0; j < numJugadores; j++) {
      if (j == humano) continue;
      final antes = _mano;
      if (soloSiete) {
        if (_ia.quiereCambiarSiete(VistaJugador.de(_mano, j))) {
          _mano = _mano.cambiarSiete(j);
        }
      } else {
        _mano = _ia.anunciar(_mano, j);
      }
      if (_mano.cartaTriunfo != antes.cartaTriunfo) {
        avisos.add('${nombres[j]} cambia el 7');
      }
      for (final cante in _mano.cantes.skip(antes.cantes.length)) {
        avisos.add(textoCante(j, cante));
      }
    }
    if (avisos.isNotEmpty) _avisar(avisos.join(' · '));
  }

  void _avisarGanadorBaza() {
    final ganador = _mano.ultimoGanador!;
    _avisar(
      ganador == humano ? 'Ganas la baza' : 'Gana la baza: ${nombres[ganador]}',
    );
  }

  void _avisar(String texto) {
    _aviso = texto;
    _timerAviso?.cancel();
    _timerAviso = Timer(duracionAviso, () {
      _aviso = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerAviso?.cancel();
    super.dispose();
  }
}
