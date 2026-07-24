#!/usr/bin/env bash
# test-check-gates.sh — testa skills/merge-gate/scripts/check-gates.sh contra a
# matriz de gates (G1-G5) + resolução de worktree por PBI (B3) + G5 bloqueante (B5)
# + G2 ancorado por critério (A4). exit 0 = toda a matriz bateu com o esperado.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SCRIPT="$ROOT/skills/merge-gate/scripts/check-gates.sh"
FAIL=0; N=0

pass(){ N=$((N+1)); printf '  ✔ %s\n' "$1"; }
fail(){ N=$((N+1)); printf '  ✘ %s\n' "$1"; FAIL=1; }

# expect_exit <esperado> <descrição> -- <comando...>
expect_exit() {
  local want="$1" desc="$2"; shift 2
  [ "$1" = "--" ] && shift
  local out; out="$("$@" 2>&1)"; local got=$?
  if [ "$got" -eq "$want" ]; then pass "$desc (exit $got)"
  else fail "$desc (esperado exit $want, veio $got) — saída:"$'\n'"$out"; fi
}

# ---- fixture: repo git com main + docs/reviews + docs/tests-spec -----------
mk_base_repo() {
  local dir="$1"
  rm -rf "$dir"; mkdir -p "$dir"; cd "$dir"
  git init -q -b main
  git config user.email t@t.com; git config user.name t
  mkdir -p docs/reviews docs/tests-spec
  echo "x" > README.md; git add -A; git commit -qm init
}

