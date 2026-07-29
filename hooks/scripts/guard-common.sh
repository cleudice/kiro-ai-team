#!/usr/bin/env bash
# guard-common.sh — núcleo compartilhado dos guards por-agente (source, não executar).
# Antes, qa-blackbox-guard.sh e readonly-guard.sh carregavam ~28 linhas byte-a-byte
# idênticas (extração de path do payload) — mesma classe de duplicação que motivou
# lib.sh. Aqui: extração do path + casamento com os diretórios de código do projeto
# (tech.md "Código-fonte:", fallback src/ — ver lib.sh:code_dirs).
#
# O payload de stdin em preToolUse — CONFIRMADO lendo o bundle instalado do Kiro
# (função `j()`, hooks-*.js): um objeto com {session_id, hook_event_name, cwd,
# tool_name, tool_input}, onde tool_input é o objeto de argumentos da própria tool
# (formato interno por tool, ex.: {"path": "..."} pra leitura de arquivo único,
# {"paths": [...]} pra leitura múltipla — esse nível interno segue sem doc pública,
# por isso a extração tenta várias chaves conhecidas). Se guard_payload_path não
# reconhecer NADA, o guard FALHA ABERTO (exit 0) — um guard que bloqueia tudo por
# engano quebraria o agente inteiro, pior que não ter guard.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# guard_payload_path <payload> — tenta extrair o caminho do arquivo do payload:
# 1) JSON com chaves conhecidas, descendo em tool_input (python3); 2) fallback
# grep por substring que contenha um dos diretórios de código. Vazio = não
# reconheceu (falhar aberto).
guard_payload_path() {
  local payload="$1" found d
  found="$(printf '%s' "$payload" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
def dig(o):
    if isinstance(o, str):
        return o
    if isinstance(o, list):
        for item in o:
            r = dig(item)
            if r:
                return r
        return None
    if isinstance(o, dict):
        for k in ('tool_input', 'path', 'file_path', 'filePath', 'file', 'paths', 'input', 'arguments'):
            if k in o:
                r = dig(o[k])
                if r:
                    return r
    return None
r = dig(d)
if r:
    print(r)
" 2>/dev/null)"
  if [ -z "$found" ]; then
    # sem -z: 'grep -ozE' é GNU-only — no BSD/macOS falhava engolido pelo 2>/dev/null
    # e o guard virava inerte. Payload JSON de uma linha só funciona igual sem -z.
    for d in $(code_dirs); do
      found="$(printf '%s' "$payload" | grep -oE '[^"'"'"' ]*/'"$d"'/[^"'"'"' ]*' 2>/dev/null | head -1 | head -c 500)"
      [ -z "$found" ] && found="$(printf '%s' "$payload" | grep -oE '(^|[^"'"'"' ]*)'"$d"'/[^"'"'"' ]*' 2>/dev/null | head -1 | head -c 500)"
      [ -n "$found" ] && break
    done
  fi
  printf '%s' "$found"
}

# guard_path_is_code <path> — true se o caminho cai em um dos diretórios de código
guard_path_is_code() {
  local p="$1" d
  for d in $(code_dirs); do
    printf '%s' "$p" | grep -qiE "(^|/)$d/" && return 0
  done
  return 1
}

# guard_code_dirs_label — rótulo humano dos diretórios protegidos (ex.: "src/" ou "lib/ web/")
guard_code_dirs_label() {
  local d out=""
  for d in $(code_dirs); do out="$out$d/ "; done
  printf '%s' "${out% }"
}
