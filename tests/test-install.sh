#!/usr/bin/env bash
# test-install.sh — testa install.sh: escopos, --stack, --update (poda real, A1/A2),
# manifesto de versão. exit 0 = tudo bateu com o esperado.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
INSTALL="$ROOT/install.sh"
FAIL=0; N=0

pass(){ N=$((N+1)); printf '  ✔ %s\n' "$1"; }
fail(){ N=$((N+1)); printf '  ✘ %s\n' "$1"; FAIL=1; }
assert_exists() { [ -e "$1" ] && pass "existe: $1" || fail "ausente: $1"; }
assert_absent()  { [ -e "$1" ] && fail "não deveria existir: $1" || pass "ausente (correto): $1"; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# =========================================================================
# 1) instalação --stack dotnet: só o dev do stack + os 6 papéis stack-agnósticos
# =========================================================================
D1="$TMP/proj-dotnet"; mkdir -p "$D1"
bash "$INSTALL" "$D1" --stack dotnet >/tmp/install-out-1.log 2>&1
K1="$D1/.kiro"

assert_exists "$K1/agents/orchestrator.json"
assert_exists "$K1/agents/spec-analyst.json"
assert_exists "$K1/agents/qa-blackbox.json"
assert_exists "$K1/agents/reviewer-spec.json"
assert_exists "$K1/agents/reviewer-code.json"
assert_exists "$K1/agents/auditor.json"
assert_exists "$K1/agents/dev-dotnet.json"
assert_absent  "$K1/agents/dev-webforms.json"
assert_absent  "$K1/agents/dev-flutter.json"

# B1 — o mesmo agente vai em .json (CLI) E .md (IDE); os dois formatos convivem
assert_exists "$K1/agents/orchestrator.md"
assert_exists "$K1/agents/dev-dotnet.md"
assert_absent "$K1/agents/dev-webforms.md"

assert_exists "$K1/steering/escalation-rules.md"
assert_exists "$K1/steering/quality-gates.md"
assert_exists "$K1/steering/workflow.md"
assert_exists "$K1/steering/guidelines/dotnet.md"
assert_exists "$K1/steering/guidelines/oracle.md"

assert_exists "$K1/steering/product.md"
assert_exists "$K1/steering/tech.md"
assert_exists "$K1/steering/structure.md"
assert_exists "$K1/steering/retro-learnings.md"
assert_exists "$D1/AGENTS.md"

assert_exists "$D1/docs/issues"
assert_exists "$D1/docs/reviews"
assert_exists "$D1/docs/context"
assert_exists "$D1/docs/tests-spec"

# .gitignore ganha as entradas de artefatos gerados por check-gates.sh (não a
# evidência em si — só ledger/contador/log de execução)
assert_exists "$D1/.gitignore"
grep -qxF "docs/reviews/.gate-ledger" "$D1/.gitignore" && pass ".gitignore: entrada .gate-ledger" || fail ".gitignore sem entrada .gate-ledger"
N=$((N+1))
grep -qxF "docs/reviews/.merge-count" "$D1/.gitignore" && pass ".gitignore: entrada .merge-count" || fail ".gitignore sem entrada .merge-count"
N=$((N+1))

assert_exists "$K1/.kiro-ai-team-version"
V1="$(cat "$K1/.kiro-ai-team-version" 2>/dev/null | tr -d '[:space:]')"
[ -n "$V1" ] && pass "versão gravada: $V1" || fail "arquivo de versão vazio"

# B1 — worktree.sh (e o resolvedor kiro-paths.sh) precisam ser instalados no
# projeto — antes desta correção, scripts/worktree.sh nunca ia pra lugar nenhum,
# apesar de todo prompt/skill citar ".kiro/scripts/worktree.sh".
assert_exists "$K1/scripts/worktree.sh"
assert_exists "$K1/scripts/kiro-paths.sh"
[ -x "$K1/scripts/worktree.sh" ] || chmod +x "$K1/scripts/worktree.sh" 2>/dev/null
RESOLVED1="$(bash "$K1/scripts/kiro-paths.sh")"
[ "$RESOLVED1" = "$K1" ] && pass "kiro-paths.sh resolve a engine local no escopo project" \
  || fail "kiro-paths.sh resolveu '$RESOLVED1', esperado '$K1'"
N=$((N+1))

# =========================================================================
# 2) install sem --stack: todos os 3 devs presentes (multi = sem podar)
# =========================================================================
D2="$TMP/proj-multi"; mkdir -p "$D2"
bash "$INSTALL" "$D2" >/tmp/install-out-2.log 2>&1
K2="$D2/.kiro"
assert_exists "$K2/agents/dev-dotnet.json"
assert_exists "$K2/agents/dev-webforms.json"
assert_exists "$K2/agents/dev-flutter.json"

# =========================================================================
# 3) --update PODA de verdade (A1): skill que o TIME instalou e saiu do central some
# =========================================================================
D3="$TMP/proj-update"; mkdir -p "$D3"
bash "$INSTALL" "$D3" --stack dotnet >/tmp/install-out-3.log 2>&1
K3="$D3/.kiro"
mkdir -p "$K3/skills/skill-fantasma"
echo "---
name: skill-fantasma
description: skill que não existe mais no central, deveria sumir no update
---
# fantasma" > "$K3/skills/skill-fantasma/SKILL.md"
assert_exists "$K3/skills/skill-fantasma/SKILL.md"
# simula que skill-fantasma FOI instalada por uma versão anterior do time
# (registrada no manifesto) — só assim a poda-por-manifesto (B1) a reconhece
# como "nossa" e a remove; sem isso ela seria tratada como artefato do projeto.
python3 -c "
import json
p = '$K3/.kiro-ai-team-version'
d = json.load(open(p))
d['skills'] = d.get('skills', []) + ['skill-fantasma']
json.dump(d, open(p, 'w'), indent=2)
"

bash "$INSTALL" "$D3" --update >/tmp/install-out-3b.log 2>&1
assert_absent "$K3/skills/skill-fantasma"

# skills reais continuam lá após o update
assert_exists "$K3/skills/merge-gate/SKILL.md"

# =========================================================================
# 3b) B1 — agente/skill PRÓPRIO DO PROJETO (nunca registrado como instalado
#     pelo time) sobrevive ao --update, mesmo sem estar no conjunto atual do
#     central. Antes da correção, o --update convergia o diretório inteiro e
#     apagava isto silenciosamente (contradizia README "a dualidade").
# =========================================================================
echo '{"name":"analista-crash-app-x","description":"agente específico deste projeto, não vem do central"}' \
  > "$K3/agents/analista-crash-app-x.json"
mkdir -p "$K3/skills/skill-do-projeto"
echo "---
name: skill-do-projeto
description: skill própria deste projeto
---
# skill do projeto" > "$K3/skills/skill-do-projeto/SKILL.md"

bash "$INSTALL" "$D3" --update >/tmp/install-out-3c.log 2>&1
assert_exists "$K3/agents/analista-crash-app-x.json"
assert_exists "$K3/skills/skill-do-projeto/SKILL.md"

# --prune-unmanaged restaura o comportamento antigo (converge tudo) — remove os dois
bash "$INSTALL" "$D3" --update --prune-unmanaged >/tmp/install-out-3d.log 2>&1
assert_absent "$K3/agents/analista-crash-app-x.json"
assert_absent "$K3/skills/skill-do-projeto"

# =========================================================================
# 4) --update sem repassar --stack MEMORIZA o stack original (A2)
#    (dev-webforms/flutter não devem aparecer só porque --update rodou sem --stack)
# =========================================================================
bash "$INSTALL" "$D3" --update >/tmp/install-out-3c.log 2>&1
assert_absent "$K3/agents/dev-webforms.json"
assert_absent "$K3/agents/dev-flutter.json"
assert_exists "$K3/agents/dev-dotnet.json"

# =========================================================================
# 5) --scope global: engine em KIRO_HOME isolado, sem exigir DEST
# =========================================================================
KH="$TMP/kiro-home"; mkdir -p "$KH"
bash "$INSTALL" --scope global --kiro-home "$KH" >/tmp/install-out-4.log 2>&1
assert_exists "$KH/agents/orchestrator.json"
assert_exists "$KH/steering/principios.md"
# B1/B3 — escopo global puro também recebe scripts/ (uso standalone, sem camada
# de projeto por perto) e um .kiro-ai-team-paths auto-referente.
assert_exists "$KH/scripts/worktree.sh"
assert_exists "$KH/scripts/kiro-paths.sh"
assert_exists "$KH/.kiro-ai-team-paths"

# =========================================================================
# 5b) B3 — --scope hybrid: engine fica em KIRO_HOME, mas .kiro/scripts/ do
#     projeto resolve pra lá via kiro-paths.sh + .kiro-ai-team-paths. Antes da
#     correção, caminhos ".kiro/..." hardcoded (guard do qa-blackbox,
#     check-gates.sh) quebravam silenciosamente nesse escopo.
# =========================================================================
KH2="$TMP/kiro-home-hybrid"; mkdir -p "$KH2"
DH="$TMP/proj-hybrid"; mkdir -p "$DH"
bash "$INSTALL" "$DH" --scope hybrid --kiro-home "$KH2" --stack dotnet >/tmp/install-out-5b.log 2>&1
KDH="$DH/.kiro"
assert_absent "$KDH/agents"                     # hybrid: sem engine local, evita conflito de nomes
assert_exists "$KDH/scripts/worktree.sh"         # camada fina SEMPRE presente no projeto
assert_exists "$KDH/scripts/kiro-paths.sh"
assert_exists "$KDH/.kiro-ai-team-paths"
assert_exists "$KH2/agents/orchestrator.json"    # engine de verdade mora em KIRO_HOME
RESOLVED_HYBRID="$(bash "$KDH/scripts/kiro-paths.sh")"
[ "$RESOLVED_HYBRID" = "$KH2" ] && pass "kiro-paths.sh (hybrid) resolve pra KIRO_HOME" \
  || fail "kiro-paths.sh (hybrid) resolveu '$RESOLVED_HYBRID', esperado '$KH2'"
N=$((N+1))

# --uninstall no hybrid remove a camada fina do projeto E a engine do KIRO_HOME,
# sem tocar steering/docs do projeto (mesma regra do escopo project)
bash "$INSTALL" "$DH" --scope hybrid --kiro-home "$KH2" --uninstall >/tmp/install-out-5c.log 2>&1
assert_absent "$KDH/scripts/worktree.sh"
assert_absent "$KH2/agents/orchestrator.json"
assert_exists "$KDH/steering/product.md"

# =========================================================================
# 6) --dry-run não escreve nada no disco
# =========================================================================
D5="$TMP/proj-dryrun"; mkdir -p "$D5"
bash "$INSTALL" "$D5" --stack dotnet --dry-run >/tmp/install-out-5.log 2>&1
grep -q '(dry-run)' /tmp/install-out-5.log && pass "dry-run anuncia as ações" || fail "dry-run não anunciou nada"
N=$((N+1))
assert_absent "$D5/.kiro"

# =========================================================================
# 7) --uninstall remove agents/skills, preserva steering do projeto
# =========================================================================
D6="$TMP/proj-uninstall"; mkdir -p "$D6"
bash "$INSTALL" "$D6" --stack dotnet >/tmp/install-out-6.log 2>&1
bash "$INSTALL" "$D6" --uninstall >/tmp/install-out-6b.log 2>&1
assert_absent "$D6/.kiro/agents/orchestrator.json"
assert_absent "$D6/.kiro/skills/merge-gate"
# I5 — scripts/ (worktree.sh, kiro-paths.sh) também sai no uninstall; antes
# desta correção ficavam órfãos (não registrados em manifesto nenhum).
assert_absent "$D6/.kiro/scripts/worktree.sh"
assert_absent "$D6/.kiro/scripts/kiro-paths.sh"
assert_exists "$D6/.kiro/steering/product.md"
assert_exists "$D6/AGENTS.md"

echo
echo "TOTAL: $N verificações"
[ $FAIL -eq 0 ] && { echo "TEST-INSTALL: OK"; exit 0; } || { echo "TEST-INSTALL: FALHOU"; exit 1; }