green_gates() {
  # popula docs/reviews e docs/tests-spec com evidência 100% verde para PBI/slug no cwd
  # inclui 'Commit: <sha-do-HEAD-atual>' (B2) — quando a branch pbi/<ID> existir de
  # verdade e resolver pra este mesmo commit, o vínculo evidência↔commit bate.
  local pbi="$1" slug="$2" sha
  sha="$(git rev-parse HEAD 2>/dev/null || true)"
  echo "# tests spec" > "docs/tests-spec/$slug.md"
  { printf 'R1.1 - PASS - ok\nR1.2 - PASS - ok\n'; [ -n "$sha" ] && printf 'Commit: %s\n' "$sha"; } > "docs/reviews/$pbi-verify.md"
  { printf 'Veredicto: APROVADO\n'; [ -n "$sha" ] && printf 'Commit: %s\n' "$sha"; } > "docs/reviews/$pbi-spec.md"
  { printf 'Veredicto: APROVADO\n'; [ -n "$sha" ] && printf 'Commit: %s\n' "$sha"; } > "docs/reviews/$pbi-code.md"
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# =========================================================================
# 1) matriz básica de gates, tudo verde, --repo explícito, --g5-log PASS
# =========================================================================
D="$TMP/basic"; mk_base_repo "$D"
green_gates PBI-1 slug-1
printf 'G5: PASS\n' > "$TMP/g5.log"
expect_exit 0 "tudo verde + g5-log PASS -> exit 0" -- \
  bash "$SCRIPT" PBI-1 slug-1 --repo "$D" --test-cmd "true" --g5-log "$TMP/g5.log"

# G1 ausente
D="$TMP/no-g1"; mk_base_repo "$D"
printf 'R1.1 - PASS - ok\n' > "docs/reviews/PBI-2-verify.md"
printf 'Veredicto: APROVADO\n' > "docs/reviews/PBI-2-spec.md"
printf 'Veredicto: APROVADO\n' > "docs/reviews/PBI-2-code.md"
printf 'G5: PASS\n' > "$TMP/g5-2.log"
expect_exit 1 "G1 sem tests-spec (trilho feature) -> exit 1" -- \
  bash "$SCRIPT" PBI-2 slug-2 --repo "$D" --test-cmd "true" --g5-log "$TMP/g5-2.log"

# G1 dispensado em manutenção sem tests-spec, resto verde
D="$TMP/manutencao"; mk_base_repo "$D"
printf 'R1.1 - PASS - ok\n' > "docs/reviews/PBI-3-verify.md"
printf 'Veredicto: APROVADO\n' > "docs/reviews/PBI-3-spec.md"
printf 'Veredicto: APROVADO\n' > "docs/reviews/PBI-3-code.md"
printf 'G5: PASS\n' > "$TMP/g5-3.log"
expect_exit 0 "manutenção sem critério novo dispensa G1 -> exit 0" -- \
  bash "$SCRIPT" PBI-3 slug-3 --repo "$D" --track manutencao --test-cmd "true" --g5-log "$TMP/g5-3.log"

# G1b: test-cmd falha
D="$TMP/g1b-fail"; mk_base_repo "$D"
green_gates PBI-4 slug-4
printf 'G5: PASS\n' > "$TMP/g5-4.log"
expect_exit 1 "G1b suíte falha -> exit 1" -- \
  bash "$SCRIPT" PBI-4 slug-4 --repo "$D" --test-cmd "false" --g5-log "$TMP/g5-4.log"

# G3 REPROVADO
D="$TMP/g3-rep"; mk_base_repo "$D"
green_gates PBI-5 slug-5
printf 'Veredicto: REPROVADO\n' > "docs/reviews/PBI-5-spec.md"
printf 'G5: PASS\n' > "$TMP/g5-5.log"
expect_exit 1 "G3 REPROVADO -> exit 1" -- \
  bash "$SCRIPT" PBI-5 slug-5 --repo "$D" --test-cmd "true" --g5-log "$TMP/g5-5.log"

# G4 ausente
D="$TMP/g4-abs"; mk_base_repo "$D"
green_gates PBI-6 slug-6
rm "docs/reviews/PBI-6-code.md"
printf 'G5: PASS\n' > "$TMP/g5-6.log"
expect_exit 1 "G4 ausente -> exit 1" -- \
  bash "$SCRIPT" PBI-6 slug-6 --repo "$D" --test-cmd "true" --g5-log "$TMP/g5-6.log"

# =========================================================================
# 2) B5 — G5 agora é bloqueante por default
# =========================================================================
D="$TMP/g5-default"; mk_base_repo "$D"
green_gates PBI-7 slug-7
expect_exit 1 "sem --g5-log e sem --skip-g5 -> G5 bloqueia (exit 1)" -- \
  bash "$SCRIPT" PBI-7 slug-7 --repo "$D" --test-cmd "true"

expect_exit 0 "--skip-g5 com motivo -> escape explícito, exit 0" -- \
  bash "$SCRIPT" PBI-7 slug-7 --repo "$D" --test-cmd "true" --skip-g5 "sem ambiente de integração disponível"

D="$TMP/g5-fail-log"; mk_base_repo "$D"
green_gates PBI-8 slug-8
printf 'G5: FAIL\n' > "$TMP/g5-8.log"
expect_exit 1 "g5-log com FAIL -> exit 1" -- \
  bash "$SCRIPT" PBI-8 slug-8 --repo "$D" --test-cmd "true" --g5-log "$TMP/g5-8.log"

# =========================================================================
# 3) A4 — G2 ancorado por linha de critério (R#.# - PASS|FAIL|BLOCKED)
# =========================================================================
D="$TMP/g2-anchored-ok"; mk_base_repo "$D"
green_gates PBI-9 slug-9
# evidência bruta colada no verify.md MENCIONA a palavra FAIL fora de uma linha de critério
{
  echo "R1.1 - PASS - ok"
  echo "R1.2 - PASS - ok"
  echo "Evidência: log completo do teste (0 FAILURES, 0 errors, build succeeded)"
} > "docs/reviews/PBI-9-verify.md"
printf 'G5: PASS\n' > "$TMP/g5-9.log"
expect_exit 0 "G2: 'FAIL' fora de linha de critério não reprova (A4) -> exit 0" -- \
  bash "$SCRIPT" PBI-9 slug-9 --repo "$D" --test-cmd "true" --g5-log "$TMP/g5-9.log"

D="$TMP/g2-anchored-bad"; mk_base_repo "$D"
green_gates PBI-10 slug-10
{
  echo "R1.1 - PASS - ok"
  echo "R1.2 - FAIL - quebrou no critério de borda"
} > "docs/reviews/PBI-10-verify.md"
printf 'G5: PASS\n' > "$TMP/g5-10.log"
expect_exit 1 "G2: FAIL numa linha de critério real reprova -> exit 1" -- \
  bash "$SCRIPT" PBI-10 slug-10 --repo "$D" --test-cmd "true" --g5-log "$TMP/g5-10.log"

D="$TMP/g2-no-criteria"; mk_base_repo "$D"
green_gates PBI-11 slug-11
echo "nada de critério aqui, só prosa" > "docs/reviews/PBI-11-verify.md"
printf 'G5: PASS\n' > "$TMP/g5-11.log"
expect_exit 1 "G2: zero linhas de critério reprova -> exit 1" -- \
  bash "$SCRIPT" PBI-11 slug-11 --repo "$D" --test-cmd "true" --g5-log "$TMP/g5-11.log"

# =========================================================================
# 4) B3 — resolução automática de --repo a partir do worktree do PBI
# =========================================================================
# 4a. branch pbi/<ID> com worktree registrado -> deve usar ESSE diretório
D="$TMP/wt-main"; mk_base_repo "$D"
WT="$TMP/wt-PBI-20"
git -C "$D" worktree add -q -b pbi/PBI-20 "$WT" main >/dev/null 2>&1
mkdir -p "$WT/docs/reviews" "$WT/docs/tests-spec"
( cd "$WT" && green_gates PBI-20 slug-20 )
SHA20="$(git -C "$D" rev-parse pbi/PBI-20)"
printf 'G5: PASS\nCommit: %s\n' "$SHA20" > "$TMP/g5-20.log"
# roda check-gates de dentro do repo principal, SEM --repo: deve achar o worktree do PBI
expect_exit 0 "sem --repo: resolve worktree de pbi/PBI-20 automaticamente -> exit 0" -- \
  bash -c "cd '$D' && bash '$SCRIPT' PBI-20 slug-20 --test-cmd true --g5-log '$TMP/g5-20.log'"

# evidência SÓ no repo principal (não no worktree) deve FALHAR — prova que checou o lugar certo
D="$TMP/wt-wrong-place"; mk_base_repo "$D"
WT2="$TMP/wt-PBI-21"
git -C "$D" worktree add -q -b pbi/PBI-21 "$WT2" main >/dev/null 2>&1
green_gates PBI-21 slug-21   # evidência no repo PRINCIPAL, não no worktree
printf 'G5: PASS\n' > "$TMP/g5-21.log"
expect_exit 1 "evidência no lugar errado (main, não worktree) -> exit 1" -- \
  bash -c "cd '$D' && bash '$SCRIPT' PBI-21 slug-21 --test-cmd true --g5-log '$TMP/g5-21.log'"

# 4b. branch pbi/<ID> existe mas SEM worktree registrado -> reprova cedo, mensagem clara
D="$TMP/wt-missing"; mk_base_repo "$D"
git -C "$D" branch pbi/PBI-22 main
expect_exit 1 "branch pbi/<ID> sem worktree -> exit 1 com mensagem clara" -- \
  bash -c "cd '$D' && bash '$SCRIPT' PBI-22 slug-22 --test-cmd true"

# 4c. sem branch pbi/<ID> nenhuma -> cai no cwd (compat com uso simples/manual)
D="$TMP/no-pbi-branch"; mk_base_repo "$D"
green_gates PBI-23 slug-23
printf 'G5: PASS\n' > "$TMP/g5-23.log"
expect_exit 0 "sem branch pbi/<ID>: fallback pro cwd -> exit 0" -- \
  bash -c "cd '$D' && bash '$SCRIPT' PBI-23 slug-23 --test-cmd true --g5-log '$TMP/g5-23.log'"

# =========================================================================
# 5) bump-counter (comportamento existente, não deve regredir)
# =========================================================================
D="$TMP/counter"; mk_base_repo "$D"
expect_exit 0 "bump-counter -> exit 0" -- bash "$SCRIPT" bump-counter --repo "$D"
[ "$(cat "$D/docs/reviews/.merge-count")" = "1" ] && pass "bump-counter grava contador" || fail "bump-counter não gravou contador"
N=$((N+1))

# I4 — bump-counter SEM --repo, rodado de dentro do WORKTREE de um PBI, grava o
# contador no repo PRINCIPAL (não no worktree, que 'worktree.sh finish' apagaria)
D="$TMP/counter-wt-main"; mk_base_repo "$D"
WTC="$TMP/wt-PBI-counter"
git -C "$D" worktree add -q -b pbi/PBI-counter "$WTC" main >/dev/null 2>&1
expect_exit 0 "bump-counter sem --repo, de dentro do worktree -> exit 0" -- \
  bash -c "cd '$WTC' && bash '$SCRIPT' bump-counter"
[ -f "$D/docs/reviews/.merge-count" ] && pass "bump-counter gravou contador no repo PRINCIPAL, não no worktree" \
  || fail "bump-counter não gravou contador no repo principal"
N=$((N+1))
[ ! -f "$WTC/docs/reviews/.merge-count" ] && pass "bump-counter NÃO gravou contador no worktree" \
  || fail "bump-counter gravou contador no worktree por engano"
N=$((N+1))

# =========================================================================
# 6) M5 — --test-cmd placeholder de tech.md não preenchido reprova cedo e claro
# =========================================================================
D="$TMP/m5-placeholder"; mk_base_repo "$D"
green_gates PBI-24 slug-24
printf 'G5: PASS\n' > "$TMP/g5-24.log"
expect_exit 1 "--test-cmd com placeholder '...' não preenchido -> exit 1" -- \
  bash "$SCRIPT" PBI-24 slug-24 --repo "$D" --test-cmd '...' --g5-log "$TMP/g5-24.log"

# =========================================================================
# 7) ledger — 1 linha por execução em docs/reviews/.gate-ledger (dado pra podar processo depois)
# =========================================================================
D="$TMP/ledger"; mk_base_repo "$D"
green_gates PBI-25 slug-25
printf 'G5: PASS\n' > "$TMP/g5-25.log"
bash "$SCRIPT" PBI-25 slug-25 --repo "$D" --test-cmd true --g5-log "$TMP/g5-25.log" >/dev/null
if [ -f "$D/docs/reviews/.gate-ledger" ] && grep -q 'PBI-25' "$D/docs/reviews/.gate-ledger"; then
  pass "ledger registrou a execução do PBI-25"
else
  fail "ledger não registrou PBI-25"
fi
N=$((N+1))

# =========================================================================
# 8) B2 — evidência de gate amarrada ao commit revisado (linha 'Commit: <sha>')
# =========================================================================
D="$TMP/b2-stale-commit"; mk_base_repo "$D"
WT8="$TMP/wt-PBI-30"
git -C "$D" worktree add -q -b pbi/PBI-30 "$WT8" main >/dev/null 2>&1
mkdir -p "$WT8/docs/reviews" "$WT8/docs/tests-spec"
( cd "$WT8" && green_gates PBI-30 slug-30 )
SHA30="$(git -C "$D" rev-parse pbi/PBI-30)"
printf 'G5: PASS\nCommit: %s\n' "$SHA30" > "$TMP/g5-30.log"
# commit MAIS código na branch DEPOIS da evidência ter sido gravada — evidência fica velha
( cd "$WT8" && echo "mudanca" >> README.md && git add README.md && git commit -qm "mais codigo depois da revisao" )
expect_exit 1 "B2: código commitado após a evidência aprovar -> gates reprovam (evidência velha)" -- \
  bash -c "cd '$D' && bash '$SCRIPT' PBI-30 slug-30 --test-cmd true --g5-log '$TMP/g5-30.log'"

# evidência sem linha 'Commit:' nenhuma, com branch pbi/<ID> resolvível -> reprova (não escapa a checagem)
D="$TMP/b2-no-commit-line"; mk_base_repo "$D"
WT9="$TMP/wt-PBI-31"
git -C "$D" worktree add -q -b pbi/PBI-31 "$WT9" main >/dev/null 2>&1
mkdir -p "$WT9/docs/reviews" "$WT9/docs/tests-spec"
( cd "$WT9" && echo "# tests spec" > docs/tests-spec/slug-31.md
  printf 'R1.1 - PASS - ok\n' > docs/reviews/PBI-31-verify.md
  printf 'Veredicto: APROVADO\n' > docs/reviews/PBI-31-spec.md
  printf 'Veredicto: APROVADO\n' > docs/reviews/PBI-31-code.md )
printf 'G5: PASS\n' > "$TMP/g5-31.log"
expect_exit 1 "B2: evidência sem linha 'Commit:' com branch pbi/<ID> resolvível -> exit 1" -- \
  bash -c "cd '$D' && bash '$SCRIPT' PBI-31 slug-31 --test-cmd true --g5-log '$TMP/g5-31.log'"

# B2 + I3 — commitar a PRÓPRIA evidência (docs/reviews/**, docs/tests-spec/**) DEPOIS
# da revisão (necessário pra 'worktree.sh finish' aceitar remover o worktree) NÃO
# invalida o vínculo evidência↔commit: só commit que toca algo FORA desses caminhos
# conta como "código novo" pro SHA de referência.
D="$TMP/b2-evidence-commit-ok"; mk_base_repo "$D"
WT10="$TMP/wt-PBI-32"
git -C "$D" worktree add -q -b pbi/PBI-32 "$WT10" main >/dev/null 2>&1
mkdir -p "$WT10/docs/reviews" "$WT10/docs/tests-spec"
( cd "$WT10" && green_gates PBI-32 slug-32 )
SHA32="$(git -C "$D" rev-parse pbi/PBI-32)"   # sha ANTES de commitar a evidência
printf 'G5: PASS\nCommit: %s\n' "$SHA32" > "$TMP/g5-32.log"
# agora commita a evidência (paperwork-only commit) — HEAD avança, mas nenhum
# arquivo fora de docs/reviews|tests-spec foi tocado
( cd "$WT10" && git add docs/reviews docs/tests-spec && git commit -qm "evidencia dos gates" )
expect_exit 0 "B2+I3: commit só de docs/reviews|tests-spec não invalida a evidência -> exit 0" -- \
  bash -c "cd '$D' && bash '$SCRIPT' PBI-32 slug-32 --test-cmd true --g5-log '$TMP/g5-32.log'"

echo
echo "TOTAL: $N verificações"
[ $FAIL -eq 0 ] && { echo "TEST-CHECK-GATES: OK"; exit 0; } || { echo "TEST-CHECK-GATES: FALHOU"; exit 1; }
