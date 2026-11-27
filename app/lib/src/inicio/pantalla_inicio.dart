import 'dart:math';

import 'package:flutter/material.dart';

import '../juego/jugadores.dart';
import '../mesa/avatar.dart';
import '../mesa/pantalla_mesa.dart';

/// Primera pantalla: eliges tu nombre (y tu avatar, si no te gusta el que
/// ha salido) y te sientas a la mesa.
class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key, this.random});

  /// Azar de los avatares; los tests lo pasan con semilla.
  final Random? random;

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  late final Random _random = widget.random ?? Random();
  late Avatar _avatar = Avatar.aleatorio(_random);
  final _nombre = TextEditingController();

  static const int largoMaximo = 14;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _jugar() {
    final escrito = _nombre.text.trim();
    final tu = Jugador(escrito.isEmpty ? nombrePorDefecto : escrito, _avatar);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            PantallaMesa(jugadores: sortearJugadores(_random, tu: tu)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: tapete,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Guiñote', style: tema.textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Juegas con tu compañero contra dos rivales.',
                          textAlign: TextAlign.center,
                          style: tema.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        AvatarJugador(avatar: _avatar, tamano: 96),
                        TextButton.icon(
                          onPressed: () => setState(
                            () => _avatar = Avatar.aleatorio(_random),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Otro avatar'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nombre,
                          autofocus: true,
                          maxLength: largoMaximo,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.go,
                          onSubmitted: (_) => _jugar(),
                          decoration: const InputDecoration(
                            labelText: '¿Cómo te llamas?',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _jugar,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Sentarse a la mesa'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
