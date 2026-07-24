#!/usr/bin/env bash
# qa-blackbox-guard.sh — defesa em profundidade pra "qa-blackbox nunca lê src/" (A5).
# Embutido como hook por-agente (preToolUse, matcher fs_read) em agents/qa-blackbox.json
# — é o único mecanismo do Kiro que mira UM agente específico; hooks globais em
# .kiro/hooks/ não têm como saber qual agente está rodando e bloquear leitura de
# src/ ali quebraria dev-*/reviewer-code também.
#
# AVISO HONESTO: o contrato exato de como um action.type=command recebe os dados
# da chamada de tool (stdin? qual formato JSON? quais chaves?) não está documentado
# publicamente no momento em que este script foi escrito. Por isso ele tenta
# reconhecer o caminho do arquivo por várias vias e, se não reconhecer NADA, FALHA
# ABERTO (exit 0, não bloqueia) — um guard que bloqueia tudo por engano quebraria o
# qa-blackbox inteiro, o que é pior que não ter o guard. Isto é reforço mecânico
# best-effort; a regra continua vivendo (e sendo a fonte da verdade) no prompt do
# agente e em task-preflight — não confie só nisto.
set -uo pipefail
PAYLOAD="$(cat 2>/dev/null || true)"

PATH_FOUND="$(printf '%s' "$PAYLOAD" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
def dig(o):
    if isinstance(o, str):
        return o
    if isinstance(o, dict):
        for k in ('path', 'file_path', 'filePath', 'file', 'input', 'arguments'):
            if k in o:
                r = dig(o[k])
                if r:
                    return r
    return None
r = dig(d)
if r:
    print(r)
" 2>/dev/null)"

if [ -z "$PATH_FOUND" ]; then
  PATH_FOUND="$(printf '%s' "$PAYLOAD" | grep -ozE '[^"'"'"' ]*(^|/)src/[^"'"'"' ]*' 2>/dev/null | tr -d '\0' | head -c 500)"
fi

if [ -n "$PATH_FOUND" ] && printf '%s' "$PATH_FOUND" | grep -qiE '(^|/)src/'; then
  echo "qa-blackbox: proibido ler implementação em src/ — se um teste só pode ser escrito olhando o código, a spec está incompleta: devolva ao spec-analyst. Caminho: $PATH_FOUND" >&2
  exit 2
fi
exit 0
