#!/usr/bin/env bash
# test-worktree.sh — testa scripts/worktree.sh: start cria worktree/branch;
# finish recusa remover com alterações não commitadas (I3 — evidência de gate
# não pode evaporar junto com o worktree) e aceita depois de commitadas.
# exit 0 = tudo bateu com o esperado.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
WORKTREE_SH="$ROOT/scripts/worktree.sh"
FAIL=0; N=0

pass(){ N=$((N+1)); printf '  ✔ %s\n' "$1"; }
fail(){ N=$((N+1)); printf '  ✘ %s\n' "$1"; FAIL=1; }
expect_exit() {
  local want="$1" desc="$2"; shift 2
  [ "$1" = "--" ] && shift
  local out; out="$("$@" 2>&1)"; local got=$?
  if [ "$got" -eq "$want" ]; then pass "$desc (exit $got)"
  else fail "$desc (esperado exit $want, veio $got) — saída:"$'\n'"$out"; fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

D="$TMP/main-repo"; mkdir -p "$D"; cd "$D"
git init -q -b main
git config user.email t@t.com; git config user.name t
echo x > README.md; git add -A; git commit -qm init
git remote add origin "$D" # remote fictício só pra symbolic-ref origin/HEAD funcionar
git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main 2>/dev/null || true
mkdir -p .git/refs/remotes/origin
git update-ref refs/remotes/origin/main main

# =========================================================================
# 1) start cria worktree + branch pbi/<ID>
# =========================================================================
WT="$D/../wt-I3"
bash "$WORKTREE_SH" start I3 >/tmp/wt-out-1.log 2>&1 || true
if [ -d "$WT" ] && git rev-parse --verify -q refs/heads/pbi/I3 >/dev/null; then
  pass "start: worktree + branch pbi/I3 criados"
else
  fail "start: worktree/branch não criados — saída: $(cat /tmp/wt-out-1.log)"
fi
N=$((N+1))

# =========================================================================
# 2) I3 — finish RECUSA remover com evidência de gate não commitada
# =========================================================================
mkdir -p "$WT/docs/reviews"
echo "Veredicto: APROVADO" > "$WT/docs/reviews/I3-code.md"
expect_exit 1 "I3: finish recusa remover com evidência não commitada" -- \
  bash "$WORKTREE_SH" finish I3

[ -d "$WT" ] && pass "I3: worktree sobrevive à tentativa recusada (evidência não perdida)" \
  || fail "I3: worktree foi removido mesmo com evidência não commitada"
N=$((N+1))

# =========================================================================
# 3) commitar a evidência + mesclar em main -> finish aceita normalmente
# =========================================================================
git -C "$WT" add docs/reviews
git -C "$WT" commit -qm "evidencia dos gates"
git merge -q --no-ff pbi/I3
expect_exit 0 "commit da evidência + branch mesclada -> finish aceita" -- \
  bash "$WORKTREE_SH" finish I3
[ ! -d "$WT" ] && pass "worktree removido após finish bem-sucedido" \
  || fail "worktree ainda existe após finish bem-sucedido"
N=$((N+1))

echo
echo "TOTAL: $N verificações"
[ $FAIL -eq 0 ] && { echo "TEST-WORKTREE: OK"; exit 0; } || { echo "TEST-WORKTREE: FALHOU"; exit 1; }
