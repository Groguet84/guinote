import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:guinote_core/guinote_core.dart';

/// Conecta el motor con la pantalla: guarda el coto y la mano en curso,
/// hace jugar a la IA con pausas para que se vea y recoge las bazas solas.
/// También guarda el orden en que el humano tiene colocadas sus cartas.
///
/// El humano es siempre el jugador [humano] (abajo); su compañero es el 2.
class ControladorPartida extends ChangeNotifier {
  /// Empieza un coto nuevo.
  ControladorPartida({
    Random? random,
    this._ia = const Ia(),
    this.retardoIa = const Duration(milliseconds: 900),
    this.retardoRecoger = const Duration(seconds: 3),
    this.esperaAnuncio = const Duration(milliseconds: 2500),
    this.duracionAviso = const Duration(milliseconds: 3500),
  }) : _random = random ?? Random() {
    _coto = Coto.nuevo(_random);
    _repartir();
  }

  /// Continúa desde un coto y una mano dados (para tests).
  @visibleForTesting
  ControladorPartida.desde({
    required this._coto,
    required EstadoMano mano,
    Random? random,
    this._ia = const Ia(),
    this.retardoIa = const Duration(milliseconds: 900),
    this.retardoRecoger = const Duration(seconds: 3),
    this.esperaAnuncio = const Duration(milliseconds: 2500),
    this.duracionAviso = const Duration(milliseconds: 3500),
  }) : _random = random ?? Random() {
    _mano = mano;
    _orden = ordenarPorPalo(mano.manos[humano]);
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
  late Coto _coto;
  late EstadoMano _mano;
  List<Carta> _orden = const [];
  ResultadoMano? _resultado;
  String? _aviso;
  Timer? _timer;
  Timer? _timerAviso;

  Coto get coto => _coto;

  /// La partida en curso del coto.
  Partida get partida => _coto.partida;
  EstadoMano get mano => _mano;

  /// Las cartas del humano en el orden en que las tiene colocadas.
  List<Carta> get manoHumano => _orden;

  /// Recuento de la mano recién terminada; `null` mientras se juega.
  ResultadoMano? get resultado => _resultado;

  /// Último aviso de la mesa («Compañero canta las 40»), si sigue visible.
  String? get aviso => _aviso;

  List<Carta> get jugablesHumano => _mano.jugadasLegalesDe(humano);
  List<Palo> get cantesHumano => _mano.cantesPosibles(humano);
  bool get puedeCambiarSieteHumano => _mano.puedeCambiarSiete(humano);
  bool get turnoHumano => _mano.fase == Fase.jugando && _mano.turno == humano;

  void nuevoCoto() {
    _coto = Coto.nuevo(_random);
    _repartir();
  }

  /// Tras el resumen de una mano: la siguiente mano de vueltas o, si la
  /// partida ha terminado, la siguiente partida del coto.
  void continuar() {
    if (_resultado == null || _coto.terminado) return;
    if (partida.terminada) _coto = _coto.siguientePartida();
    _repartir();
  }

  /// Mueve la carta de la posición [desde] a la posición [hasta].
  void reordenar(int desde, int hasta) {
    if (desde == hasta) return;
    final orden = [..._orden];
    orden.insert(hasta, orden.removeAt(desde));
    _orden = List.unmodifiable(orden);
    notifyListeners();
  }

  /// Coloca las cartas del humano agrupadas por palo, de mayor a menor.
  void ordenarMano() {
    _orden = ordenarPorPalo(_orden);
    notifyListeners();
  }

  /// Cartas agrupadas por palo y, dentro del palo, de mayor a menor.
  static List<Carta> ordenarPorPalo(List<Carta> cartas) {
    final ordenadas = [...cartas]
      ..sort(
        (a, b) => a.palo != b.palo
            ? a.palo.index.compareTo(b.palo.index)
            : b.valor.fuerza.compareTo(a.valor.fuerza),
      );
    return List.unmodifiable(ordenadas);
  }

  void jugar(Carta carta) {
    if (!jugablesHumano.contains(carta)) return;
    _cambiar(_mano.jugar(humano, carta));
  }

  void cantar(Palo palo) {
    if (!cantesHumano.contains(palo)) return;
    _estado = _mano.cantar(humano, palo);
    _avisar(textoCante(humano, _mano.cantes.last));
    notifyListeners();
  }

  void cambiarSiete() {
    if (!puedeCambiarSieteHumano) return;
    final siete = Carta(Valor.siete, _mano.triunfo);
    final recogida = _mano.cartaTriunfo!;
    // La carta recogida ocupa el sitio del 7 en la mano.
    _orden = List.unmodifiable([
      for (final c in _orden) c == siete ? recogida : c,
    ]);
    _estado = _mano.cambiarSiete(humano);
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
    _mano = _coto.repartir(_random);
    _orden = ordenarPorPalo(_mano.manos[humano]);
    final quien = nombres[_mano.repartidor];
    final numero = _coto.partidasGanadas.reduce((a, b) => a + b) + 1;
    _avisar(switch (partida) {
      Partida(deVueltas: true) => 'De vueltas · reparte $quien',
      _ when numero > 1 => 'Partida $numero del coto · reparte $quien',
      _ => 'Reparte $quien',
    });
    notifyListeners();
    _programar();
  }

  /// Cambia la mano y mantiene el orden del humano: las cartas que ya tenía
  /// siguen donde estaban y las robadas se añaden al final.
  set _estado(EstadoMano nueva) {
    _mano = nueva;
    final enMano = nueva.manos[humano];
    final siguen = _orden.where(enMano.contains);
    _orden = List.unmodifiable([
      ...siguen,
      ...enMano.where((c) => !_orden.contains(c)),
    ]);
  }

  void _cambiar(EstadoMano nueva) {
    _estado = nueva;
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
    _estado = _mano.recoger();
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
    _coto = _coto.registrarMano(_resultado!);
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
