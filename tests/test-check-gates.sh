#!/usr/bin/env bash
# test-check-gates.sh — testa skills/merge-gate/scripts/check-gates.sh contra a
# matriz de gates (G1-G5) + resolução de worktree por PBI (B3) + G5 bloqueante (B5)
# + G2 ancorado por critério (A4). exit 0 = toda a matriz bateu com o esperado.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SCRIPT="$ROOT/skills/merge-gate/scripts/check-gates.sh"
FAIL=0; N=0

. "$HERE/lib.sh"   # harness comum: pass/fail/expect_exit/assert_*

# ---- fixture: repo git com main + docs/reviews + docs/tests-spec -----------
mk_base_repo() {
  local dir="$1"
  rm -rf "$dir"; mkdir -p "$dir"; cd "$dir" || exit 1
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
  bash "$SCRIPT" PBI-1 slug-1 --repo "$D" --test-cmd "true" --g5-log "$TMP/g5.log" --allow-missing-branch "fixture sem branch pbi/"

# G1 ausente
D="$TMP/no-g1"; mk_base_repo "$D"
printf 'R1.1 - PASS - ok\n' > "docs/reviews/PBI-2-verify.md"
printf 'Veredicto: APROVADO\n' > "docs/reviews/PBI-2-spec.md"
printf 'Veredicto: APROVADO\n' > "docs/reviews/PBI-2-code.md"
printf 'G5: PASS\n' > "$TMP/g5-2.log"
expect_exit 1 "G1 sem tests-spec (trilho feature) -> exit 1" -- \
  bash "$SCRIPT" PBI-2 slug-2 --repo "$D" --test-cmd "true" --g5-log "$TMP/g5-2.log"

# G1 em manutenção sem tests-spec: dispensa exige flag EXPLÍCITA — ausência de
# arquivo sem --no-new-criteria REPROVA (ausência de evidência nunca vira
# aprovação por omissão), com a flag passa e registra no gate.md
D="$TMP/manutencao"; mk_base_repo "$D"
printf 'R1.1 - PASS - ok\n' > "docs/reviews/PBI-3-verify.md"
printf 'Veredicto: APROVADO\n' > "docs/reviews/PBI-3-spec.md"
printf 'Veredicto: APROVADO\n' > "docs/reviews/PBI-3-code.md"
printf 'G5: PASS\n' > "$TMP/g5-3.log"
expect_exit 1 "manutenção sem tests-spec e SEM --no-new-criteria -> exit 1 (dispensa por omissão não existe mais)" -- \
  bash "$SCRIPT" PBI-3 slug-3 --repo "$D" --track manutencao --test-cmd "true" --g5-log "$TMP/g5-3.log"
expect_exit 0 "manutenção sem critério novo COM --no-new-criteria -> exit 0" -- \
  bash "$SCRIPT" PBI-3 slug-3 --repo "$D" --track manutencao --test-cmd "true" --g5-log "$TMP/g5-3.log" --no-new-criteria "bugfix sem critério de aceitação novo" --allow-missing-branch "fixture sem branch pbi/"
if grep -q 'no-new-criteria' "$D/docs/reviews/PBI-3-gate.md" 2>/dev/null; then
  pass "escape --no-new-criteria registrado em PBI-3-gate.md"
else
  fail "escape --no-new-criteria NÃO registrado em PBI-3-gate.md"
fi

# G2 BLOCKED: reprova por padrão; --allow-blocked "<motivo>" é o escape explícito
D="$TMP/blocked"; mk_base_repo "$D"
green_gates PBI-30 slug-30
printf 'R1.1 - PASS - ok\nR1.2 - BLOCKED - sem ambiente IIS local\n' > "docs/reviews/PBI-30-verify.md"
printf 'G5: PASS\n' > "$TMP/g5-30.log"
expect_exit 1 "G2 com BLOCKED sem --allow-blocked -> exit 1" -- \
  bash "$SCRIPT" PBI-30 slug-30 --repo "$D" --test-cmd "true" --g5-log "$TMP/g5-30.log"
expect_exit 0 "G2 com BLOCKED e --allow-blocked -> exit 0" -- \
  bash "$SCRIPT" PBI-30 slug-30 --repo "$D" --test-cmd "true" --g5-log "$TMP/g5-30.log" --allow-blocked "legado sem ambiente de smoke (IIS)" --allow-missing-branch "fixture sem branch pbi/"
printf 'R1.1 - FAIL - quebrou\n' > "docs/reviews/PBI-30-verify.md"
expect_exit 1 "G2 com FAIL reprova mesmo com --allow-blocked" -- \
  bash "$SCRIPT" PBI-30 slug-30 --repo "$D" --test-cmd "true" --g5-log "$TMP/g5-30.log" --allow-blocked "x"

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
  bash "$SCRIPT" PBI-7 slug-7 --repo "$D" --test-cmd "true" --skip-g5 "sem ambiente de integração disponível" --allow-missing-branch "fixture sem branch pbi/"

# gate.md de escape é IDEMPOTENTE: rodar 3x não empilha 3 blocos
bash "$SCRIPT" PBI-7 slug-7 --repo "$D" --test-cmd "true" --skip-g5 "motivo" --allow-missing-branch "fixture" >/dev/null 2>&1
bash "$SCRIPT" PBI-7 slug-7 --repo "$D" --test-cmd "true" --skip-g5 "motivo" --allow-missing-branch "fixture" >/dev/null 2>&1
BLOCOS="$(grep -c '^<!-- check-gates:escapes -->' "$D/docs/reviews/PBI-7-gate.md" 2>/dev/null || echo 0)"
if [ "$BLOCOS" -eq 1 ]; then pass "--skip-g5 repetido: gate.md com 1 bloco de escapes (idempotente)"
else fail "--skip-g5 repetido: esperado 1 bloco em gate.md, veio $BLOCOS"; fi

# gates reprovados NÃO gravam bloco de escape (escape de execução reprovada não é escape)
D="$TMP/skip-rejeitado"; mk_base_repo "$D"
green_gates PBI-31 slug-31
rm "docs/reviews/PBI-31-code.md"
bash "$SCRIPT" PBI-31 slug-31 --repo "$D" --test-cmd "true" --skip-g5 "motivo" >/dev/null 2>&1
if grep -q '^<!-- check-gates:escapes -->' "$D/docs/reviews/PBI-31-gate.md" 2>/dev/null; then
  fail "gates reprovados gravaram bloco de escape em gate.md (não deviam)"
else pass "gates reprovados: sem bloco de escape em gate.md"; fi

# reset-counter: zera o contador e grava marco em .last-audit
D="$TMP/reset-counter"; mk_base_repo "$D"
echo 7 > "$D/docs/reviews/.merge-count"
expect_exit 0 "reset-counter -> exit 0" -- bash "$SCRIPT" reset-counter --repo "$D"
if [ "$(cat "$D/docs/reviews/.merge-count")" = "0" ] && [ -s "$D/docs/reviews/.last-audit" ]; then
  pass "reset-counter zerou .merge-count e gravou .last-audit (data+SHA)"
else fail "reset-counter não zerou/gravou marco"; fi

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
  bash "$SCRIPT" PBI-9 slug-9 --repo "$D" --test-cmd "true" --g5-log "$TMP/g5-9.log" --allow-missing-branch "fixture sem branch pbi/"

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

# 4c. sem branch pbi/<ID> nenhuma -> cai no cwd, mas B2 sem branch agora REPROVA
# por default (antes era pulado em silêncio — aprovação sem vínculo); o uso
# manual/exemplo declara com --allow-missing-branch e fica registrado no gate.md
D="$TMP/no-pbi-branch"; mk_base_repo "$D"
green_gates PBI-23 slug-23
printf 'G5: PASS\n' > "$TMP/g5-23.log"
expect_exit 1 "sem branch pbi/<ID> e SEM --allow-missing-branch -> exit 1 (fuga silenciosa do B2 fechada)" -- \
  bash -c "cd '$D' && bash '$SCRIPT' PBI-23 slug-23 --test-cmd true --g5-log '$TMP/g5-23.log'"
expect_exit 0 "sem branch pbi/<ID> COM --allow-missing-branch -> exit 0 (escape explícito)" -- \
  bash -c "cd '$D' && bash '$SCRIPT' PBI-23 slug-23 --test-cmd true --g5-log '$TMP/g5-23.log' --allow-missing-branch 'uso manual sem worktree'"
if grep -q 'allow-missing-branch' "$D/docs/reviews/PBI-23-gate.md" 2>/dev/null; then
  pass "escape --allow-missing-branch registrado em PBI-23-gate.md"
else
  fail "escape --allow-missing-branch NÃO registrado em PBI-23-gate.md"
fi
expect_exit 2 "--track com valor desconhecido -> exit 2 (vocabulário validado, typo não vira trilho feature mudo)" -- \
  bash -c "cd '$D' && bash '$SCRIPT' PBI-23 slug-23 --test-cmd true --track spec-completa"

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
bash "$SCRIPT" PBI-25 slug-25 --repo "$D" --test-cmd true --g5-log "$TMP/g5-25.log" --allow-missing-branch "fixture" >/dev/null
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

# =========================================================================
# 9) ledger sobrevive ao worktree — gravado no repo PRINCIPAL (mesma regra do
#    bump-counter, I4): antes era escrito no worktree do PBI, que 'worktree.sh
#    finish' apaga — o dado de auto-avaliação do processo nunca sobrevivia.
# =========================================================================
D="$TMP/ledger-wt"; mk_base_repo "$D"
WTL="$TMP/wt-PBI-40"
git -C "$D" worktree add -q -b pbi/PBI-40 "$WTL" main >/dev/null 2>&1
mkdir -p "$WTL/docs/reviews" "$WTL/docs/tests-spec"
( cd "$WTL" && green_gates PBI-40 slug-40 )
SHA40="$(git -C "$D" rev-parse pbi/PBI-40)"
printf 'G5: PASS\nCommit: %s\n' "$SHA40" > "$TMP/g5-40.log"
bash -c "cd '$D' && bash '$SCRIPT' PBI-40 slug-40 --test-cmd true --g5-log '$TMP/g5-40.log'" >/dev/null
if [ -f "$D/docs/reviews/.gate-ledger" ] && grep -q 'PBI-40' "$D/docs/reviews/.gate-ledger"; then
  pass "ledger gravado no repo PRINCIPAL (sobrevive ao finish do worktree)"
else
  fail "ledger não foi gravado no repo principal"
fi
N=$((N+1))
[ ! -f "$WTL/docs/reviews/.gate-ledger" ] && pass "ledger NÃO gravado no worktree efêmero" \
  || fail "ledger gravado no worktree por engano (seria apagado pelo finish)"
N=$((N+1))

# =========================================================================
# 10) G1b em worktree recém-criado — docs/reviews/ não vem no worktree (git não
#     versiona dir vazio); sem o mkdir antes do redirect do log, a suíte VERDE
#     era reportada como "G1b suíte FALHOU" (diagnóstico enganoso)
# =========================================================================
D="$TMP/g1b-fresh"; mk_base_repo "$D"
mkdir -p docs/tests-spec; echo "# tests spec" > docs/tests-spec/slug-41.md
git add -A; git commit -qm "spec de testes"
WTF="$TMP/wt-PBI-41"
git -C "$D" worktree add -q -b pbi/PBI-41 "$WTF" main >/dev/null 2>&1
[ ! -d "$WTF/docs/reviews" ] || rmdir "$WTF/docs/reviews" 2>/dev/null
OUT41="$(cd "$D" && bash "$SCRIPT" PBI-41 slug-41 --test-cmd true 2>&1)"
if printf '%s' "$OUT41" | grep -q 'G1b suíte executada VERDE'; then
  pass "G1b verde em worktree sem docs/reviews/ pré-existente"
else
  fail "G1b reportou falha falsa em worktree recém-criado — saída:"$'\n'"$OUT41"
fi
N=$((N+1))

# =========================================================================
# 11) paths com espaço — 'git worktree list --porcelain' + awk \$2 truncava no
#     primeiro token ('C:/Users/Nome Sobrenome/...' é a norma no Windows)
# =========================================================================
D="$TMP/space dir/repo"; mk_base_repo "$D"
WTS="$TMP/space dir/wt PBI-42"
git -C "$D" worktree add -q -b pbi/PBI-42 "$WTS" main >/dev/null 2>&1
mkdir -p "$WTS/docs/reviews" "$WTS/docs/tests-spec"
( cd "$WTS" && green_gates PBI-42 slug-42 )
SHA42="$(git -C "$D" rev-parse pbi/PBI-42)"
printf 'G5: PASS\nCommit: %s\n' "$SHA42" > "$TMP/g5-42.log"
expect_exit 0 "worktree com espaço no path resolve e passa -> exit 0" -- \
  bash -c "cd '$D' && bash '$SCRIPT' PBI-42 slug-42 --test-cmd true --g5-log '$TMP/g5-42.log'"

# =========================================================================
# 12) G0 — recomendado, NÃO bloqueante (vira bloqueante na 2.0): sem
#     spec-draft aprovado o exit continua 0, mas o aviso ⚠ precisa aparecer;
#     com draft APROVADO, o ✔ de G0 aparece. Único gate que não tinha teste.
# =========================================================================
D="$TMP/g0"; mk_base_repo "$D"
green_gates PBI-50 slug-50
printf 'G5: PASS\n' > "$TMP/g5-50.log"
OUT50="$(bash "$SCRIPT" PBI-50 slug-50 --repo "$D" --test-cmd true --g5-log "$TMP/g5-50.log" --allow-missing-branch "fixture" 2>&1)"; RC50=$?
if [ "$RC50" -eq 0 ] && printf '%s' "$OUT50" | grep -q 'G0 ausente'; then
  pass "G0 ausente: avisa (⚠) mas não bloqueia (exit 0)"
else
  fail "G0 ausente: esperado exit 0 + aviso 'G0 ausente' (exit $RC50) — saída:"$'\n'"$OUT50"
fi
N=$((N+1))
printf 'Veredicto: APROVADO\n' > "$D/docs/reviews/PBI-50-spec-draft.md"
OUT50B="$(bash "$SCRIPT" PBI-50 slug-50 --repo "$D" --test-cmd true --g5-log "$TMP/g5-50.log" --allow-missing-branch "fixture" 2>&1)"
if printf '%s' "$OUT50B" | grep -q 'G0 spec revisada'; then
  pass "G0 com spec-draft APROVADO: reconhecido (✔)"
else
  fail "G0 com draft aprovado não reconhecido — saída:"$'\n'"$OUT50B"
fi
N=$((N+1))
OUT50C="$(bash "$SCRIPT" PBI-50 slug-50 --repo "$D" --track manutencao --test-cmd true --g5-log "$TMP/g5-50.log" --allow-missing-branch "fixture" 2>&1)"
if printf '%s' "$OUT50C" | grep -q 'G0'; then
  fail "G0 não deveria ser avaliado no trilho manutenção — saída:"$'\n'"$OUT50C"
else
  pass "G0 só é avaliado no trilho feature (manutenção não menciona G0)"
fi
N=$((N+1))

echo
echo "TOTAL: $N verificações"
[ $FAIL -eq 0 ] && { echo "TEST-CHECK-GATES: OK"; exit 0; } || { echo "TEST-CHECK-GATES: FALHOU"; exit 1; }
