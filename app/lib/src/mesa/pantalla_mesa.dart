import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guinote_core/guinote_core.dart';

import '../cartas/carta_widget.dart';
import '../cartas/pintor_carta.dart';
import '../juego/controlador_partida.dart';
import '../juego/jugadores.dart';
import 'avatar.dart';
import 'centro_mesa.dart';
import 'manos.dart';
import 'marcador.dart';
import 'monton_bazas.dart';
import 'resumen_mano.dart';

/// Fondo verde de la mesa, también en la pantalla de inicio.
const BoxDecoration tapete = BoxDecoration(
  gradient: RadialGradient(
    radius: 1.2,
    colors: [Color(0xFF2E7D45), Color(0xFF14522A), Color(0xFF0B3319)],
  ),
);

/// La mesa de juego: tú abajo, tu compañero arriba y los rivales a los lados.
class PantallaMesa extends StatefulWidget {
  const PantallaMesa({super.key, this.controlador, this.jugadores});

  /// Si no se da, la pantalla crea uno con una partida nueva entre
  /// [jugadores].
  final ControladorPartida? controlador;
  final List<Jugador>? jugadores;

  @override
  State<PantallaMesa> createState() => _PantallaMesaState();
}

class _PantallaMesaState extends State<PantallaMesa> {
  late final ControladorPartida _c =
      widget.controlador ?? ControladorPartida(jugadores: widget.jugadores);
  bool _cartasPrecargadas = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_cartasPrecargadas) {
      _cartasPrecargadas = true;
      precargarCartas(context);
    }
  }

  @override
  void dispose() {
    if (widget.controlador == null) _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: tapete,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _c,
            builder: (context, _) => LayoutBuilder(
              builder: (context, restricciones) => _mesa(restricciones.biggest),
            ),
          ),
        ),
      ),
    );
  }

  /// La mesa no pasa de este ancho respecto al alto: en ventanas muy anchas
  /// los jugadores quedan agrupados alrededor del centro y sobra fondo a los
  /// lados.
  static const double _proporcionMaxima = 1.5;

  Widget _mesa(Size ventana) {
    final tamano = Size(
      math.min(ventana.width, ventana.height * _proporcionMaxima),
      ventana.height,
    );
    final mano = _c.mano;
    final base = (tamano.shortestSide / 7.2).clamp(40.0, 120.0);
    final anchoHumano = [
      base * 1.3,
      (tamano.width - 24) / 6.4,
      tamano.height * 0.13,
    ].reduce(math.min);
    final anchoOculta = base * 0.62;
    final resultado = _c.resultado;

    final tamanoAvatar = (base * 0.5).clamp(28.0, 56.0);
    Widget etiqueta(int jugador, {bool vertical = false}) => _EtiquetaJugador(
      jugador: _c.jugadores[jugador],
      tamanoAvatar: tamanoAvatar,
      vertical: vertical,
      activo: mano.fase == Fase.jugando && mano.turno == jugador,
    );

    // Los montones, con cartas del tamaño de las manos ocultas, ocupan un
    // cuadrado en el que caben girados.
    final ladoMonton = MontonBazas.ladoPara(anchoOculta);
    final anchoLateral = [
      anchoOculta / proporcionCarta,
      72.0,
      ladoMonton,
    ].reduce(math.max);

    // Montón de bazas de una pareja; cabe girado en la columna lateral.
    Widget monton(int pareja) => MontonBazas(
      key: claveMonton(pareja),
      nombre: nombresParejas[pareja],
      bazas: _c.bazasEnMonton(pareja),
      marcas: _c.marcasDeVeinte(pareja),
      ancho: anchoOculta,
    );

    Widget rival(int jugador, {Widget? arriba, Widget? abajo}) => SizedBox(
      width: anchoLateral,
      child: Column(
        children: [
          ?arriba,
          // Si no cabe junto al montón, la mano del rival encoge.
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    etiqueta(jugador, vertical: true),
                    const SizedBox(height: 4),
                    ManoOculta(
                      numero: mano.manos[jugador].length,
                      ancho: anchoOculta,
                      vertical: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          ?abajo,
        ],
      ),
    );

    final mesa = Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Marcador y compañero, centrado respecto a la mesa.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Marcador(
                      coto: _c.coto,
                      puntos: _c.puntosMarcador,
                      triunfo: mano.triunfo,
                      onNuevoCoto: _c.nuevoCoto,
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  ManoOculta(numero: mano.manos[2].length, ancho: anchoOculta),
                  const SizedBox(height: 4),
                  etiqueta(2),
                ],
              ),
              const Spacer(),
            ],
          ),
          // Rivales a los lados y la baza en el centro.
          Expanded(
            child: Row(
              children: [
                rival(3, abajo: monton(0)),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, hueco) {
                      // El mazo va junto a la baza: a su izquierda si la mesa
                      // es apaisada y encima si es alargada (móvil).
                      final apaisada = hueco.maxWidth > hueco.maxHeight * 1.2;
                      final hayMazo = mano.cartasPorRobar > 0;
                      final anchoMazo = base * 0.8;
                      final mazo = MazoYTriunfo(
                        cartaTriunfo: mano.cartaTriunfo,
                        cartasMazo: mano.mazo.length,
                        ancho: anchoMazo,
                      );
                      const separacion = 16.0;
                      final libreAncho = hayMazo && apaisada
                          ? hueco.maxWidth - mazo.tamano.width - separacion
                          : hueco.maxWidth;
                      final libreAlto = hayMazo && !apaisada
                          ? hueco.maxHeight - mazo.tamano.height - separacion
                          : hueco.maxHeight;
                      final ancho = [
                        libreAncho / CentroMesa.anchosOcupados,
                        libreAlto * proporcionCarta / CentroMesa.altosOcupados,
                        base * 1.1,
                      ].reduce(math.min);
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Flex(
                            direction: apaisada
                                ? Axis.horizontal
                                : Axis.vertical,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hayMazo) ...[
                                mazo,
                                const SizedBox.square(dimension: separacion),
                              ],
                              CentroMesa(
                                baza: mano.baza,
                                ancho: ancho,
                                ganador: mano.fase == Fase.jugando
                                    ? null
                                    : mano.ultimoGanador,
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: _Aviso(texto: _c.aviso),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                rival(1, arriba: monton(1)),
              ],
            ),
          ),
          // Tú.
          _Acciones(controlador: _c),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EtiquetaJugador(
                jugador: _c.jugadores[ControladorPartida.humano],
                tamanoAvatar: tamanoAvatar,
                texto: _c.turnoHumano
                    ? '${_c.nombre(ControladorPartida.humano)} · te toca'
                    : null,
                activo: _c.turnoHumano,
              ),
              IconButton(
                tooltip: 'Ordenar por palos',
                visualDensity: VisualDensity.compact,
                color: Colors.white,
                onPressed: _c.ordenarMano,
                icon: const Icon(Icons.sort),
              ),
            ],
          ),
          ManoHumano(
            cartas: _c.manoHumano,
            jugables: _c.jugablesHumano,
            ancho: anchoHumano,
            anchoMaximo: tamano.width - 16,
            onJugar: _c.jugar,
            onReordenar: _c.reordenar,
          ),
        ],
      ),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: SizedBox(width: tamano.width, child: mesa),
          ),
        ),
        if (resultado != null) ...[
          const ModalBarrier(color: Color(0x88000000), dismissible: false),
          Center(
            child: SingleChildScrollView(
              child: ResumenMano(
                resultado: resultado,
                coto: _c.coto,
                onContinuar: _c.continuar,
                onNuevoCoto: _c.nuevoCoto,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Botones para cantar y cambiar el 7; solo aparecen cuando se puede.
class _Acciones extends StatelessWidget {
  const _Acciones({required this.controlador});

  final ControladorPartida controlador;

  @override
  Widget build(BuildContext context) {
    final triunfo = controlador.mano.triunfo;
    final botones = [
      for (final palo in controlador.cantesHumano)
        FilledButton.icon(
          onPressed: () => controlador.cantar(palo),
          icon: Icon(Icons.campaign, color: colorPalo(palo)),
          label: Text(
            palo == triunfo
                ? 'Cantar las 40'
                : 'Cantar las 20 en ${palo.nombre}',
          ),
        ),
      if (controlador.puedeCambiarSieteHumano)
        FilledButton.icon(
          onPressed: controlador.cambiarSiete,
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Cambiar el 7'),
        ),
    ];
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Wrap(spacing: 8, runSpacing: 8, children: botones),
    );
  }
}

/// Avatar y nombre de un jugador; se iluminan cuando le toca.
class _EtiquetaJugador extends StatelessWidget {
  const _EtiquetaJugador({
    required this.jugador,
    required this.tamanoAvatar,
    required this.activo,
    this.texto,
    this.vertical = false,
  });

  final Jugador jugador;
  final double tamanoAvatar;
  final bool activo;

  /// Texto en lugar del nombre («Marta · te toca»).
  final String? texto;

  /// Con el avatar encima del nombre en vez de al lado.
  final bool vertical;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Flex(
      direction: vertical ? Axis.vertical : Axis.horizontal,
      mainAxisSize: MainAxisSize.min,
      children: [
        AvatarJugador(
          avatar: jugador.avatar,
          tamano: tamanoAvatar,
          activo: activo,
        ),
        const SizedBox.square(dimension: 4),
        _nombre(),
      ],
    ),
  );

  Widget _nombre() => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: activo ? const Color(0xFFFFD54F) : const Color(0x88000000),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      texto ?? jugador.nombre,
      textAlign: TextAlign.center,
      softWrap: false,
      style: TextStyle(
        color: activo ? Colors.black : Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});

  final String? texto;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 250),
    child: texto == null
        ? const SizedBox.shrink()
        : Container(
            key: ValueKey(texto),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xDD000000),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              texto!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
  );
}
