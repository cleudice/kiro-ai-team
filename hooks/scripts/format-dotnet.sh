#!/usr/bin/env bash
# format-dotnet.sh — dotnet format + build incremental, determinístico, rodado
# pelo hook format-dotnet (PostFileSave em .cs). Convertido de action.type=agent
# pra command (I5) — não precisa de um turno de modelo inteiro só pra rodar
# 'dotnet format' a cada save; hook determinístico é mais barato e mais rápido.
# Projeto legado (.aspx.cs / non-SDK-style, sem <Project Sdk=...> no .csproj):
# pula 'dotnet format' (formatador novo não entende bem projeto antigo) e faz
# só o build incremental — mesmo comportamento que o hook antigo baseado em agente.
# KIRO_HOOK_BUILD=0 desliga o build por save (solução grande onde o incremental
# ainda custa caro) — o task-checkpoint continua cobrindo o build por task.
set -uo pipefail
. "$(dirname "$0")/lib.sh"
cd_repo_root
FAIL=0
# mktemp em vez de /tmp/*.log fixo: o desenho é 1 PBI = 1 worktree — saves
# concorrentes em worktrees diferentes colidiriam no mesmo arquivo de log.
LOG="$(mktemp -t format-dotnet.XXXXXX)"; trap 'rm -f "$LOG"' EXIT

require_tool dotnet || exit 0

F="$(resolve_file '*.cs' "${1:-}")"
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

if [ "${KIRO_HOOK_BUILD:-1}" != "0" ]; then
  if ! dotnet build "$CSPROJ" --nologo -v quiet >"$LOG" 2>&1; then
    echo "  ✘ build incremental falhou em $CSPROJ"; cat "$LOG"; FAIL=1
  fi
fi

exit $FAIL
