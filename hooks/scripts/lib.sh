#!/usr/bin/env bash
# lib.sh — funções comuns dos scripts de hook (source, não executar).
# Antes, newest_of/resolve_file/find_up viviam duplicados byte-a-byte em
# format-dotnet.sh e format-flutter.sh, com find_up de MESMO nome e semântica
# divergente (um devolvia arquivo, o outro diretório) — armadilha de manutenção.
# Aqui: find_up devolve sempre o ARQUIVO; quem quiser o diretório usa dirname.

# cd_repo_root — os hooks referenciam caminhos relativos à raiz do workspace
# (.kiro/steering/..., git diff etc.); se o Kiro invocar o command com outro cwd,
# tudo quebraria silenciosamente. Melhor esforço: sobe pra raiz do repo git.
cd_repo_root() {
  local t
  t="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$t" ] && cd "$t" || true
}

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

# resolve_file <glob> [<arg1>] — resolve o arquivo salvo: $arg1, depois
# $KIRO_FILE_PATH, depois o arquivo casando <glob> com mudança não commitada
# mais recente (o contrato de como o Kiro repassa o arquivo salvo a um
# action.type=command não é documentado publicamente — por isso as 3 vias).
resolve_file() {
  local glob="$1" arg="${2:-}"
  if [ -n "$arg" ] && [ -f "$arg" ]; then printf '%s\n' "$arg"; return 0; fi
  if [ -n "${KIRO_FILE_PATH:-}" ] && [ -f "$KIRO_FILE_PATH" ]; then printf '%s\n' "$KIRO_FILE_PATH"; return 0; fi
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    { git diff --name-only -- "$glob"; git diff --cached --name-only -- "$glob"; git ls-files --others --exclude-standard -- "$glob"; } \
      | sort -u | newest_of
  fi
}

# find_up <dir> <pattern> — procura <pattern> no diretório e nos pais, até a
# raiz do repo; devolve o caminho do ARQUIVO encontrado. O dir é canonicalizado
# primeiro: com path relativo, dirname degenera em "." pra sempre (loop infinito).
find_up() {
  local dir="$1" pattern="$2" top; top="$(git rev-parse --show-toplevel 2>/dev/null || echo /)"
  dir="$(cd "$dir" 2>/dev/null && pwd)" || return 1
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    local f; f="$(find "$dir" -maxdepth 1 -iname "$pattern" 2>/dev/null | head -1)"
    [ -n "$f" ] && { printf '%s\n' "$f"; return 0; }
    [ "$dir" = "$top" ] && break
    dir="$(dirname "$dir")"
  done
  return 1
}

# unfilled <cmd> — true se o comando é placeholder não preenchido do template
# (vazio ou contendo '...'), mesma regra do check-gates.sh
unfilled() { local c="$1"; [ -z "$(printf '%s' "$c" | tr -d '[:space:]')" ] && return 0; case "$c" in *'...'*) return 0;; esac; return 1; }

# require_tool <cmd> — toolchain ausente NÃO é erro do save: máquina sem o SDK
# (ou repo multi-stack com hook do stack errado copiado) viraria hook vermelho
# em todo save. Avisa e o chamador sai 0.
require_tool() {
  command -v "$1" >/dev/null 2>&1 && return 0
  echo "  ℹ '$1' não encontrado no PATH — hook pulado (instale a toolchain ou remova este hook de .kiro/hooks/)"
  return 1
}
