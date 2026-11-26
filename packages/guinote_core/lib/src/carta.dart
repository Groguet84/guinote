/// Los cuatro palos de la baraja española.
enum Palo {
  oros,
  copas,
  espadas,
  bastos;

  String get nombre => name;
}

/// Valores de la baraja, ordenados de menor a mayor fuerza.
///
/// El orden de declaración es el orden del juego (ver `REGLAS.md`):
/// as > 3 > rey > sota > caballo > 7 > 6 > 5 > 4 > 2.
enum Valor {
  dos(numero: 2, puntos: 0, nombre: '2'),
  cuatro(numero: 4, puntos: 0, nombre: '4'),
  cinco(numero: 5, puntos: 0, nombre: '5'),
  seis(numero: 6, puntos: 0, nombre: '6'),
  siete(numero: 7, puntos: 0, nombre: '7'),
  caballo(numero: 11, puntos: 2, nombre: 'caballo'),
  sota(numero: 10, puntos: 3, nombre: 'sota'),
  rey(numero: 12, puntos: 4, nombre: 'rey'),
  tres(numero: 3, puntos: 10, nombre: '3'),
  as(numero: 1, puntos: 11, nombre: 'as');

  const Valor({
    required this.numero,
    required this.puntos,
    required this.nombre,
  });

  /// Número impreso en la carta (1-7, 10, 11, 12).
  final int numero;

  /// Puntos que vale la carta en el recuento.
  final int puntos;

  /// Nombre en español, en minúsculas.
  final String nombre;

  /// Fuerza relativa dentro del palo: mayor gana.
  int get fuerza => index;

  static Valor deNumero(int numero) =>
      values.firstWhere((v) => v.numero == numero);
}

/// Una carta de la baraja española de 40 cartas.
final class Carta {
  const Carta(this.valor, this.palo);

  final Valor valor;
  final Palo palo;

  int get puntos => valor.puntos;

  /// La baraja completa de 40 cartas, sin barajar.
  static final List<Carta> baraja = List.unmodifiable([
    for (final palo in Palo.values)
      for (final valor in Valor.values) Carta(valor, palo),
  ]);

  /// Si esta carta es más alta que [otra] del mismo palo.
  bool superaEnPalo(Carta otra) =>
      palo == otra.palo && valor.fuerza > otra.valor.fuerza;

  @override
  bool operator ==(Object other) =>
      other is Carta && other.valor == valor && other.palo == palo;

  @override
  int get hashCode => Object.hash(valor, palo);

  /// Por ejemplo, «rey de oros».
  @override
  String toString() => '${valor.nombre} de ${palo.nombre}';
}
