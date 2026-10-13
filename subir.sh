#!/bin/bash
# Coloca a página no ar pelo túnel do Cloudflare. Ctrl+C para tirar do ar.

cd "$(dirname "$0")"
PORTA=8080
PAGINA="ecovibe_moda_sustent_vel.html"
LOG=$(mktemp)

# Se a porta estiver ocupada, procura a próxima livre
while lsof -iTCP:$PORTA -sTCP:LISTEN >/dev/null 2>&1; do
  PORTA=$((PORTA + 1))
done

encerrar() {
  kill $SERVIDOR $TUNEL 2>/dev/null
  rm -f "$LOG"
  echo
  echo "Site fora do ar."
}
trap encerrar EXIT
trap 'exit' INT TERM

# Servidor local só acessível pelo próprio Mac; o acesso externo é pelo túnel
python3 -m http.server $PORTA --bind 127.0.0.1 >/dev/null 2>&1 &
SERVIDOR=$!

cloudflared tunnel --url http://localhost:$PORTA >"$LOG" 2>&1 &
TUNEL=$!

# Impede o Mac de dormir enquanto o script estiver rodando
caffeinate -i -w $$ &

echo "Abrindo o túnel..."
for _ in $(seq 30); do
  URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$LOG" | head -1)
  [ -n "$URL" ] && break
  sleep 1
done

if [ -z "$URL" ]; then
  echo "Não consegui abrir o túnel. Saída do cloudflared:"
  cat "$LOG"
  exit 1
fi

LINK="$URL/$PAGINA"
echo "$LINK" | pbcopy
echo
echo "No ar! Link (já copiado):"
echo "  $LINK"
echo
echo "Deixe esta janela aberta. Ctrl+C para tirar do ar."

wait $TUNEL
