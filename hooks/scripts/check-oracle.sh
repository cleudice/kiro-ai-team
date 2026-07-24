#!/usr/bin/env bash
# check-oracle.sh — linter determinístico contra steering/guidelines/oracle.md,
# rodado pelo hook format-oracle (PostFileSave em .sql). Substitui a versão antiga
# que disparava um agente inteiro pra reler a guideline a cada save (M3) — isto é
# um mini-review, não o G4; grep não substitui julgamento, só pega os padrões óbvios
# e baratos de detectar.
#
# O contrato exato de como o Kiro repassa o arquivo salvo pra um action.type=command
# não é documentado publicamente no momento em que este script foi escrito. Por isso
# ele NÃO depende de um único mecanismo: tenta, nesta ordem, $1, $KIRO_FILE_PATH e,
# na ausência dos dois, cai para os .sql com mudança não commitada no git (staged +
# working tree) — o que funciona independente de qual for o contrato real do hook.
set -uo pipefail
FAIL=0
warn(){ printf '  ⚠ %s\n' "$1"; FAIL=1; }

check_one() {
  local f="$1"
  [ -f "$f" ] || return 0
  grep -qiE 'WHEN[[:space:]]+OTHERS[[:space:]]+THEN[[:space:]]+NULL' "$f" && \
    warn "$f: 'WHEN OTHERS THEN NULL' — tratamento de exceção explícito é obrigatório (guidelines/oracle.md)"
  if grep -qiE '\b(DDL|DROP|ALTER|CREATE)\b' "$f" 2>/dev/null; then
    local dir base; dir="$(dirname "$f")"; base="$(basename "$f" .sql)"
    ls "$dir/${base}"*rollback* >/dev/null 2>&1 || ls "$dir"/rollback*"${base}"* >/dev/null 2>&1 || \
      warn "$f: parece DDL/alteração de schema sem script de rollback ao lado (convenção: <nome>.rollback.sql) — confirme se existe em outro caminho"
  fi
  # I7: restrito a arquivos que já denunciam SQL DINÂMICO (EXECUTE IMMEDIATE /
  # cursor aberto por string / DBMS_SQL) E têm uma linha de fato concatenando
  # '||' com aspa (em qualquer ordem: `'literal' || var` ou `var || 'literal'`)
  # — a versão anterior disparava em QUALQUER '||' perto de aspas, o que é falso
  # positivo garantido (concatenação de string pura é rotina em PL/SQL comum).
  if grep -qiE "(EXECUTE[[:space:]]+IMMEDIATE|OPEN[[:space:]].*[[:space:]]FOR|DBMS_SQL)" "$f" 2>/dev/null \
     && grep -E "\\|\\|" "$f" 2>/dev/null | grep -qE "'"; then
    warn "$f: SQL dinâmico (EXECUTE IMMEDIATE/OPEN...FOR/DBMS_SQL) com concatenação '||' e aspa — confira bind variable em vez de string concatenada"
  fi
}

if [ -n "${1:-}" ] && [ -f "${1:-}" ]; then
  check_one "$1"
elif [ -n "${KIRO_FILE_PATH:-}" ] && [ -f "$KIRO_FILE_PATH" ]; then
  check_one "$KIRO_FILE_PATH"
elif git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  while IFS= read -r f; do check_one "$f"; done < <(
    { git diff --name-only -- '*.sql'; git diff --cached --name-only -- '*.sql'; git ls-files --others --exclude-standard -- '*.sql'; } | sort -u
  )
fi

[ $FAIL -eq 1 ] && exit 1 || exit 0
