#!/usr/bin/env bash
# run-hook.sh <script.sh> [args...] — ponto de entrada único de TODO hook (JSON em
# hooks/*.json e guards por-agente embutidos em agents/*.md).
#
# Por quê existe (C3 da auditoria 1.11): o Kiro executa o "command" de um hook via
# `spawn(command, { shell: true })`. No Windows, shell:true resolve para
# process.env.ComSpec — cmd.exe, não bash — mesmo com o Kiro/Git Bash instalados.
# O comando antigo (`bash "$(bash .kiro/scripts/kiro-paths.sh)/hooks/scripts/X.sh"`)
# tem substituição `$(...)` e aspas aninhadas: sintaxe de bash, não de cmd.exe. Sob
# cmd, "$(bash" é um argumento literal — o hook nunca resolvia o script de verdade,
# silenciosamente (sem erro visível, só um comando que não fazia nada útil).
#
# A correção: UMA única invocação de shell no "command" do hook (sem `$()`, sem
# aspas aninhadas, sem `&&`/`;`/`|`) — `bash .kiro/scripts/run-hook.sh X.sh`. Isso é
# válido tanto para cmd.exe (que só encaminha os argv pro bash.exe do PATH — cmd não
# interpreta nada aqui, então não há sintaxe pra quebrar) quanto para sh/bash no
# Linux/macOS. Path relativo (não ${WORKSPACE_ROOT}) porque o cwd do processo do
# hook já É a raiz do workspace (confirmado no bundle: resolveCommandCwd).
#
# uso: bash .kiro/scripts/run-hook.sh <script.sh> [args...]
#      (chamado pelo "command" de hooks/*.json e dos hooks embutidos em agents/*.md)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../.kiro/scripts
SCRIPT="${1:?uso: run-hook.sh <script.sh em hooks/scripts> [args...]}"; shift
ENGINE="$(bash "$HERE/kiro-paths.sh")"
# exec preserva stdin (payload JSON do hook) e o exit code do script-alvo.
exec bash "$ENGINE/hooks/scripts/$SCRIPT" "$@"
