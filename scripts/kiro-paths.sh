#!/usr/bin/env bash
# kiro-paths.sh — resolve e imprime a RAIZ da engine kiro-ai-team (onde agents/
# skills/scripts de verdade estão instalados). Existe porque nos escopos
# hybrid/global a engine mora em $KIRO_HOME, não em <projeto>/.kiro — mas
# prompts/skills/hooks continuam sendo invocados a partir do projeto, no
# caminho fixo `.kiro/scripts/kiro-paths.sh` (este arquivo é copiado ali em
# TODA instalação, mesmo hybrid/global, exatamente pra servir de ponto único
# de indireção — ver README "a dualidade" e install.sh install_project_layer).
#
# uso: ENGINE="$(bash .kiro/scripts/kiro-paths.sh)"
#      bash "$ENGINE/skills/merge-gate/scripts/check-gates.sh" ...
#
# Precedência:
#   1. $KIRO_ENGINE já exportado no ambiente (override manual/CI)
#   2. .kiro-ai-team-paths ao lado deste script (gravado pelo installer com o
#      caminho absoluto real da engine — igual em project, hybrid e global)
#   3. $KIRO_HOME/.kiro-ai-team-paths (fallback — engine global sem camada de
#      projeto por perto, ex.: rodando fora de um repo instalado)
#   4. o próprio diretório .kiro onde este script está (escopo project: a
#      engine e o projeto são o mesmo lugar, então isto já é a resposta certa)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../.kiro/scripts
PROJECT_KIRO="$(dirname "$HERE")"                       # .../.kiro

if [ -n "${KIRO_ENGINE:-}" ]; then
  printf '%s\n' "$KIRO_ENGINE"; exit 0
fi

if [ -f "$PROJECT_KIRO/.kiro-ai-team-paths" ]; then
  # shellcheck disable=SC1090
  . "$PROJECT_KIRO/.kiro-ai-team-paths"
  printf '%s\n' "${KIRO_ENGINE:-$PROJECT_KIRO}"; exit 0
fi

KIRO_HOME="${KIRO_HOME:-$HOME/.kiro}"
if [ -f "$KIRO_HOME/.kiro-ai-team-paths" ]; then
  # shellcheck disable=SC1090
  . "$KIRO_HOME/.kiro-ai-team-paths"
  printf '%s\n' "${KIRO_ENGINE:-$KIRO_HOME}"; exit 0
fi

printf '%s\n' "$PROJECT_KIRO"
