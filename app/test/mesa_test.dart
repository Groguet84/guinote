import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guinote/main.dart';
import 'package:guinote/src/inicio/pantalla_inicio.dart';
import 'package:guinote/src/juego/controlador_partida.dart';
import 'package:guinote/src/mesa/avatar.dart';
import 'package:guinote/src/mesa/manos.dart';
import 'package:guinote/src/mesa/monton_bazas.dart';
import 'package:guinote/src/mesa/pantalla_mesa.dart';
import 'package:guinote_core/guinote_core.dart';

Future<ControladorPartida> montar(
  WidgetTester tester, {
  int semilla = 4,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final c = ControladorPartida(random: Random(semilla));
  await tester.pumpWidget(GuinoteApp(inicio: PantallaMesa(controlador: c)));
  return c;
}

/// Desmonta la mesa y libera el controlador, que tiene temporizadores.
Future<void> cerrar(WidgetTester tester, ControladorPartida c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  testWidgets('la mesa muestra a los cuatro jugadores, el mazo y el triunfo', (
    tester,
  ) async {
    final c = await montar(tester);
    for (var j = 1; j < numJugadores; j++) {
      expect(find.text(c.nombre(j)), findsOneWidget);
    }
    expect(find.textContaining(c.nombre(0)), findsOneWidget);
    expect(find.byType(AvatarJugador), findsNWidgets(numJugadores));
    expect(find.byKey(const ValueKey('carta-triunfo')), findsOneWidget);
    expect(find.byKey(const ValueKey('cartas-mazo')), findsOneWidget);
    expect(find.text('Triunfo: ${c.mano.triunfo.nombre}'), findsOneWidget);
    expect(find.textContaining('Nosotros'), findsWidgets);
    expect(find.byKey(claveMonton(0)), findsOneWidget);
    expect(find.byKey(claveMonton(1)), findsOneWidget);
    await cerrar(tester, c);
  });

  testWidgets('al tocar una carta jugable se echa a la mesa', (tester) async {
    final c = await montar(tester);
    while (!c.turnoHumano) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('${c.nombre(0)} · te toca'), findsOneWidget);
    final carta = c.jugablesHumano.first;
    await tester.tap(find.byKey(claveCartaMano(carta)));
    await tester.pump();
    expect(c.mano.baza.map((j) => j.carta), contains(carta));
    expect(find.byKey(claveCartaMano(carta)), findsNothing);
    await cerrar(tester, c);
  });

  testWidgets('al acabar la mano se ve el resumen', (tester) async {
    final c = await montar(tester, semilla: 2);
    while (c.resultado == null) {
      if (c.turnoHumano) c.jugar(c.jugablesHumano.first);
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pump();
    expect(find.text('Diez de últimas'), findsOneWidget);
    expect(find.text('Total de la mano'), findsOneWidget);
    final boton = c.partida.terminada
        ? find.text('Siguiente partida')
        : find.text('Siguiente mano (de vueltas)');
    await tester.tap(boton);
    await tester.pump();
    expect(c.resultado, isNull);
    expect(find.text('Diez de últimas'), findsNothing);
    await cerrar(tester, c);
  });

  testWidgets('arrastrando una carta se cambia de sitio en la mano', (
    tester,
  ) async {
    final c = await montar(tester);
    final primera = c.manoHumano.first;
    final ancho = tester.getSize(find.byKey(claveCartaMano(primera))).width;
    await tester.drag(
      find.byKey(claveCartaMano(primera)),
      Offset(ancho * 2.2, 0),
    );
    await tester.pump();
    expect(c.manoHumano.indexOf(primera), 2);
    expect(
      c.mano.baza.where((j) => j.carta == primera),
      isEmpty,
      reason: 'arrastrar no la echa',
    );
    await cerrar(tester, c);
  });

  testWidgets('el marcador muestra el coto al mejor de tres', (tester) async {
    final c = await montar(tester);
    expect(find.text('Coto (al mejor de 3): 0 - 0'), findsOneWidget);
    await cerrar(tester, c);
  });

  testWidgets('el menú muestra los créditos de las cartas', (tester) async {
    final c = await montar(tester);
    await tester.tap(find.byTooltip('Menú'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.text('Créditos'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.textContaining('Basquetteur'), findsOneWidget);
    expect(find.textContaining('CC BY-SA 3.0'), findsOneWidget);
    await cerrar(tester, c);
  });

  testWidgets('al empezar eliges tu nombre y te sientas a la mesa', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GuinoteApp(inicio: PantallaInicio(random: Random(1))),
    );
    expect(find.text('¿Cómo te llamas?'), findsOneWidget);
    await tester.tap(find.text('Otro avatar'));
    await tester.enterText(find.byType(TextField), '  Marta ');
    await tester.tap(find.text('Sentarse a la mesa'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byType(PantallaMesa), findsOneWidget);
    expect(find.textContaining('Marta'), findsOneWidget);
    // Al desmontar la mesa se liberan su controlador y sus temporizadores.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sin nombre te llamas «Tú»', (tester) async {
    await tester.pumpWidget(
      GuinoteApp(inicio: PantallaInicio(random: Random(1))),
    );
    await tester.tap(find.text('Sentarse a la mesa'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.textContaining('Tú'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
