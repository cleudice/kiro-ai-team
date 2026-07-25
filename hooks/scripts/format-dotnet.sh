#!/usr/bin/env bash
# format-dotnet.sh — dotnet format + build incremental, determinístico, rodado
# pelo hook format-dotnet (PostFileSave em .cs). Convertido de action.type=agent
# pra command (I5) — não precisa de um turno de modelo inteiro só pra rodar
# 'dotnet format' a cada save; hook determinístico é mais barato e mais rápido.
# Projeto legado (.aspx.cs / non-SDK-style, sem <Project Sdk=...> no .csproj):
# pula 'dotnet format' (formatador novo não entende bem projeto antigo) e faz
# só o build incremental — mesmo comportamento que o hook antigo baseado em agente.
#
# O contrato exato de como o Kiro repassa o arquivo salvo pra um action.type=command
# não é documentado publicamente. Mesma estratégia de resolução do check-oracle.sh:
# $1, $KIRO_FILE_PATH e, na ausência dos dois, o .cs alterado mais recente no git.
set -uo pipefail
FAIL=0
# mktemp em vez de /tmp/*.log fixo: o desenho é 1 PBI = 1 worktree — saves
# concorrentes em worktrees diferentes colidiriam no mesmo arquivo de log.
LOG="$(mktemp -t format-dotnet.XXXXXX)"; trap 'rm -f "$LOG"' EXIT

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
    { git diff --name-only -- '*.cs'; git diff --cached --name-only -- '*.cs'; git ls-files --others --exclude-standard -- '*.cs'; } \
      | sort -u | newest_of
  fi
}

# find_up <dir> <pattern> — procura <pattern> no diretório e nos pais, até a raiz
# do repo (convenção MSBuild: o .csproj mais próximo do arquivo, subindo).
find_up() {
  local dir="$1" pattern="$2" top; top="$(git rev-parse --show-toplevel 2>/dev/null || echo /)"
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    local f; f="$(find "$dir" -maxdepth 1 -iname "$pattern" 2>/dev/null | head -1)"
    [ -n "$f" ] && { printf '%s\n' "$f"; return 0; }
    [ "$dir" = "$top" ] && break
    dir="$(dirname "$dir")"
  done
  return 1
}

F="$(resolve_file "${1:-}")"
[ -z "$F" ] && exit 0  # nada resolvido, sem trigger claro — não falha o save

CSPROJ="$(find_up "$(dirname "$F")" '*.csproj' || true)"
if [ -z "$CSPROJ" ]; then
  echo "  ℹ nenhum .csproj encontrado subindo de $(dirname "$F") — pulando format/build"
  exit 0
fi

if grep -qi '<Project Sdk=' "$CSPROJ" 2>/dev/null; then
  if ! dotnet format "$CSPROJ" >"$LOG" 2>&1; then
    echo "  ✘ dotnet format falhou em $CSPROJ"; cat "$LOG"; FAIL=1
  fi
else
  echo "  ℹ projeto legado/non-SDK-style ($CSPROJ) — pulando 'dotnet format', só build incremental"
fi

if ! dotnet build "$CSPROJ" --nologo -v quiet >"$LOG" 2>&1; then
  echo "  ✘ build incremental falhou em $CSPROJ"; cat "$LOG"; FAIL=1
fi

exit $FAIL
