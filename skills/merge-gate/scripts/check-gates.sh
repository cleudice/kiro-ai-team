#!/usr/bin/env bash
# check-gates.sh — verificação DETERMINÍSTICA dos gates (exit 0 = pode mesclar)
# uso:
#   check-gates.sh <PBI-ID> <slug> [--test-cmd "cmd"] [--repo <dir>] [--track manutencao] [--g5-log <arquivo>]
#   check-gates.sh bump-counter [--repo <dir>]     # rodar APÓS o merge efetivo
#
# --g5-log <arquivo>: caminho de um log com a linha-âncora 'G5: PASS' (produzido pelo
#   orchestrator após 'git merge --no-commit --no-ff pbi/<ID> && <test-cmd> ; git merge --abort').
#   Sem essa flag, G5 permanece instrucional (não bloqueia o exit code).
set -uo pipefail
REPO="."; TESTCMD=""; TRACK="feature"; G5LOG=""
if [ "${1:-}" = "bump-counter" ]; then MODE=counter; shift; else MODE=check; PBI="${1:?PBI-ID}"; SLUG="${2:?slug}"; shift 2; fi
while [ $# -gt 0 ]; do case "$1" in
  --repo) REPO="$2"; shift 2;; --test-cmd) TESTCMD="$2"; shift 2;; --track) TRACK="$2"; shift 2;;
  --g5-log) G5LOG="$2"; shift 2;;
  *) echo "arg desconhecido: $1"; exit 2;; esac; done
cd "$REPO"; R="docs/reviews"; FAIL=0
ok(){ printf '  ✔ %s\n' "$1"; }; bad(){ printf '  ✘ %s\n' "$1"; FAIL=1; }

if [ "$MODE" = "counter" ]; then
  mkdir -p "$R"; C=$(( $(cat "$R/.merge-count" 2>/dev/null || echo 0) + 1 )); echo "$C" > "$R/.merge-count"
  echo "merges desde a última auditoria: $C"
  if [ "$C" -ge 5 ]; then echo "⚠ AUDITORIA DEVIDA: execute audit-integration (auditor) e zere com: echo 0 > $R/.merge-count"; fi
  exit 0
fi

echo "check-gates PBI=$PBI slug=$SLUG track=$TRACK"
# G1 — testes black-box
if [ "$TRACK" = "manutencao" ] && [ ! -f "docs/tests-spec/$SLUG.md" ]; then
  ok "G1 dispensado (manutenção sem critério novo — sem docs/tests-spec/$SLUG.md)"
elif [ -f "docs/tests-spec/$SLUG.md" ]; then
  ok "G1a evidência: docs/tests-spec/$SLUG.md"
  if [ -n "$TESTCMD" ]; then
    if bash -c "$TESTCMD" > "$R/$PBI-g1-run.log" 2>&1; then ok "G1b suíte executada VERDE (log: $R/$PBI-g1-run.log)"
    else bad "G1b suíte FALHOU (log: $R/$PBI-g1-run.log)"; fi
  else bad "G1b não executado — passe --test-cmd (comando de Testes do tech.md)"; fi
else bad "G1 sem evidência: docs/tests-spec/$SLUG.md ausente"; fi
# G2 — verify observado
V="$R/$PBI-verify.md"
if [ ! -f "$V" ]; then bad "G2 ausente: $V"
elif grep -qE '\b(FAIL|BLOCKED)\b' "$V"; then bad "G2 contém FAIL/BLOCKED em $V"
elif grep -qE '\bPASS\b' "$V"; then ok "G2 verify: só PASS"
else bad "G2 sem veredictos PASS em $V"; fi
# G3/G4 — reviews (exige a linha-âncora "Veredicto: APROVADO|REPROVADO" — não vasculha o corpo do texto)
for g in spec:G3 code:G4; do f="$R/$PBI-${g%%:*}.md"; tag="${g##*:}"
  if [ ! -f "$f" ]; then bad "$tag ausente: $f"
  elif grep -qE '^Veredicto: *REPROVADO' "$f"; then bad "$tag REPROVADO em $f"
  elif grep -qE '^Veredicto: *APROVADO' "$f"; then ok "$tag APROVADO ($f)"
  else bad "$tag sem linha-âncora 'Veredicto: APROVADO' em $f"; fi
done
# G5 — regressão pós-merge simulado
if [ -n "$G5LOG" ]; then
  if [ ! -f "$G5LOG" ]; then bad "G5 ausente: $G5LOG"
  elif grep -qE '^G5: *FAIL' "$G5LOG"; then bad "G5 FAIL em $G5LOG"
  elif grep -qE '^G5: *PASS' "$G5LOG"; then ok "G5 regressão verde ($G5LOG)"
  else bad "G5 sem linha-âncora 'G5: PASS' em $G5LOG"; fi
elif [ -n "$TESTCMD" ]; then
  echo "  ℹ G5: na branch alvo rode 'git merge --no-commit --no-ff pbi/$PBI' e então: $TESTCMD ; git merge --abort — registre 'G5: PASS'/'G5: FAIL' num log e repasse com --g5-log pra virar bloqueante"
else echo "  ℹ G5: simule o merge e rode a suíte completa (comando do tech.md) — registre 'G5: PASS'/'G5: FAIL' num log e repasse com --g5-log pra virar bloqueante"; fi

[ $FAIL -eq 0 ] && { echo "RESULTADO: GATES OK — autorizado a mesclar (após G5 verde)"; exit 0; } \
                || { echo "RESULTADO: GATES REPROVADOS — devolver ao papel dono do gate"; exit 1; }
