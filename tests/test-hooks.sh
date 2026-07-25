#!/usr/bin/env bash
# test-hooks.sh — testes comportamentais dos scripts de hooks/scripts/*.sh.
# Antes eles só passavam por bash -n/shellcheck — e são justamente os scripts
# mais heurísticos do repo (resolução de arquivo por 3 vias, regex de lint,
# guard que falha aberto), todos com histórico de bug no CHANGELOG.
# exit 0 = tudo bateu com o esperado.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
HS="$ROOT/hooks/scripts"
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

# =========================================================================
# check-oracle.sh — verdadeiro-positivo e verdadeiro-negativo por regra
# =========================================================================
D="$TMP/oracle"; mkdir -p "$D"

# package comum com CREATE OR REPLACE: NÃO pode exigir rollback (era o falso
# positivo garantido: todo save de package ficava vermelho)
cat > "$D/pkg_ok.sql" <<'SQL'
CREATE OR REPLACE PACKAGE BODY minha_pkg AS
  PROCEDURE calcula(p_id IN NUMBER) IS
  BEGIN
    UPDATE pedidos SET total = total * 0.9 WHERE id = p_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN RAISE_APPLICATION_ERROR(-20001, 'pedido inexistente');
  END;
END minha_pkg;
SQL
expect_exit 0 "check-oracle: CREATE OR REPLACE PACKAGE sem rollback passa (não é DDL estrutural)" -- bash "$HS/check-oracle.sh" "$D/pkg_ok.sql"

# DDL estrutural sem rollback ao lado: reprova
cat > "$D/migra.sql" <<'SQL'
ALTER TABLE pedidos ADD (desconto NUMBER(5,2));
SQL
expect_exit 1 "check-oracle: ALTER TABLE sem rollback reprova" -- bash "$HS/check-oracle.sh" "$D/migra.sql"

# mesmo DDL com rollback ao lado: passa
cat > "$D/migra.rollback.sql" <<'SQL'
ALTER TABLE pedidos DROP COLUMN desconto;
SQL
expect_exit 0 "check-oracle: ALTER TABLE com <nome>.rollback.sql ao lado passa" -- bash "$HS/check-oracle.sh" "$D/migra.sql"

# WHEN OTHERS THEN NULL: reprova
cat > "$D/swallow.sql" <<'SQL'
BEGIN
  faz_algo;
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
SQL
expect_exit 1 "check-oracle: WHEN OTHERS THEN NULL reprova" -- bash "$HS/check-oracle.sh" "$D/swallow.sql"

