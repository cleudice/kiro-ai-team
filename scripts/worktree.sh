#!/usr/bin/env bash
# Ciclo de worktree por PBI — uso:
#   worktree.sh start  <PBI-ID>   cria ../wt-<ID> a partir da branch principal
#   worktree.sh finish <PBI-ID>   remove o worktree após merge aprovado
set -euo pipefail
CMD="${1:?start|finish}"; ID="${2:?id do PBI}"
MAIN="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|origin/||' || echo main)"
ROOT="$(git rev-parse --show-toplevel)"; WT="$ROOT/../wt-$ID"
case "$CMD" in
  start)
    git fetch origin "$MAIN"
    git worktree add -b "pbi/$ID" "$WT" "origin/$MAIN"
    echo "OK worktree: $WT (branch pbi/$ID) — 1 PBI por worktree, merge só via merge-gate";;
  finish)
    git worktree remove "$WT" --force
    git branch -D "pbi/$ID" 2>/dev/null || true
    echo "OK worktree removido";;
  *) echo "comando invalido"; exit 1;;
esac
