#!/usr/bin/env bash
# task-checkpoint.sh — build+testes determinísticos após cada task de tasks.md
# marcada [x] pelo "Start task" nativo (trigger PostTaskExec). Convertido de
# action.type=agent pra command (mesma racional do I5 nos format-*): "rode o
# build e os testes do tech.md" é determinístico — não precisa de um turno de
# modelo inteiro por task concluída (rodava dezenas de vezes por PBI).
# Só reporta em falha; verde = uma linha de confirmação. Nunca corrige código —
# checkpoint, não implementação; falha é escalação pro dev-* dono da task.
set -uo pipefail
. "$(dirname "$0")/lib.sh"
cd_repo_root
TECH=".kiro/steering/tech.md"
[ -f "$TECH" ] || { echo "  ℹ task-checkpoint: $TECH não encontrado (cwd não é a raiz do projeto?) — checkpoint pulado"; exit 0; }

# extrai o comando entre crases de uma linha "Build: `cmd`" / "Testes: `cmd`" —
# tolerante ao marcador de lista (-, *, +, ou nenhum): acoplar ao literal '^- '
# quebrava silencioso se o template fosse reformatado.
extract_cmd() {
  grep -m1 -E "^[-*+]?[[:space:]]*$1:" "$TECH" 2>/dev/null | sed -n 's/.*`\([^`]*\)`.*/\1/p'
}

BUILD="$(extract_cmd Build)"
TEST="$(extract_cmd Testes)"
if unfilled "$BUILD" && unfilled "$TEST"; then
  echo "  ✘ task-checkpoint: tech.md sem comando de Build/Testes preenchido (placeholder do template) — preencha steering/tech.md; sem isso o checkpoint (e depois G1b/G5) não roda"
  exit 1
fi

LOG="$(mktemp -t task-checkpoint.XXXXXX)"; trap 'rm -f "$LOG"' EXIT
FAIL=0
if ! unfilled "$BUILD"; then
  if ! bash -c "$BUILD" >"$LOG" 2>&1; then
    echo "  ✘ task-checkpoint: BUILD falhou (\`$BUILD\`) — escalar pro dev-* dono da task (escalation-rules.md). Últimas linhas:"
    tail -20 "$LOG"; FAIL=1
  fi
fi
if [ "$FAIL" -eq 0 ] && ! unfilled "$TEST"; then
  if ! bash -c "$TEST" >"$LOG" 2>&1; then
    echo "  ✘ task-checkpoint: TESTES falharam (\`$TEST\`) — escalar pro dev-* dono da task (escalation-rules.md). Últimas linhas:"
    tail -20 "$LOG"; FAIL=1
  fi
fi
[ "$FAIL" -eq 0 ] && echo "  ✔ task-checkpoint: build/testes verdes"
exit $FAIL
