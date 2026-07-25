#!/usr/bin/env bash
# format-flutter.sh — dart format + flutter analyze, determinístico, rodado pelo
# hook format-flutter (PostFileSave em .dart). Convertido de action.type=agent
# pra command (I5) — não precisa de um turno de modelo inteiro só pra rodar
# 'dart format' a cada save; hook determinístico é mais barato e mais rápido.
set -uo pipefail
. "$(dirname "$0")/lib.sh"
cd_repo_root
FAIL=0
# mktemp em vez de /tmp/*.log fixo: o desenho é 1 PBI = 1 worktree — saves
# concorrentes em worktrees diferentes colidiriam no mesmo arquivo de log.
LOG="$(mktemp -t format-flutter.XXXXXX)"; trap 'rm -f "$LOG"' EXIT

require_tool dart || exit 0

F="$(resolve_file '*.dart' "${1:-}")"
[ -z "$F" ] && exit 0  # nada resolvido, sem trigger claro — não falha o save

PUBSPEC="$(find_up "$(dirname "$F")" pubspec.yaml || true)"
if [ -z "$PUBSPEC" ]; then
  echo "  ℹ nenhum pubspec.yaml encontrado subindo de $(dirname "$F") — pulando format/analyze"
  exit 0
fi
PKG_DIR="$(dirname "$PUBSPEC")"

if ! dart format "$F" >"$LOG" 2>&1; then
  echo "  ✘ dart format falhou em $F"; cat "$LOG"; FAIL=1
fi

if require_tool flutter; then
  if ! ( cd "$PKG_DIR" && flutter analyze ) >"$LOG" 2>&1; then
    echo "  ✘ flutter analyze reportou problema(s) em $PKG_DIR"; cat "$LOG"; FAIL=1
  fi
fi

exit $FAIL
