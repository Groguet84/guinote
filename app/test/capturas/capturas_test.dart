// Genera las capturas del README en docs/capturas/:
//
//   flutter test --dart-define=CAPTURAS=true test/capturas
//
// Usa las fuentes Roboto del SDK de Flutter para que el texto se vea real.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guinote/main.dart';
import 'package:guinote/src/cartas/carta_widget.dart';
import 'package:guinote/src/inicio/pantalla_inicio.dart';
import 'package:guinote/src/juego/controlador_partida.dart';
import 'package:guinote/src/juego/jugadores.dart';
import 'package:guinote/src/mesa/pantalla_mesa.dart';
import 'package:guinote_core/guinote_core.dart';

const bool generar = bool.fromEnvironment('CAPTURAS');
const ia = Ia();

/// Píxeles por punto lógico de las capturas.
const double escala = 1.5;
final salida = Directory('../docs/capturas');

Future<void> cargarFuentes() async {
  final dir =
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
  Future<ByteData> leer(String f) async =>
      ByteData.sublistView(await File('$dir/$f').readAsBytes());
  final roboto = FontLoader('Roboto');
  for (final f in [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]) {
    roboto.addFont(leer(f));
  }
  await roboto.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(leer('MaterialIcons-Regular.otf'))).load();
}

