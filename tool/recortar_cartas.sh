#!/usr/bin/env bash
# Genera app/assets/cartas/ a partir de la baraja «Naipes libres» de
# Basquetteur en Wikimedia Commons (CC BY-SA 3.0):
#   https://commons.wikimedia.org/wiki/File:Baraja_espa%C3%B1ola_completa.png
#
# La imagen original es una cuadrícula de 12 columnas (1 a 12) por 5 filas
# (oros, copas, espadas, bastos y, en la última, el dorso en la 2.ª celda).
# Se recorta cada celda y se descartan los ochos y nueves, que el guiñote no
# usa. Requiere curl e ImageMagick 7 (magick).
set -euo pipefail

URL='https://upload.wikimedia.org/wikipedia/commons/e/e0/Baraja_espa%C3%B1ola_completa.png'
DESTINO="$(cd "$(dirname "$0")/.." && pwd)/app/assets/cartas"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp:?}"' EXIT

curl -fsSL -A 'guinote/recortar-cartas' -o "$tmp/baraja.png" "$URL"
magick "$tmp/baraja.png" -crop 12x5@ +repage "$tmp/c_%02d.png"

mkdir -p "$DESTINO"
palos=(oros copas espadas bastos)
for fila in 0 1 2 3; do
  for columna in $(seq 0 11); do
    numero=$((columna + 1))
    if [[ $numero == 8 || $numero == 9 ]]; then continue; fi
    celda=$(printf '%02d' $((fila * 12 + columna)))
    magick "$tmp/c_$celda.png" -strip "$DESTINO/${numero}_${palos[fila]}.png"
  done
done
magick "$tmp/c_49.png" -strip "$DESTINO/dorso.png"

echo "Cartas generadas en $DESTINO: $(ls "$DESTINO"/*.png | wc -l) imágenes"
