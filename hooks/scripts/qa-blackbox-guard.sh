#!/usr/bin/env bash
# qa-blackbox-guard.sh — defesa em profundidade pra "qa-blackbox nunca lê o código
# de implementação" (A5). Embutido como hook por-agente (preToolUse, matcher fs_read)
# em agents/qa-blackbox.json — é o único mecanismo do Kiro que mira UM agente
# específico; hooks globais em .kiro/hooks/ não têm como saber qual agente está
# rodando e bloquear leitura ali quebraria dev-*/reviewer-code também.
#
# Diretórios protegidos: "Código-fonte:" do steering/tech.md (fallback src/) —
# ver lib.sh:code_dirs. Extração de payload + aviso de fail-open: guard-common.sh.
set -uo pipefail
. "$(dirname "$0")/guard-common.sh"
cd_repo_root
PAYLOAD="$(cat 2>/dev/null || true)"
PATH_FOUND="$(guard_payload_path "$PAYLOAD")"

if [ -n "$PATH_FOUND" ] && guard_path_is_code "$PATH_FOUND"; then
  echo "qa-blackbox: proibido ler implementação em $(guard_code_dirs_label) — se um teste só pode ser escrito olhando o código, a spec está incompleta: devolva ao spec-analyst. Caminho: $PATH_FOUND" >&2
  exit 2
fi
exit 0
