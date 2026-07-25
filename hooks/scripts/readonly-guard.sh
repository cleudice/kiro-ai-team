#!/usr/bin/env bash
# readonly-guard.sh — defesa em profundidade pra papéis que por contrato NÃO
# escrevem no código de implementação (orchestrator, reviewer-spec, reviewer-code,
# auditor). Embutido como hook por-agente (preToolUse, matcher fs_write) nos
# agents/*.json desses papéis — simétrico ao qa-blackbox-guard.sh (que protege
# LEITURA): antes, a regra "você só reporta, não corrige" vivia só no prompt.
#
# Diretórios protegidos: "Código-fonte:" do steering/tech.md (fallback src/) —
# ver lib.sh:code_dirs. Extração de payload + aviso de fail-open: guard-common.sh.
set -uo pipefail
. "$(dirname "$0")/guard-common.sh"
cd_repo_root
PAYLOAD="$(cat 2>/dev/null || true)"
PATH_FOUND="$(guard_payload_path "$PAYLOAD")"

if [ -n "$PATH_FOUND" ] && guard_path_is_code "$PATH_FOUND"; then
  echo "este papel não edita $(guard_code_dirs_label) — reporte o achado (docs/reviews/ ou docs/issues/) e devolva ao dev-* dono; correção fora do papel quebra a separação que sustenta os gates. Caminho: $PATH_FOUND" >&2
  exit 2
fi
exit 0
