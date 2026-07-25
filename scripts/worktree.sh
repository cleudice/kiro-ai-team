#!/usr/bin/env bash
# Ciclo de worktree por PBI — uso:
#   worktree.sh start  <PBI-ID>            cria ../wt-<ID> a partir da branch principal
#                                          (idempotente: worktree/branch já existentes são reusados)
#   worktree.sh start  <PBI-ID> --qa       cria ../wt-<ID>-qa SEM src/ (sparse-checkout) — sessão
#                                          do qa-blackbox: o isolamento black-box vira invariante
#                                          física, não só regra de prompt
#   worktree.sh finish <PBI-ID> [--force]  remove o(s) worktree(s) após merge aprovado
set -euo pipefail
CMD="${1:?start|finish}"; ID="${2:?id do PBI}"; OPT="${3:-}"
MAIN="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
MAIN="${MAIN#origin/}"
if [ -z "$MAIN" ]; then
  echo "⚠ origin/HEAD não configurado — assumindo branch principal='main'. Se estiver errado: git remote set-head origin -a" >&2
  MAIN=main
fi
ROOT="$(git rev-parse --show-toplevel)"; WT="$ROOT/../wt-$ID"; WTQA="$ROOT/../wt-$ID-qa"
case "$CMD" in
  start)
    if [ "$OPT" = "--qa" ]; then
      # worktree do QA: mesma branch pbi/<ID> em checkout esparso sem src/ —
      # 'a spec está incompleta se o teste precisa do código' deixa de depender
      # de disciplina: o código simplesmente não está lá.
      if [ -d "$WTQA" ]; then echo "OK worktree QA já existe (reusado): $WTQA"; exit 0; fi
      git show-ref --verify --quiet "refs/heads/pbi/$ID" || {
        echo "abortado: branch pbi/$ID não existe — rode 'worktree.sh start $ID' antes do worktree QA." >&2; exit 1; }
      # branch própria qa/pbi/<ID> (a mesma branch não pode ter dois checkouts):
      # o qa commita os testes aqui; antes do merge-gate, mesclar em pbi/<ID>
      # ('git merge qa/pbi/<ID>' no worktree do dev) — ver merge-gate/SKILL.md.
      git show-ref --verify --quiet "refs/heads/qa/pbi/$ID" \
        && git worktree add "$WTQA" "qa/pbi/$ID" \
        || git worktree add -b "qa/pbi/$ID" "$WTQA" "pbi/$ID"
      git -C "$WTQA" sparse-checkout set --no-cone '/*' '!/src/'
      echo "OK worktree QA: $WTQA (branch qa/pbi/$ID, SEM src/) — sessão do qa-blackbox roda aqui"
      exit 0
    fi
    # idempotência: quem chegar em segundo (humano no passo 3 × orchestrator no
    # prompt) reusa em vez de morrer com 'branch já existe' — erro fatal aqui
    # vira falso bloqueio na sessão do agente.
    if [ -d "$WT" ]; then echo "OK worktree já existe (reusado): $WT (branch pbi/$ID)"; exit 0; fi
    if git show-ref --verify --quiet "refs/heads/pbi/$ID"; then
      git worktree add "$WT" "pbi/$ID"
      echo "OK worktree recriado da branch existente: $WT (branch pbi/$ID)"
      exit 0
    fi
    git fetch origin "$MAIN"
    git worktree add -b "pbi/$ID" "$WT" "origin/$MAIN"
    echo "OK worktree: $WT (branch pbi/$ID) — 1 PBI por worktree, merge só via merge-gate";;
  finish)
    if [ "$OPT" != "--force" ]; then
      if [ -d "$WT" ] && [ -n "$(git -C "$WT" status --porcelain 2>/dev/null)" ]; then
        echo "abortado: $WT tem alterações não commitadas. Confirme e commite, ou rode 'finish $ID --force' para descartar." >&2; exit 1
      fi
      git fetch origin "$MAIN" >/dev/null 2>&1 || true
      if ! git merge-base --is-ancestor "pbi/$ID" "origin/$MAIN" 2>/dev/null; then
        echo "abortado: branch pbi/$ID não está mergeada em origin/$MAIN (merge-gate G5 concluído?). Rode 'finish $ID --force' se tiver certeza." >&2; exit 1
      fi
    fi
    if [ -d "$WTQA" ]; then git worktree remove "$WTQA" --force; fi
    git worktree remove "$WT" --force
    git branch -D "pbi/$ID" 2>/dev/null || true
    git branch -D "qa/pbi/$ID" 2>/dev/null || true
    echo "OK worktree removido";;
  *) echo "comando invalido"; exit 1;;
esac
