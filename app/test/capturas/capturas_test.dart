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
import 'package:guinote/src/juego/controlador_partida.dart';
import 'package:guinote/src/mesa/pantalla_mesa.dart';
import 'package:guinote_core/guinote_core.dart';

const bool generar = bool.fromEnvironment('CAPTURAS');
const ia = Ia();
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
/// [hasta]. El humano juega con la misma IA que el resto.
Future<ControladorPartida> jugarHasta(
  WidgetTester tester,
  Size tamano,
  int semilla,
  bool Function(ControladorPartida c) hasta,
) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = tamano * 2;
  addTearDown(tester.view.reset);
  // Por defecto los tests dibujan las sombras como bloques negros; se
  // restaura en [cerrar], dentro del propio test.
  debugDisableShadows = false;
  final c = ControladorPartida(random: Random(semilla));
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('captura'),
      child: GuinoteApp(mesa: PantallaMesa(controlador: c)),
    ),
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

Future<void> guardar(WidgetTester tester, String nombre) async {
  final limite = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('captura')),
  );
  await tester.runAsync(() async {
    final imagen = await limite.toImage(pixelRatio: 2);
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
    testWidgets('escritorio', (tester) async {
      final c = await jugarHasta(tester, const Size(1280, 800), 11, enJuego);
      await guardar(tester, 'mesa_escritorio');
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
