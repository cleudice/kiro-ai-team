#!/usr/bin/env bash
# readonly-guard.sh — defesa em profundidade pra papéis que por contrato NÃO
# escrevem em src/ (orchestrator, reviewer-spec, reviewer-code, auditor).
# Embutido como hook por-agente (preToolUse, matcher fs_write) nos agents/*.json
# desses papéis — simétrico ao qa-blackbox-guard.sh (que protege LEITURA): antes,
# a regra "você só reporta, não corrige" vivia só no prompt, enquanto o guard
# existente cobria apenas o papel de QA.
#
# AVISO HONESTO (mesmo do qa-blackbox-guard.sh): o contrato de payload de um
# action.type=command em preToolUse não é documentado publicamente. Se não
# reconhecer NADA, FALHA ABERTO (exit 0) — a fonte da verdade continua sendo o
# prompt do agente; isto é reforço best-effort.
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
  PATH_FOUND="$(printf '%s' "$PAYLOAD" | grep -oE '[^"'"'"' ]*/src/[^"'"'"' ]*' 2>/dev/null | head -1 | head -c 500)"
  [ -z "$PATH_FOUND" ] && PATH_FOUND="$(printf '%s' "$PAYLOAD" | grep -oE '(^|[^"'"'"' ]*)src/[^"'"'"' ]*' 2>/dev/null | head -1 | head -c 500)"
fi

if [ -n "$PATH_FOUND" ] && printf '%s' "$PATH_FOUND" | grep -qiE '(^|/)src/'; then
  echo "este papel não edita src/ — reporte o achado (docs/reviews/ ou docs/issues/) e devolva ao dev-* dono; correção fora do papel quebra a separação que sustenta os gates. Caminho: $PATH_FOUND" >&2
  exit 2
fi
exit 0
