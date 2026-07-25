#!/usr/bin/env bash
# test-examples.sh — os exemplos são fixtures EXECUTÁVEIS e suas promessas são
# verificadas aqui (antes, o comando prometido no README do PBI-EXEMPLO não era
# rodado por nada — e o próprio fixture já esteve quebrado sem ninguém notar).
# 1) PBI-EXEMPLO: o comando do README termina com "GATES OK" e exit 0.
# 2) PBI-FEATURE: rastreabilidade tripla — todo R#.# do requirements aparece no
#    'Cobre:' de algum contrato do design E na tabela do tests-spec.
# exit 0 = tudo bateu com o esperado.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
FAIL=0; N=0
pass(){ N=$((N+1)); printf '  ✔ %s\n' "$1"; }
fail(){ N=$((N+1)); printf '  ✘ %s\n' "$1"; FAIL=1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# =========================================================================
# 1) PBI-EXEMPLO — o comando prometido no README, numa cópia (não sujar o repo)
# =========================================================================
cp -r "$ROOT/examples/PBI-EXEMPLO" "$TMP/ex"
OUT="$(cd "$TMP/ex" && bash "$ROOT/skills/merge-gate/scripts/check-gates.sh" PBI-EXEMPLO exemplo-desconto \
  --repo . --track manutencao --test-cmd true \
  --skip-g5 "exemplo ilustrativo — sem branch/merge real pra simular regressão" 2>&1)"
RC=$?
if [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -q "GATES OK"; then
  pass "PBI-EXEMPLO: comando do README termina em GATES OK (exit 0)"
else
  fail "PBI-EXEMPLO: promessa do README quebrada (exit $RC) — saída:"$'\n'"$OUT"
fi

# e a promessa inversa: sem a evidência do G4, reprova
rm "$TMP/ex/docs/reviews/PBI-EXEMPLO-code.md"
( cd "$TMP/ex" && bash "$ROOT/skills/merge-gate/scripts/check-gates.sh" PBI-EXEMPLO exemplo-desconto \
  --repo . --track manutencao --test-cmd true --skip-g5 "x" ) >/dev/null 2>&1
if [ $? -eq 1 ]; then pass "PBI-EXEMPLO: sem PBI-EXEMPLO-code.md reprova (exit 1), como o README ensina"
else fail "PBI-EXEMPLO: deveria reprovar sem a evidência do G4"; fi

# =========================================================================
# 2) PBI-FEATURE — rastreabilidade tripla por R#.#
# =========================================================================
FT="$ROOT/examples/PBI-FEATURE"
REQ="$FT/.kiro/specs/exportar-extrato/requirements.md"
DES="$FT/.kiro/specs/exportar-extrato/design.md"
TSP="$FT/docs/tests-spec/exportar-extrato.md"
MISS=0
while IFS= read -r r; do
  grep -E "^Cobre:|Cobre:" "$DES" | grep -q "$r" || { fail "PBI-FEATURE: $r do requirements sem 'Cobre:' no design"; MISS=1; }
  grep -q "$r" "$TSP" || { fail "PBI-FEATURE: $r do requirements ausente do tests-spec"; MISS=1; }
done < <(grep -oE 'R[0-9]+\.[0-9]+' "$REQ" | sort -u)
[ "$MISS" -eq 0 ] && pass "PBI-FEATURE: todo R#.# do requirements coberto no design (Cobre:) e no tests-spec"

echo
if [ "$FAIL" -eq 0 ]; then echo "TEST-EXAMPLES: OK ($N caso(s))"; exit 0
else echo "TEST-EXAMPLES: FALHOU"; exit 1; fi
