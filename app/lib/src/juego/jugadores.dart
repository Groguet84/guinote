import 'dart:math';

import 'package:flutter/painting.dart';

/// Peinados de los avatares.
enum Peinado { corto, largo, rizado, mono, calvo, flequillo }

/// Rasgos de un avatar dibujado por código. Se eligen al azar, pero un mismo
/// [Random] con semilla da siempre el mismo avatar.
class Avatar {
  const Avatar({
    required this.fondo,
    required this.piel,
    required this.pelo,
    required this.ropa,
    required this.peinado,
    required this.gafas,
  });

  factory Avatar.aleatorio(Random random) {
    T uno<T>(List<T> opciones) => opciones[random.nextInt(opciones.length)];
    return Avatar(
      fondo: uno(_fondos),
      piel: uno(_pieles),
      pelo: uno(_pelos),
      ropa: uno(_ropas),
      peinado: uno(Peinado.values),
      gafas: random.nextInt(4) == 0,
    );
  }

  final Color fondo;
  final Color piel;
  final Color pelo;
  final Color ropa;
  final Peinado peinado;
  final bool gafas;

  static const _fondos = [
    Color(0xFF90CAF9),
    Color(0xFFFFCC80),
    Color(0xFFCE93D8),
    Color(0xFFA5D6A7),
    Color(0xFFEF9A9A),
    Color(0xFF80CBC4),
    Color(0xFFFFF59D),
  ];
  static const _pieles = [
    Color(0xFFFFDBC1),
    Color(0xFFF1C27D),
    Color(0xFFE0AC69),
    Color(0xFFC68642),
    Color(0xFF8D5524),
  ];
  static const _pelos = [
    Color(0xFF2B1B0E),
    Color(0xFF5A3825),
    Color(0xFF8B5A2B),
    Color(0xFFD9B26B),
    Color(0xFF9E9E9E),
    Color(0xFFB5442B),
  ];
  static const _ropas = [
    Color(0xFF1565C0),
    Color(0xFFC62828),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFEF6C00),
    Color(0xFF37474F),
  ];
}

/// Un jugador de la mesa: su nombre y su avatar.
class Jugador {
  const Jugador(this.nombre, this.avatar);

  final String nombre;
  final Avatar avatar;
}

/// Nombre que se usa si el humano no escribe ninguno.
const String nombrePorDefecto = 'Tú';

/// Nombres de los que se sortean los jugadores del ordenador.
const List<String> nombresDisponibles = [
  'Pilar',
  'Chusé',
  'Maite',
  'Vicent',
  'Amparo',
  'Mariano',
  'Nieves',
  'Toni',
  'Carmen',
  'Paco',
  'Lola',
  'Javier',
  'Rosa',
  'Andrés',
  'Elena',
  'Joaquín',
  'Inma',
  'Ramón',
  'Teresa',
  'Fermín',
  'Merche',
  'Blas',
  'Consuelo',
  'Jorge',
];

/// Los cuatro jugadores de la mesa, en el orden de los asientos: [tu] en
/// el 0 y tres jugadores del ordenador con nombres distintos (y distintos
/// del tuyo) y avatares al azar.
List<Jugador> sortearJugadores(Random random, {Jugador? tu}) {
  final humano = tu ?? Jugador(nombrePorDefecto, Avatar.aleatorio(random));
  final nombres = [
    for (final n in nombresDisponibles)
      if (n.toLowerCase() != humano.nombre.toLowerCase()) n,
  ]..shuffle(random);
  return List.unmodifiable([
    humano,
    for (final nombre in nombres.take(3))
      Jugador(nombre, Avatar.aleatorio(random)),
  ]);
}
