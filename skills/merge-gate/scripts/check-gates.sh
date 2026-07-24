#!/usr/bin/env bash
# check-gates.sh — verificação DETERMINÍSTICA dos gates (exit 0 = pode mesclar)
# uso:
#   check-gates.sh <PBI-ID> <slug> [--test-cmd "cmd"] [--repo <dir>] [--track manutencao] [--g5-log <arquivo>] [--skip-g5 "<motivo>"]
#   check-gates.sh bump-counter [--repo <dir>]     # rodar APÓS o merge efetivo
#
# --repo <dir>: se omitido, o script tenta resolver sozinho o worktree do PBI —
#   procura um worktree registrado (`git worktree list`) para a branch `pbi/<PBI-ID>`
#   e roda os gates LÁ, nunca no diretório corrente por acidente. Se a branch existir
#   mas não houver worktree registrado, reprova cedo (o trabalho pode estar solto/errado).
#   Sem branch `pbi/<PBI-ID>` nenhuma, cai no diretório corrente (uso manual/simples).
#
# --g5-log <arquivo>: caminho de um log com a linha-âncora 'G5: PASS' (produzido pelo
#   orchestrator após 'git merge --no-commit --no-ff pbi/<ID> && <test-cmd> ; git merge --abort').
#   G5 é BLOQUEANTE por padrão: sem --g5-log (e sem --skip-g5), o exit code reprova.
# --skip-g5 "<motivo>": escape explícito e registrado — grava o motivo em
#   docs/reviews/<PBI>-gate.md e libera o exit code sem regressão de integração.
#
# Vínculo evidência↔commit (B2): G2/G3/G4 e o log de G5 exigem uma linha-âncora
# 'Commit: <sha>' que precisa ser (prefixo de) o HEAD atual da branch pbi/<PBI-ID>.
# Sem isso, aprovar em um commit e commitar mais código depois no mesmo PBI passava
# no gate sem que nada tivesse revisado o código novo — a evidência era atemporal.
# Sem branch pbi/<PBI-ID> resolvível (uso manual/exemplo), a checagem é pulada.
set -uo pipefail
REPO=""; TESTCMD=""; TRACK="feature"; G5LOG=""; SKIPG5=""
if [ "${1:-}" = "bump-counter" ]; then MODE=counter; shift; else MODE=check; PBI="${1:?PBI-ID}"; SLUG="${2:?slug}"; shift 2; fi
while [ $# -gt 0 ]; do case "$1" in
  --repo) REPO="$2"; shift 2;; --test-cmd) TESTCMD="$2"; shift 2;; --track) TRACK="$2"; shift 2;;
  --g5-log) G5LOG="$2"; shift 2;; --skip-g5) SKIPG5="$2"; shift 2;;
  *) echo "arg desconhecido: $1"; exit 2;; esac; done
FAIL=0
ok(){ printf '  ✔ %s\n' "$1"; }; bad(){ printf '  ✘ %s\n' "$1"; FAIL=1; }

if [ "$MODE" = "counter" ]; then
  # I4: sem --repo, resolve o REPO PRINCIPAL (não o cwd) — bump-counter roda
  # depois do merge efetivo, tipicamente ainda de dentro do worktree do PBI que
  # 'worktree.sh finish' está prestes a apagar; gravar o contador lá o perderia.
  # 'git worktree list --porcelain' lista o repo principal como primeiro bloco.
  if [ -z "$REPO" ] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    REPO="$(git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2; exit}')"
    [ -n "$REPO" ] && echo "  ℹ --repo não informado — usando repo principal: $REPO"
  fi
  cd "${REPO:-.}"; R="docs/reviews"
  mkdir -p "$R"; C=$(( $(cat "$R/.merge-count" 2>/dev/null || echo 0) + 1 )); echo "$C" > "$R/.merge-count"
  echo "merges desde a última auditoria: $C"
  if [ "$C" -ge 5 ]; then echo "⚠ AUDITORIA DEVIDA: execute audit-integration (auditor) e zere com: echo 0 > $R/.merge-count"; fi
  exit 0
fi

