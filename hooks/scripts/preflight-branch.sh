#!/usr/bin/env bash
# preflight-branch.sh — avisa no início da sessão (SessionStart) se o diretório
# atual não é o worktree pbi/<ID> de um PBI COM TASK PENDENTE. Era shell inline
# dentro do JSON do hook (não lintável por bash -n/shellcheck, não testável);
# extraído pra cá. I8: só specs com '[ ]' pendente disparam o aviso — senão ele
# apareceria toda sessão até em PBI já fechado, e aviso constante é aviso ignorado.
set -uo pipefail
. "$(dirname "$0")/lib.sh"
cd_repo_root
b="$(git branch --show-current 2>/dev/null || true)"
if [ -n "$b" ] && [ "$b" != "${b#pbi/}" ]; then
  echo "worktree do PBI confirmado: branch $b"
elif grep -l '^- \[ \]' .kiro/specs/*/tasks.md >/dev/null 2>&1; then
  echo "⚠ há specs com task PENDENTE ('[ ]') em .kiro/specs/ mas a branch atual ('${b:-desconhecida}') não é pbi/<ID> — confirme se é o worktree certo antes de rodar 'Start task' (.kiro/scripts/worktree.sh start <PBI>)."
fi
