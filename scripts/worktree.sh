#!/usr/bin/env bash
# Ciclo de worktree por PBI — uso:
#   worktree.sh start  <PBI-ID>            cria ../wt-<ID> a partir da branch principal
#   worktree.sh finish <PBI-ID> [--force]  remove o worktree após merge aprovado
set -euo pipefail
CMD="${1:?start|finish}"; ID="${2:?id do PBI}"; FORCE="${3:-}"
MAIN="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
MAIN="${MAIN#origin/}"
if [ -z "$MAIN" ]; then
  echo "⚠ origin/HEAD não configurado — assumindo branch principal='main'. Se estiver errado: git remote set-head origin -a" >&2
  MAIN=main
fi
ROOT="$(git rev-parse --show-toplevel)"; WT="$ROOT/../wt-$ID"
case "$CMD" in
  start)
    git fetch origin "$MAIN"
    git worktree add -b "pbi/$ID" "$WT" "origin/$MAIN"
    echo "OK worktree: $WT (branch pbi/$ID) — 1 PBI por worktree, merge só via merge-gate";;
  finish)
    if [ "$FORCE" != "--force" ]; then
      if [ -d "$WT" ] && [ -n "$(git -C "$WT" status --porcelain 2>/dev/null)" ]; then
        echo "abortado: $WT tem alterações não commitadas. Confirme e commite, ou rode 'finish $ID --force' para descartar." >&2; exit 1
      fi
      git fetch origin "$MAIN" >/dev/null 2>&1 || true
      if ! git merge-base --is-ancestor "pbi/$ID" "origin/$MAIN" 2>/dev/null; then
        echo "abortado: branch pbi/$ID não está mergeada em origin/$MAIN (merge-gate G5 concluído?). Rode 'finish $ID --force' se tiver certeza." >&2; exit 1
      fi
    fi
    git worktree remove "$WT" --force
    git branch -D "pbi/$ID" 2>/dev/null || true
    echo "OK worktree removido";;
  *) echo "comando invalido"; exit 1;;
esac