# ---- resolução de --repo: worktree do PBI, nunca o cwd por acidente (B3) --------
if [ -z "$REPO" ]; then
  BRANCH="pbi/$PBI"
  WT_PATH=""
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # git worktree list --porcelain: blocos separados por linha em branco,
    # cada bloco tem "worktree <path>" seguido (eventualmente) de "branch refs/heads/<nome>"
    WT_PATH="$(git worktree list --porcelain 2>/dev/null | awk -v b="refs/heads/$BRANCH" '
      /^worktree /{p=$2} /^branch /{if ($2==b) print p}')"
  fi
  if [ -n "$WT_PATH" ]; then
    REPO="$WT_PATH"
    echo "  ℹ --repo não informado — usando worktree de $BRANCH: $REPO"
  elif git show-ref --verify --quiet "refs/heads/$BRANCH" 2>/dev/null; then
    echo "✘ branch $BRANCH existe mas não tem worktree registrado (git worktree list) — rode '.kiro/scripts/worktree.sh start $PBI' ou passe --repo explicitamente. Nunca rodar os gates fora do worktree do PBI (o trabalho pode estar solto/errado)." >&2
    exit 1
  else
    REPO="."
    echo "  ℹ sem branch $BRANCH — rodando no diretório corrente (uso manual/sem worktree)"
  fi
fi
cd "$REPO"; R="docs/reviews"

# ---- SHA da branch pbi/<PBI-ID>, pra amarrar evidência a commit (B2) -----------
# SHA usado na comparação é o commit de CÓDIGO mais recente na branch, não o HEAD
# literal: um commit que só toca docs/reviews/** ou docs/tests-spec/** (a própria
# evidência, ou o log de G5, sendo commitados DEPOIS da revisão — necessário pra
# 'worktree.sh finish' aceitar remover o worktree, ver quality-gates.md) não conta
# como "código novo" e não invalida o vínculo. Só um commit que toca algo FORA
# desses dois caminhos avança o SHA de referência.
BRANCH_SHA="$(git rev-parse --verify -q "refs/heads/pbi/$PBI" 2>/dev/null || true)"
if [ -n "$BRANCH_SHA" ]; then
  SHA="$(git log -1 --format=%H "$BRANCH_SHA" -- . ':!docs/reviews' ':!docs/tests-spec' 2>/dev/null || true)"
  [ -z "$SHA" ] && SHA="$BRANCH_SHA"
else
  SHA=""
  echo "  ℹ branch pbi/$PBI não resolvida — checagem de vínculo evidência↔commit (linha 'Commit: <sha>') pulada (uso manual/exemplo)"
fi
# assert_commit <arquivo> <label> — exige 'Commit: <sha>' cujo valor seja prefixo
# do último commit de CÓDIGO em pbi/<PBI-ID> ($SHA acima). Sem $SHA (checagem
# pulada acima), sempre passa.
assert_commit() {
  local f="$1" label="$2" line commit
  [ -z "$SHA" ] && return 0
  line="$(grep -m1 -E '^Commit: *[0-9a-fA-F]{7,40}' "$f" 2>/dev/null || true)"
  if [ -z "$line" ]; then
    bad "$label sem linha-âncora 'Commit: <sha>' em $f — evidência não amarrada ao commit revisado"
    return 1
  fi
  commit="$(printf '%s' "$line" | grep -oE '[0-9a-fA-F]{7,40}')"
  case "$SHA" in
    "$commit"*) return 0;;
    *) bad "$label: evidência gravada em commit $commit, mas pbi/$PBI está em $SHA — refazer $label sobre o commit atual"; return 1;;
  esac
}

# M5 — tech.md sem comando de teste preenchido (placeholder do template não editado)
# chega aqui como --test-cmd vazio ou literalmente contendo "..." — falha cedo e
# claro em vez de deixar G1b/G5 fracassarem de um jeito confuso mais adiante.
unfilled_cmd() { local c="$1"; [ -z "$(printf '%s' "$c" | tr -d '[:space:]')" ] && return 0; case "$c" in *'...'*) return 0;; esac; return 1; }
if [ -n "$TESTCMD" ] && unfilled_cmd "$TESTCMD"; then
  bad "--test-cmd recebido mas parece placeholder não preenchido ('$TESTCMD') — confira steering/tech.md (campo Testes: \`...\`) antes de rodar os gates"
fi

echo "check-gates PBI=$PBI slug=$SLUG track=$TRACK"
G1S=FAIL; G2S=FAIL; G3S=FAIL; G4S=FAIL; G5S=FAIL
# G1 — testes black-box
if [ "$TRACK" = "manutencao" ] && [ ! -f "docs/tests-spec/$SLUG.md" ]; then
  ok "G1 dispensado (manutenção sem critério novo — sem docs/tests-spec/$SLUG.md)"; G1S=OK
elif [ -f "docs/tests-spec/$SLUG.md" ]; then
  ok "G1a evidência: docs/tests-spec/$SLUG.md"
  if [ -n "$TESTCMD" ] && ! unfilled_cmd "$TESTCMD"; then
    if bash -c "$TESTCMD" > "$R/$PBI-g1-run.log" 2>&1; then ok "G1b suíte executada VERDE (log: $R/$PBI-g1-run.log)"; G1S=OK
    else bad "G1b suíte FALHOU (log: $R/$PBI-g1-run.log)"; fi
  else bad "G1b não executado — passe --test-cmd (comando de Testes do tech.md)"; fi