/// Monta la app a [tamano] lógico y la deja avanzar hasta que se cumpla
/// [hasta]. El humano juega con la misma IA que el resto. Con [crear] se
/// parte de un controlador preparado en vez de una partida con [semilla].
Future<ControladorPartida> jugarHasta(
  WidgetTester tester,
  Size tamano,
  int semilla,
  bool Function(ControladorPartida c) hasta, {
  ControladorPartida Function()? crear,
}) async {
  tester.view.devicePixelRatio = escala;
  tester.view.physicalSize = tamano * escala;
  addTearDown(tester.view.reset);
  // Por defecto los tests dibujan las sombras como bloques negros; se
  // restaura en [cerrar], dentro del propio test.
  debugDisableShadows = false;
  final c =
      crear?.call() ??
      ControladorPartida(
        random: Random(semilla),
        jugadores: jugadoresDeCaptura(),
      );
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('captura'),
      child: GuinoteApp(inicio: PantallaMesa(controlador: c)),
    ),
  );
  // Las imágenes de las cartas se cargan fuera del reloj simulado.
  await tester.runAsync(
    () => precargarCartas(tester.element(find.byType(PantallaMesa))),
  );
  for (var i = 0; i < 4000 && !hasta(c); i++) {
    if (c.turnoHumano) {
      c.jugar(
        ia.elegirCarta(VistaJugador.de(c.mano, ControladorPartida.humano)),
      );
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(hasta(c), isTrue, reason: 'no se llegó al momento buscado');
  await tester.pump(const Duration(seconds: 1));
  return c;
}

/// Jugadores fijos para que las capturas siempre salgan iguales.
List<Jugador> jugadoresDeCaptura() => sortearJugadores(
  Random(3),
  tu: Jugador('Marta', Avatar.aleatorio(Random(2))),
);

Future<void> guardar(WidgetTester tester, String nombre) async {
  final limite = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('captura')),
  );
  await tester.runAsync(() async {
    final imagen = await limite.toImage(pixelRatio: escala);
    final png = await imagen.toByteData(format: ui.ImageByteFormat.png);
    salida.createSync(recursive: true);
    File('${salida.path}/$nombre.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}

Future<void> cerrar(WidgetTester tester, ControladorPartida c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
  debugDisableShadows = true;
}

/// Turno del humano con cartas en la mesa, ya avanzada la mano.
bool enJuego(ControladorPartida c, {int bazas = 2}) =>
    c.turnoHumano && c.mano.baza.length >= 2 && c.mano.bazas.length >= bazas;

void main() {
  setUpAll(() async {
    if (generar) await cargarFuentes();
  });

  group('Capturas', skip: !generar, () {
    testWidgets('inicio', (tester) async {
      tester.view.devicePixelRatio = escala;
      tester.view.physicalSize = const Size(1280, 800) * escala;
      addTearDown(tester.view.reset);
      debugDisableShadows = false;
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('captura'),
          child: GuinoteApp(inicio: PantallaInicio(random: Random(2))),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Marta');
      await tester.pump(const Duration(seconds: 1));
      await guardar(tester, 'inicio');
      await tester.pumpWidget(const SizedBox());
      debugDisableShadows = true;
    });

    testWidgets('escritorio', (tester) async {
      final c = await jugarHasta(tester, const Size(1280, 800), 11, enJuego);
      await guardar(tester, 'mesa_escritorio');
      await cerrar(tester, c);
    });

    testWidgets('pantalla grande', (tester) async {
      final c = await jugarHasta(tester, const Size(1920, 970), 11, enJuego);
      await guardar(tester, 'mesa_pantalla_grande');
      await cerrar(tester, c);
    });

    testWidgets('móvil', (tester) async {
      final c = await jugarHasta(tester, const Size(400, 860), 5, enJuego);
      await guardar(tester, 'mesa_movil');
      await cerrar(tester, c);
    });

    testWidgets('arrastre', (tester) async {
      final c = await jugarHasta(
        tester,
        const Size(1280, 800),
        11,
        (c) => c.mano.esArrastre && enJuego(c, bazas: 5),
      );
      await guardar(tester, 'mesa_arrastre');
      await cerrar(tester, c);
    });

    testWidgets('montones de bazas y las 20 marcadas', (tester) async {
      Carta k(Valor v, Palo p) => Carta(v, p);
      final c = await jugarHasta(
        tester,
        const Size(1280, 800),
        0,
        (c) => true,
        crear: () {
          final c = ControladorPartida.desde(
            jugadores: jugadoresDeCaptura(),
            coto: Coto(
              partidasGanadas: const [0, 0],
              partida: Partida(puntos: const [0, 0], repartidor: 3),
            ),
            mano: EstadoMano(
              repartidor: 3,
              triunfo: Palo.oros,
              cartaTriunfo: k(Valor.seis, Palo.oros),
              mazo: [
                k(Valor.dos, Palo.oros),
                k(Valor.cuatro, Palo.oros),
                k(Valor.cinco, Palo.oros),
              ],
              manos: [
                [
                  k(Valor.rey, Palo.copas),
                  k(Valor.sota, Palo.copas),
                  k(Valor.as, Palo.espadas),
                  k(Valor.cuatro, Palo.bastos),
                  k(Valor.siete, Palo.oros),
                  k(Valor.tres, Palo.bastos),
                ],
                for (final palo in [Palo.copas, Palo.espadas, Palo.bastos])
                  [
                    for (final v in [
                      Valor.dos,
                      Valor.cinco,
                      Valor.seis,
                      Valor.siete,
                      Valor.caballo,
                      Valor.cuatro,
                    ])
                      k(v, palo),
                  ],
              ],
              turno: 0,
              bazas: [
                for (final (ganador, palo, valores) in [
                  (0, Palo.oros, [Valor.as, Valor.tres, Valor.rey, Valor.sota]),
                  (
                    1,
                    Palo.espadas,
                    [Valor.tres, Valor.rey, Valor.sota, Valor.caballo],
                  ),
                  (
                    2,
                    Palo.copas,
                    [Valor.as, Valor.tres, Valor.caballo, Valor.siete],
                  ),
                ])
                  Baza(
                    jugadas: [
                      for (var i = 0; i < 4; i++)
                        (
                          jugador: (ganador + i) % 4,
                          carta: k(valores[i], palo),
                        ),
                    ],
                    ganador: ganador,
                  ),
              ],
            ),
          );
          return c;
        },
      );
      c.cantar(Palo.copas);
      // Un fotograma para que arranque la animación del aviso y otro para
      // que termine.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await guardar(tester, 'mesa_montones');
      await cerrar(tester, c);
    });

    testWidgets('resumen de la mano', (tester) async {
      final c = await jugarHasta(
        tester,
        const Size(1280, 800),
        11,
        (c) => c.resultado != null,
      );
      await guardar(tester, 'resumen_mano');
      await cerrar(tester, c);
    });
  });
}
