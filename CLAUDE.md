# Guiñote — contexto del proyecto

Juego de guiñote (variante aragonesa y valenciana) en Flutter para web y Android. Es un proyecto de portfolio: lo leerán reclutadores, así que el código, los tests y el README tienen que estar cuidados.

## Reglas
- **`REGLAS.md` es la especificación y manda sobre cualquier otra variante del guiñote.** No inventes reglas: si algo no está claro, pregunta.
- Puntos frecuentes de error:
  - la sota (3 puntos) es más alta que el caballo (2);
  - se canta **rey + caballo**;
  - en el arrastre solo hay obligación de matar o de fallar con triunfo si la baza la va ganando un rival.

## Estructura
```
packages/guinote_core/   Dart puro: modelo, reglas, estado de la mano, puntuación, IA
app/                     Flutter (web + Android). Solo interfaz y estado de pantalla
```
- `guinote_core` no puede depender de Flutter. Toda regla vive ahí, con tests.
- La interfaz y la IA usan la misma función de jugadas legales del motor. La interfaz nunca valida reglas por su cuenta.
- Estado de juego inmutable, con acciones que devuelven un estado nuevo. El azar se inyecta con `Random` con semilla para poder repetir partidas en los tests.
- Cartas dibujadas por código (`CustomPainter`), sin imágenes de terceros.

## Decisiones de interfaz
- La baza completa se ve en la mesa 3 segundos y se recoge sola (el controlador llama a `recoger()`). No hay botón de recoger.
- Durante esos 3 segundos ya se puede cantar y cambiar el 7. Si después de robar el humano tiene un cante o el 7 disponible, la IA espera un momento antes de salir. La IA nunca canta por el humano.

## Convenciones
- Dominio en español (`Carta`, `Palo`, `Baza`, `cantar`, `arrastre`); textos de la interfaz en español.
- Lints estrictos (`analysis_options.yaml` de cada paquete). Sin avisos de `dart analyze`.
- Sin dependencias nuevas salvo necesidad clara.

## Comandos
```bash
# Motor
cd packages/guinote_core && dart pub get && dart analyze && dart test
# App
cd app && flutter pub get && flutter analyze && flutter test
flutter run -d chrome          # web
flutter build apk              # Android
```

## Fases
0. Esqueleto: repo, estructura, lints, CI ✓
1. Motor de reglas y tests ✓
2. IA de los tres jugadores del ordenador
3. Interfaz de mesa
4. Pulido: README con capturas, despliegue web, APK

Se trabaja fase a fase y se espera la aprobación del usuario antes de empezar la siguiente.
