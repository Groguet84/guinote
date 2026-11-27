# Guiñote — contexto del proyecto

Juego de guiñote (variante aragonesa y valenciana) en Flutter para web y Android. Es un proyecto de portfolio: lo leerán reclutadores, así que el código, los tests y el README tienen que estar cuidados.

## Reglas
- **`REGLAS.md` es la especificación y manda sobre cualquier otra variante del guiñote.** No inventes reglas: si algo no está claro, pregunta.
- Puntos frecuentes de error:
  - la sota (3 puntos) es más alta que el caballo (2);
  - se canta **rey + sota**, nunca con el caballo;
  - en el arrastre solo hay obligación de matar o de fallar con triunfo si la baza la va ganando un rival.

## Estructura
```
packages/guinote_core/   Dart puro: modelo, reglas, estado de la mano, puntuación, IA
app/                     Flutter (web + Android). Solo interfaz y estado de pantalla
```
- `guinote_core` no puede depender de Flutter. Toda regla vive ahí, con tests.
- La interfaz y la IA usan la misma función de jugadas legales del motor. La interfaz nunca valida reglas por su cuenta.
- Estado de juego inmutable, con acciones que devuelven un estado nuevo. El azar se inyecta con `Random` con semilla para poder repetir partidas en los tests.
- Cartas: imágenes de `app/assets/cartas/`, de la baraja «Naipes libres» de Basquetteur (Wikimedia Commons, CC BY-SA 3.0), generadas con `tool/recortar_cartas.sh`. La licencia obliga a mantener la atribución (README, `assets/cartas/LICENCIA.md` y menú «Créditos»). `PintorCarta` dibuja las cartas por código si una imagen no carga.
- No uses cartas ni diseños de otras apps ni de barajas con derechos (por ejemplo, Fournier).

## Decisiones de interfaz
- La baza completa se ve en la mesa 2 segundos y se recoge sola (el controlador llama a `recoger()`) al montón de la pareja ganadora. No hay botón de recoger.
- La mesa no pasa de 1,5 veces el alto de la ventana: en pantallas muy anchas queda centrada, con fondo a los lados, para que los jugadores no se separen. Hay una captura a 1920×970 para comprobarlo.
- Montones de bazas: el de nuestra pareja abajo a la izquierda y el de los rivales arriba a la derecha, boca abajo. Cada cante de 20 se marca con una carta ya jugada del montón puesta boca arriba (nunca el rey ni la sota, que siguen en juego). Las 40 no se marcan.
- Durante esos 2 segundos ya se puede cantar y cambiar el 7. Si después de robar el humano tiene un cante o el 7 disponible, la IA espera un momento antes de salir. La IA nunca canta por el humano.

## Convenciones
- Dominio en español (`Carta`, `Palo`, `Baza`, `cantar`, `arrastre`); textos de la interfaz en español.
- Lints estrictos (`analysis_options.yaml` de cada paquete). Sin avisos de `dart analyze`.
- Sin dependencias nuevas salvo necesidad clara.
- Flutter 3.47.9 / Dart 3.13.7, fijados también en `.github/workflows/`. Al actualizar Flutter, cambia la versión en los dos sitios.

## Comandos
```bash
# Motor
cd packages/guinote_core && dart pub get && dart analyze && dart test
# App
cd app && flutter pub get && flutter analyze && flutter test
flutter run -d chrome          # web
flutter build apk              # Android
# Capturas del README (docs/capturas/), con fuentes reales y tiempo simulado
flutter test --dart-define=CAPTURAS=true test/capturas
```
- Para ver la interfaz, usa las capturas de `test/capturas`, no Chromium en modo headless: su reloj virtual congela las animaciones y su ventana tiene un ancho mínimo de unos 500 px.

## Fases
0. Esqueleto: repo, estructura, lints, CI ✓
1. Motor de reglas y tests ✓
2. IA de los tres jugadores del ordenador ✓
3. Interfaz de mesa ✓
4. Pulido: README con capturas ✓, APK ✓, flujos de despliegue web y release ✓ (pendiente: subir a GitHub y activar Pages)

Se trabaja fase a fase y se espera la aprobación del usuario antes de empezar la siguiente.
