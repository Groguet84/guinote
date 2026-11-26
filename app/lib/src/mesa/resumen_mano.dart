import 'package:flutter/material.dart';
import 'package:guinote_core/guinote_core.dart';

import 'marcador.dart';

/// Recuento al acabar una mano y, si la hay, la pareja ganadora.
class ResumenMano extends StatelessWidget {
  const ResumenMano({
    super.key,
    required this.resultado,
    required this.partida,
    required this.onSiguienteMano,
    required this.onNuevaPartida,
  });

  final ResultadoMano resultado;
  final Partida partida;
  final VoidCallback onSiguienteMano;
  final VoidCallback onNuevaPartida;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final ganador = partida.ganador;
    final titulo = switch (ganador) {
      null => 'Fin de la mano',
      0 => '¡Habéis ganado la partida!',
      _ => 'Han ganado los rivales',
    };

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
              const SizedBox(height: 20),
              if (ganador == null)
                FilledButton(
                  onPressed: onSiguienteMano,
                  child: const Text('Siguiente mano (de vueltas)'),
                )
              else
                FilledButton(
                  onPressed: onNuevaPartida,
                  child: const Text('Nueva partida'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