# SQL dinâmico com concatenação e aspa: reprova; concatenação de string pura sem
# SQL dinâmico: passa (regra I7)
cat > "$D/dyn.sql" <<'SQL'
BEGIN
  EXECUTE IMMEDIATE 'SELECT * FROM t WHERE nome = ''' || p_nome || '''';
END;
SQL
expect_exit 1 "check-oracle: SQL dinâmico com '||' e aspa reprova" -- bash "$HS/check-oracle.sh" "$D/dyn.sql"
cat > "$D/concat_ok.sql" <<'SQL'
BEGIN
  mensagem := 'Olá, ' || p_nome || '!';
END;
SQL
expect_exit 0 "check-oracle: concatenação de string pura sem SQL dinâmico passa" -- bash "$HS/check-oracle.sh" "$D/concat_ok.sql"

# =========================================================================
# qa-blackbox-guard.sh — bloqueia src/ em payload conhecido; falha ABERTO no resto
# =========================================================================
expect_exit 2 "qa-guard: payload JSON com path em src/ bloqueia (exit 2)" -- \
  bash -c 'printf "%s" "{\"path\": \"src/servico/calc.cs\"}" | bash "$1"' _ "$HS/qa-blackbox-guard.sh"
expect_exit 2 "qa-guard: payload JSON aninhado (input.file_path) em src/ bloqueia" -- \
  bash -c 'printf "%s" "{\"input\": {\"file_path\": \"repo/src/a.dart\"}}" | bash "$1"' _ "$HS/qa-blackbox-guard.sh"
expect_exit 0 "qa-guard: payload JSON com path fora de src/ passa" -- \
  bash -c 'printf "%s" "{\"path\": \"docs/tests-spec/x.md\"}" | bash "$1"' _ "$HS/qa-blackbox-guard.sh"
expect_exit 0 "qa-guard: payload irreconhecível falha ABERTO (exit 0), como documentado" -- \
  bash -c 'printf "%s" "formato-desconhecido sem chave alguma" | bash "$1"' _ "$HS/qa-blackbox-guard.sh"
expect_exit 2 "qa-guard: payload não-JSON mas com caminho src/ visível bloqueia (fallback grep)" -- \
  bash -c 'printf "%s" "tool=fs_read arquivo=projeto/src/Program.cs" | bash "$1"' _ "$HS/qa-blackbox-guard.sh"
expect_exit 0 "qa-guard: stdin vazio falha ABERTO" -- \
  bash -c ': | bash "$1"' _ "$HS/qa-blackbox-guard.sh"

# =========================================================================
# readonly-guard.sh — mesmo contrato do qa-guard, mirando ESCRITA
# =========================================================================
expect_exit 2 "readonly-guard: payload com path em src/ bloqueia" -- \
  bash -c 'printf "%s" "{\"file_path\": \"src/app/main.dart\"}" | bash "$1"' _ "$HS/readonly-guard.sh"
expect_exit 0 "readonly-guard: escrita em docs/reviews/ passa" -- \
  bash -c 'printf "%s" "{\"file_path\": \"docs/reviews/PBI-1-code.md\"}" | bash "$1"' _ "$HS/readonly-guard.sh"
expect_exit 0 "readonly-guard: payload irreconhecível falha ABERTO" -- \
  bash -c 'printf "%s" "???" | bash "$1"' _ "$HS/readonly-guard.sh"

# =========================================================================
# task-checkpoint.sh — placeholder do tech.md × comandos reais
# =========================================================================
mk_proj() {  # $1 = dir; $2 = conteúdo do tech.md
  mkdir -p "$1/.kiro/steering"
  printf '%s\n' "$2" > "$1/.kiro/steering/tech.md"
  git -C "$1" init -q -b main 2>/dev/null || true
}
P1="$TMP/proj-placeholder"; mk_proj "$P1" '- Build: `...`
- Testes: `...`'
expect_exit 1 "task-checkpoint: tech.md placeholder reprova com mensagem clara" -- \
  bash -c 'cd "$1" && bash "$2"' _ "$P1" "$HS/task-checkpoint.sh"

P2="$TMP/proj-verde"; mk_proj "$P2" '- Build: `true`
- Testes: `true`'
expect_exit 0 "task-checkpoint: build/testes verdes passam" -- \
  bash -c 'cd "$1" && bash "$2"' _ "$P2" "$HS/task-checkpoint.sh"

P3="$TMP/proj-quebrado"; mk_proj "$P3" '- Build: `false`
- Testes: `true`'
expect_exit 1 "task-checkpoint: build quebrado reprova" -- \
  bash -c 'cd "$1" && bash "$2"' _ "$P3" "$HS/task-checkpoint.sh"

# tolerância a marcador de lista diferente do template ('- ' → '* ')
P4="$TMP/proj-asterisco"; mk_proj "$P4" '* Build: `true`
* Testes: `true`'
expect_exit 0 "task-checkpoint: tech.md com bullet '*' em vez de '-' ainda resolve" -- \
  bash -c 'cd "$1" && bash "$2"' _ "$P4" "$HS/task-checkpoint.sh"

P5="$TMP/proj-sem-tech"; mkdir -p "$P5"; git -C "$P5" init -q -b main
expect_exit 0 "task-checkpoint: sem tech.md pula com aviso (não falha o hook)" -- \
  bash -c 'cd "$1" && bash "$2"' _ "$P5" "$HS/task-checkpoint.sh"

# =========================================================================
# preflight-branch.sh — avisa só com task pendente E branch fora de pbi/*
# =========================================================================
B="$TMP/preflight"; mkdir -p "$B/.kiro/specs/slug-x"; cd "$B" || exit 1
git init -q -b main; git config user.email t@t.com; git config user.name t
echo x > f; git add -A; git commit -qm init
printf -- '- [ ] task pendente (dev-dotnet)\n' > .kiro/specs/slug-x/tasks.md
git add -A; git commit -qm spec
OUT="$(bash "$HS/preflight-branch.sh")"
case "$OUT" in *"⚠"*) pass "preflight: task pendente + branch main = avisa";; *) fail "preflight: deveria avisar em main com task pendente — saída: $OUT";; esac
git checkout -qb pbi/slug-x
OUT="$(bash "$HS/preflight-branch.sh")"
case "$OUT" in *"confirmado"*) pass "preflight: em pbi/* confirma sem aviso";; *) fail "preflight: em pbi/* deveria confirmar — saída: $OUT";; esac
git checkout -q main
printf -- '- [x] task fechada (dev-dotnet)\n' > .kiro/specs/slug-x/tasks.md
git add -A; git commit -qm "done"
OUT="$(bash "$HS/preflight-branch.sh")"
if [ -z "$OUT" ]; then pass "preflight: sem task pendente fica em silêncio (I8: aviso constante é aviso ignorado)"
else fail "preflight: sem task pendente deveria silenciar — saída: $OUT"; fi
cd "$TMP" || exit 1

# =========================================================================
# format-dotnet.sh / format-flutter.sh — guarda de toolchain (sem SDK = exit 0)
# e resolução de arquivo via lib.sh
# =========================================================================
# PATH controlado SEM as toolchains (a máquina do CI pode ter dotnet real —
# symlinca só as ferramentas base num bin/ próprio)
STUB="$TMP/stubbin"; mkdir -p "$STUB"
for t in bash sh git grep sed find dirname basename mktemp stat sort head tail cat rm tr ls env printf touch; do
  p="$(command -v "$t" 2>/dev/null || true)"; [ -n "$p" ] && ln -sf "$p" "$STUB/$t"
done
FD="$TMP/fake-dotnet"; mkdir -p "$FD/src"; cd "$FD" || exit 1
git init -q -b main; git config user.email t@t.com; git config user.name t
echo 'class A {}' > src/A.cs
expect_exit 0 "format-dotnet: sem 'dotnet' no PATH sai 0 (máquina sem SDK não fica com save vermelho)" -- \
  env PATH="$STUB" bash "$HS/format-dotnet.sh" src/A.cs
echo 'void main() {}' > src/a.dart
expect_exit 0 "format-flutter: sem 'dart' no PATH sai 0" -- \
  env PATH="$STUB" bash "$HS/format-flutter.sh" src/a.dart
cd "$TMP" || exit 1

# newest_of da lib: devolve por MTIME, não por ordem alfabética (bug 1.7.0)
NW="$TMP/newest"; mkdir -p "$NW"
touch -t 202001010000 "$NW/zzz-velho.cs"
touch "$NW/aaa-novo.cs"
GOT="$(printf '%s\n%s\n' "$NW/zzz-velho.cs" "$NW/aaa-novo.cs" | bash -c '. "'"$HS"'/lib.sh"; newest_of')"
case "$GOT" in *aaa-novo.cs) pass "lib.newest_of: escolhe por mtime (aaa-novo mais recente que zzz-velho)";;
  *) fail "lib.newest_of: esperado aaa-novo.cs, veio: $GOT";; esac

echo
if [ "$FAIL" -eq 0 ]; then echo "test-hooks: $N caso(s), todos OK"; exit 0
else echo "test-hooks: FALHOU (de $N casos)"; exit 1; fi