else bad "G1 sem evidência: docs/tests-spec/$SLUG.md ausente"; fi
# G2 — verify observado (âncora por critério: só linhas "R#.# - PASS|FAIL|BLOCKED" contam — A4)
V="$R/$PBI-verify.md"
if [ ! -f "$V" ]; then bad "G2 ausente: $V"
else
  CRIT_LINES="$(grep -cE '^R[0-9]+(\.[0-9]+)?[[:space:]]*[-–—][[:space:]]*(PASS|FAIL|BLOCKED)\b' "$V" 2>/dev/null || true)"
  BAD_LINES="$(grep -cE '^R[0-9]+(\.[0-9]+)?[[:space:]]*[-–—][[:space:]]*(FAIL|BLOCKED)\b' "$V" 2>/dev/null || true)"
  if [ "${CRIT_LINES:-0}" -eq 0 ]; then bad "G2 sem linha de critério reconhecida (formato: 'R#.# - PASS|FAIL|BLOCKED - evidência') em $V"
  elif [ "${BAD_LINES:-0}" -gt 0 ]; then bad "G2 contém FAIL/BLOCKED em linha de critério de $V"
  elif ! assert_commit "$V" "G2"; then :
  else ok "G2 verify: $CRIT_LINES critério(s), todos PASS (commit ok)"; G2S=OK; fi
fi
# G3/G4 — reviews (exige a linha-âncora "Veredicto: APROVADO|REPROVADO" — não vasculha o corpo do texto)
for g in spec:G3 code:G4; do f="$R/$PBI-${g%%:*}.md"; tag="${g##*:}"
  if [ ! -f "$f" ]; then bad "$tag ausente: $f"
  elif grep -qE '^Veredicto: *REPROVADO' "$f"; then bad "$tag REPROVADO em $f"
  elif grep -qE '^Veredicto: *APROVADO' "$f"; then
    if assert_commit "$f" "$tag"; then ok "$tag APROVADO ($f, commit ok)"; [ "$tag" = G3 ] && G3S=OK || G4S=OK; fi
  else bad "$tag sem linha-âncora 'Veredicto: APROVADO' em $f"; fi
done
# G5 — regressão pós-merge simulado (bloqueante por padrão — B5)
if [ -n "$G5LOG" ]; then
  if [ ! -f "$G5LOG" ]; then bad "G5 ausente: $G5LOG"
  elif grep -qE '^G5: *FAIL' "$G5LOG"; then bad "G5 FAIL em $G5LOG"
  elif grep -qE '^G5: *PASS' "$G5LOG"; then
    if assert_commit "$G5LOG" "G5"; then ok "G5 regressão verde ($G5LOG, commit ok)"; G5S=OK; fi
  else bad "G5 sem linha-âncora 'G5: PASS' em $G5LOG"; fi
elif [ -n "$SKIPG5" ]; then
  ok "G5 dispensado explicitamente — motivo: $SKIPG5"; G5S="SKIP"
  mkdir -p "$R"
  printf '# Merge Gate — %s (%s)\nG5 dispensado via --skip-g5.\nMotivo: %s\n' "$PBI" "$SLUG" "$SKIPG5" >> "$R/$PBI-gate.md"
else
  bad "G5 ausente — sem --g5-log nem --skip-g5. Na branch alvo rode 'git merge --no-commit --no-ff pbi/$PBI' e então a suíte de teste; 'git merge --abort' em seguida. Registre 'G5: PASS'/'G5: FAIL' num log e repasse com --g5-log (ou use --skip-g5 \"<motivo>\" para um escape explícito e registrado)."
fi

# ledger: 1 linha por execução em docs/reviews/.gate-ledger — dado bruto pra decidir
# com números (não opinião) se algum gate custa mais do que pega (contra-estrutural §3).
mkdir -p "$R"
printf '%s PBI=%s slug=%s track=%s G1=%s G2=%s G3=%s G4=%s G5=%s resultado=%s\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$PBI" "$SLUG" "$TRACK" "$G1S" "$G2S" "$G3S" "$G4S" "$G5S" \
  "$([ $FAIL -eq 0 ] && echo OK || echo REPROVADO)" >> "$R/.gate-ledger"

[ $FAIL -eq 0 ] && { echo "RESULTADO: GATES OK — autorizado a mesclar"; exit 0; } \
                || { echo "RESULTADO: GATES REPROVADOS — devolver ao papel dono do gate"; exit 1; }
