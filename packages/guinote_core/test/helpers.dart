import 'package:guinote_core/guinote_core.dart';

/// Carta a partir de número + inicial del palo: `'1o'` es el as de oros,
/// `'3c'` el 3 de copas, `'11e'` el caballo de espadas y `'12b'` el rey de
/// bastos.
Carta c(String codigo) {
  final palo = switch (codigo[codigo.length - 1]) {
    'o' => Palo.oros,
    'c' => Palo.copas,
    'e' => Palo.espadas,
    'b' => Palo.bastos,
    _ => throw ArgumentError('Palo desconocido en $codigo'),
  };
  final numero = int.parse(codigo.substring(0, codigo.length - 1));
  return Carta(Valor.deNumero(numero), palo);
}

/// Varias cartas separadas por espacios: `cs('1o 3c 12b')`.
List<Carta> cs(String codigos) => codigos.trim().isEmpty
    ? []
    : codigos.trim().split(RegExp(r'\s+')).map(c).toList();

/// Una baza en curso a partir de quién sale y las cartas en orden de juego.
List<Jugada> baza(int salida, String codigos) {
  final cartas = cs(codigos);
  return [
    for (var i = 0; i < cartas.length; i++)
      (jugador: (salida + i) % numJugadores, carta: cartas[i]),
  ];
}
