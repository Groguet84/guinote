import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guinote_core/guinote_core.dart';

import '../cartas/carta_widget.dart';
import '../cartas/pintor_carta.dart';
import '../juego/controlador_partida.dart';
import 'centro_mesa.dart';
import 'manos.dart';
import 'marcador.dart';
import 'resumen_mano.dart';

/// La mesa de juego: tú abajo, tu compañero arriba y los rivales a los lados.
class PantallaMesa extends StatefulWidget {
  const PantallaMesa({super.key, this.controlador});

  /// Si no se da, la pantalla crea uno con una partida nueva.
  final ControladorPartida? controlador;

  @override
  State<PantallaMesa> createState() => _PantallaMesaState();
}

class _PantallaMesaState extends State<PantallaMesa> {
  late final ControladorPartida _c = widget.controlador ?? ControladorPartida();
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
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 1.2,
            colors: [Color(0xFF2E7D45), Color(0xFF14522A), Color(0xFF0B3319)],
          ),
        ),
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

  Widget _mesa(Size tamano) {
    final mano = _c.mano;
    final base = (tamano.shortestSide / 7.2).clamp(40.0, 96.0);
    final anchoHumano = [
      base * 1.3,
      (tamano.width - 24) / 6.4,
      tamano.height * 0.13,
    ].reduce(math.min);
    final anchoOculta = base * 0.62;
    final resultado = _c.resultado;

    Widget etiqueta(int jugador, {bool dosLineas = false}) => _EtiquetaJugador(
      nombre: dosLineas
          ? ControladorPartida.nombres[jugador].replaceFirst(' ', '\n')
          : ControladorPartida.nombres[jugador],
      activo: mano.fase == Fase.jugando && mano.turno == jugador,
    );

    Widget rival(int jugador) => SizedBox(
      width: math.max(anchoOculta / proporcionCarta, 72),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          etiqueta(jugador, dosLineas: true),
          const SizedBox(height: 4),
          ManoOculta(
            numero: mano.manos[jugador].length,
            ancho: anchoOculta,
            vertical: true,
          ),
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
                rival(3),
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
                rival(1),
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
                nombre: _c.turnoHumano ? 'Tú · te toca' : 'Tú',
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
        Positioned.fill(child: mesa),
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

class _EtiquetaJugador extends StatelessWidget {
  const _EtiquetaJugador({required this.nombre, required this.activo});

  final String nombre;
  final bool activo;

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, child: _contenido());

  Widget _contenido() => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: activo ? const Color(0xFFFFD54F) : const Color(0x88000000),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      nombre,
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
