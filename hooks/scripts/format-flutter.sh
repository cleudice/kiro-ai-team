#!/usr/bin/env bash
# format-flutter.sh — dart format + flutter analyze, determinístico, rodado pelo
# hook format-flutter (PostFileSave em .dart). Convertido de action.type=agent
# pra command (I5) — não precisa de um turno de modelo inteiro só pra rodar
# 'dart format' a cada save; hook determinístico é mais barato e mais rápido.
#
# O contrato exato de como o Kiro repassa o arquivo salvo pra um action.type=command
# não é documentado publicamente. Mesma estratégia de resolução do check-oracle.sh:
# $1, $KIRO_FILE_PATH e, na ausência dos dois, o .dart alterado mais recente no git.
set -uo pipefail
FAIL=0
# mktemp em vez de /tmp/*.log fixo: o desenho é 1 PBI = 1 worktree — saves
# concorrentes em worktrees diferentes colidiriam no mesmo arquivo de log.
LOG="$(mktemp -t format-flutter.XXXXXX)"; trap 'rm -f "$LOG"' EXIT

# newest_of — lê paths no stdin, devolve o de mtime mais recente ('tail -1' após
# sort pegava o último em ordem ALFABÉTICA, não o salvo por último)
newest_of() {
  local f t newest="" newest_t=0
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    t="$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null || echo 0)"
    [ "$t" -ge "$newest_t" ] && { newest_t="$t"; newest="$f"; }
  done
  [ -n "$newest" ] && printf '%s\n' "$newest"
}

resolve_file() {
  if [ -n "${1:-}" ] && [ -f "${1:-}" ]; then printf '%s\n' "$1"; return 0; fi
  if [ -n "${KIRO_FILE_PATH:-}" ] && [ -f "$KIRO_FILE_PATH" ]; then printf '%s\n' "$KIRO_FILE_PATH"; return 0; fi
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    { git diff --name-only -- '*.dart'; git diff --cached --name-only -- '*.dart'; git ls-files --others --exclude-standard -- '*.dart'; } \
      | sort -u | newest_of
  fi
}

# find_up <dir> <pattern> — procura <pattern> no diretório e nos pais, até a raiz
# do repo (raiz do pacote Flutter = onde está o pubspec.yaml).
find_up() {
  local dir="$1" pattern="$2" top; top="$(git rev-parse --show-toplevel 2>/dev/null || echo /)"
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    [ -f "$dir/$pattern" ] && { printf '%s\n' "$dir"; return 0; }
    [ "$dir" = "$top" ] && break
    dir="$(dirname "$dir")"
  done
  return 1
}

F="$(resolve_file "${1:-}")"
[ -z "$F" ] && exit 0  # nada resolvido, sem trigger claro — não falha o save

PKG_DIR="$(find_up "$(dirname "$F")" pubspec.yaml || true)"
if [ -z "$PKG_DIR" ]; then
  echo "  ℹ nenhum pubspec.yaml encontrado subindo de $(dirname "$F") — pulando format/analyze"
  exit 0
fi

if ! dart format "$F" >"$LOG" 2>&1; then
  echo "  ✘ dart format falhou em $F"; cat "$LOG"; FAIL=1
fi

if ! ( cd "$PKG_DIR" && flutter analyze ) >"$LOG" 2>&1; then
  echo "  ✘ flutter analyze reportou problema(s) em $PKG_DIR"; cat "$LOG"; FAIL=1
fi

exit $FAIL
