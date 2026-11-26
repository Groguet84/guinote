import 'package:flutter/material.dart';
import 'package:guinote_core/guinote_core.dart';

import 'marcador.dart';

/// Recuento al acabar una mano y, si la hay, la pareja que gana la partida
/// o el coto.
class ResumenMano extends StatelessWidget {
  const ResumenMano({
    super.key,
    required this.resultado,
    required this.coto,
    required this.onContinuar,
    required this.onNuevoCoto,
  });

  final ResultadoMano resultado;
  final Coto coto;

  /// Siguiente mano de vueltas o siguiente partida del coto.
  final VoidCallback onContinuar;
  final VoidCallback onNuevoCoto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final partida = coto.partida;
    final marcadorCoto =
        '${coto.partidasGanadas[0]} - ${coto.partidasGanadas[1]}';
    final titulo = switch ((coto.ganador, partida.ganador)) {
      (0, _) => '¡Habéis ganado el coto! ($marcadorCoto)',
      (1, _) => 'Los rivales ganan el coto ($marcadorCoto)',
      (_, 0) => '¡Ganáis la partida! Coto: $marcadorCoto',
      (_, 1) => 'Los rivales ganan la partida. Coto: $marcadorCoto',
      _ => 'Fin de la mano',
    };
    final (textoBoton, accion) = coto.terminado
        ? ('Nuevo coto', onNuevoCoto)
        : partida.terminada
        ? ('Siguiente partida', onContinuar)
        : ('Siguiente mano (de vueltas)', onContinuar);

    TableRow fila(
      String concepto,
      int Function(int pareja) valor, {
      bool negrita = false,
    }) {
      final estilo = negrita
          ? const TextStyle(fontWeight: FontWeight.w700)
          : null;
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(concepto, style: estilo),
          ),
          for (var p = 0; p < 2; p++)
            Text('${valor(p)}', textAlign: TextAlign.end, style: estilo),
        ],
      );
    }

    return Card(
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titulo,
                style: tema.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {0: FlexColumnWidth(2)},
                children: [
                  TableRow(
                    children: [
                      const SizedBox(),
                      for (final nombre in nombresParejas)
                        Text(
                          nombre,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                  fila('Bazas', (p) => resultado.puntosBazas[p]),
                  fila('Cantes', (p) => resultado.puntosCantes[p]),
                  fila(
                    'Diez de últimas',
                    (p) =>
                        p == resultado.parejaUltimaBaza ? puntosUltimaBaza : 0,
                  ),
                  fila('Total de la mano', resultado.totalDe, negrita: true),
                  fila('Marcador', (p) => partida.puntos[p], negrita: true),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                [
                  for (var p = 0; p < 2; p++)
                    '${nombresParejas[p]}: ${textoMalasBuenas(partida.puntos[p])}',
                ].join(' · '),
                style: tema.bodySmall,
              ),
              if (resultado.cortada) ...[
                const SizedBox(height: 8),
                Text(
                  'Se ha llegado a 51 buenas antes de acabar la mano: '
                  'no se juegan las cartas que quedan ni hay diez de últimas.',
                  style: tema.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(onPressed: accion, child: Text(textoBoton)),
            ],
          ),
        ),
      ),
    );
  }
}
