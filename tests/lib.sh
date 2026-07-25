#!/usr/bin/env bash
# tests/lib.sh — harness comum das suítes (source, não executar). Antes,
# pass/fail/expect_exit viviam copiados 5× (uma cópia por suíte) — mesma classe
# de duplicação que motivou hooks/scripts/lib.sh. Convenção: a suíte inicializa
# FAIL=0; N=0 ANTES de sourcear; as funções só mexem nesses globais.

pass(){ N=$((N+1)); printf '  ✔ %s\n' "$1"; }
# shellcheck disable=SC2034  # FAIL é global da suíte que sourceia (inicializado lá)
fail(){ N=$((N+1)); printf '  ✘ %s\n' "$1"; FAIL=1; }

# expect_exit <esperado> <descrição> -- <comando...>
expect_exit() {
  local want="$1" desc="$2"; shift 2
  [ "$1" = "--" ] && shift
  local out; out="$("$@" 2>&1)"; local got=$?
  if [ "$got" -eq "$want" ]; then pass "$desc (exit $got)"
  else fail "$desc (esperado exit $want, veio $got) — saída:"$'\n'"$out"; fi
}

assert_exists() { [ -e "$1" ] && pass "existe: $1" || fail "ausente: $1"; }
assert_absent() { [ -e "$1" ] && fail "não deveria existir: $1" || pass "ausente (correto): $1"; }
