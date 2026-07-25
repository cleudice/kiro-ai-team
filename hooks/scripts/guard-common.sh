#!/usr/bin/env bash
# guard-common.sh — núcleo compartilhado dos guards por-agente (source, não executar).
# Antes, qa-blackbox-guard.sh e readonly-guard.sh carregavam ~28 linhas byte-a-byte
# idênticas (extração de path do payload) — mesma classe de duplicação que motivou
# lib.sh. Aqui: extração do path + casamento com os diretórios de código do projeto
# (tech.md "Código-fonte:", fallback src/ — ver lib.sh:code_dirs).
#
# AVISO HONESTO (herdado dos dois guards): o contrato exato de como um
# action.type=command recebe os dados da chamada de tool (stdin? qual formato
# JSON? quais chaves?) não está documentado publicamente. Por isso a extração
# tenta várias vias e, se não reconhecer NADA, o guard FALHA ABERTO (exit 0) —
# um guard que bloqueia tudo por engano quebraria o agente inteiro, pior que não
# ter guard. Reforço best-effort; a fonte da verdade é o prompt do agente.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# guard_payload_path <payload> — tenta extrair o caminho do arquivo do payload:
# 1) JSON com chaves conhecidas (python3); 2) fallback grep por substring que
# contenha um dos diretórios de código. Vazio = não reconheceu (falhar aberto).
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
