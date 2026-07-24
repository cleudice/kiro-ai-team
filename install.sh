#!/usr/bin/env bash
# kiro-ai-team installer — escopos: project (padrão) | global | hybrid
#
# uso:
#   ./install.sh <projeto>                      # tudo no repo do projeto (padrão)
#   ./install.sh <projeto> --stack dotnet       # só agente(s)+guideline(s) do stack informado
#   ./install.sh --scope global                 # engine (agents+skills) em ~/.kiro
#   ./install.sh <projeto> --scope hybrid       # engine global + camada fina no projeto
#   flags extras: --update    --kiro-home <dir>  (default: $HOME/.kiro)
#   --stack dotnet|webforms|flutter|multi  (default: multi = instala tudo, sem podar — poda manual depois)
#   --dry-run     mostra o que seria feito (copiado/removido/gravado) sem tocar em nada
#   --uninstall   remove agents/skills instalados por este installer (a partir do
#                 próprio manifesto) do destino/--kiro-home; NUNCA toca steering do
#                 projeto (product/tech/structure/retro-learnings), docs/ nem AGENTS.md
#                 (são conteúdo do projeto, não do time)
#
# O que vai para onde:
#   engine  (agents/, skills/)                → project ou global, conforme escopo
#   steering compartilhado + guidelines       → SEMPRE projeto (steering do Kiro é por workspace)
#   steering do projeto (templates), docs/    → SEMPRE projeto
#   mcp/ (fragmentos)                         → mesclar manualmente (projeto ou ~/.kiro/settings)
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
VER="$(cat "$SRC/VERSION")"
KIRO_HOME="${KIRO_HOME:-$HOME/.kiro}"
VERFILE=".kiro-ai-team-version"
OLD_VERFILE=".ai-team-version"
SCOPE="project"; MODE="install"; DEST=""; STACK=""; DRYRUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --scope) SCOPE="${2:?project|global|hybrid}"; shift 2;;
    --stack) STACK="${2:?dotnet|webforms|flutter|multi}"; shift 2;;
    --update) MODE="update"; shift;;
    --uninstall) MODE="uninstall"; shift;;
    --dry-run) DRYRUN=1; shift;;
    --kiro-home) KIRO_HOME="${2:?dir}"; shift 2;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) DEST="$1"; shift;;
  esac
done
case "$SCOPE" in project|global|hybrid) ;; *) echo "escopo inválido: $SCOPE"; exit 1;; esac
case "$STACK" in ""|dotnet|webforms|flutter|multi) ;; *) echo "stack inválido: $STACK"; exit 1;; esac
[ "$SCOPE" = "global" ] || [ -n "$DEST" ] || { echo "informe o caminho do projeto (ou use --scope global)"; exit 1; }

# _x <cmd...> — executa, ou só anuncia sob --dry-run (nunca muta o disco nesse modo)
_x() { if [ "$DRYRUN" = "1" ]; then echo "  (dry-run) $*"; else "$@"; fi; }

CORE_AGENTS="orchestrator.json spec-analyst.json qa-blackbox.json reviewer-spec.json reviewer-code.json auditor.json"

stack_dev_agents() {
  case "$STACK" in
    dotnet) echo "dev-dotnet.json";;
    webforms) echo "dev-webforms.json";;
    flutter) echo "dev-flutter.json";;
    multi|"") echo "dev-dotnet.json dev-webforms.json dev-flutter.json";;
  esac
}

stack_guidelines() {
  # reviewer-code/reviewer-spec são CORE_AGENTS instalados em todo stack e revisam
  # qualquer diff do repo — por isso os 4 guideline files sempre vão juntos,
  # independente do --stack (são .md pequenos; o custo de bloat é irrelevante).
  echo "dotnet.md webforms.md flutter.md oracle.md"
}

# manifesto JSON em $VERFILE — substitui o antigo arquivo de uma linha (versão em
# texto puro); guarda também scope/stack/agents/skills instalados, pra --update
# saber o que podar (A1) e lembrar --stack sem precisar repassar (A2). Migra
# transparentemente o formato antigo na primeira atualização.
# uso: write_manifest <path> <version> <scope> <stack|@keep@> <"agentes"|@keep@> <"skills"|@keep@>
write_manifest() {
  python3 - "$1" "$2" "$3" "$4" "$5" "$6" << 'PY'
import json, sys, os
path, ver, scope, stack, agents, skills = sys.argv[1:7]
data = {}
if os.path.exists(path):
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except Exception:
        data = {}  # formato antigo (versão em texto puro) — migra transparente
data["version"] = ver
data["scope"] = scope
if stack != "@keep@":
    data["stack"] = stack
if agents != "@keep@":
    data["agents"] = agents.split()
if skills != "@keep@":
    data["skills"] = skills.split()
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2, sort_keys=True)
    f.write("\n")
PY
}

manifest_field() {  # manifest_field <path> <campo> -- vazio se ausente/arquivo não-JSON (formato antigo)
  [ -f "$1" ] || return 0
  python3 -c "
import json
try:
    d = json.load(open('$1', encoding='utf-8'))
except Exception:
    raise SystemExit
print(' '.join(d.get('$2', [])) if isinstance(d.get('$2'), list) else (d.get('$2') or ''))
" 2>/dev/null || true
}

array_contains() { local n="$1"; shift; [ $# -eq 0 ] && return 1; printf '%s\n' "$@" | grep -qxF "$n"; }

install_engine() {  # $1 = raiz .kiro de destino
  local K="$1"
  _x mkdir -p "$K/agents" "$K/skills"

  # --stack não informado NO UPDATE -> lembra o da instalação original (A2)
  if [ "$MODE" = "update" ] && [ -z "$STACK" ]; then
    local remembered; remembered="$(manifest_field "$K/$VERFILE" stack)"
    if [ -n "$remembered" ]; then
      STACK="$remembered"
      echo "  ℹ --stack não informado no update — usando o memorizado: '$STACK'"
    fi
  fi

  local NEW_AGENTS=()
  for a in $CORE_AGENTS $(stack_dev_agents); do
    _x cp -f "$SRC/agents/$a" "$K/agents/"; NEW_AGENTS+=("$a")
    md="${a%.json}.md"                    # CLI lê .json, IDE lê .md (gen-agent-md.sh) — os dois vão juntos
    if [ -f "$SRC/agents/$md" ]; then _x cp -f "$SRC/agents/$md" "$K/agents/"; NEW_AGENTS+=("$md"); fi
  done
  _x cp -rf "$SRC"/skills/*      "$K/skills/"
  local NEW_SKILLS=(); for d in "$SRC"/skills/*/; do NEW_SKILLS+=("$(basename "$d")"); done

  # scripts referenciados por hooks EMBUTIDOS em agente (ex.: qa-blackbox-guard.sh em
  # agents/qa-blackbox.json) são dependência de carga, não opcionais como os
  # hooks/*.json de conveniência (esses continuam cópia manual, ver QUICKSTART) —
  # sempre vão junto da engine.
  if [ -d "$SRC/hooks/scripts" ]; then
    _x mkdir -p "$K/hooks/scripts"
    _x cp -f "$SRC"/hooks/scripts/*.sh "$K/hooks/scripts/"
  fi

  # poda (A1): converge $K/agents e $K/skills pro conjunto atual — remove o que está
  # no destino mas não devia estar (skill/agente que saiu do central, dev-* de outro
  # --stack, arquivo estranho). Diff contra o DIRETÓRIO real, não contra o manifesto
  # antigo — autocura mesmo se o manifesto estiver ausente/corrompido/no formato legado.
  # (Sob --dry-run, $K/agents e $K/skills ainda não receberam os arquivos novos acima
  # — a listagem abaixo reflete o estado ANTES desta execução, que é a poda que
  # aconteceria numa execução real.)
  for f in "$K"/agents/*.json "$K"/agents/*.md; do
    [ -e "$f" ] || continue
    b="$(basename "$f")"
    array_contains "$b" "${NEW_AGENTS[@]}" || { _x rm -f "$f"; echo "  ✂ podado (fora do conjunto atual): agents/$b"; }
  done
  for d in "$K"/skills/*/; do
    [ -e "$d" ] || continue
    b="$(basename "$d")"
    array_contains "$b" "${NEW_SKILLS[@]}" || { _x rm -rf "$d"; echo "  ✂ podado (saiu do central): skills/$b"; }
  done

  _x write_manifest "$K/$VERFILE" "$VER" "$SCOPE" "$STACK" "${NEW_AGENTS[*]}" "${NEW_SKILLS[*]}"
  _x rm -f "$K/$OLD_VERFILE"
  if [ -z "$STACK" ]; then
    echo "  ✔ engine v$VER → $K (agents + skills — todos os stacks; use --stack dotnet|webforms|flutter pra instalar só o necessário)"
  else
    echo "  ✔ engine v$VER → $K (agents + skills — stack: $STACK)"
  fi
}

install_project_layer() {  # $1 = raiz do projeto
  local P="$1" K="$1/.kiro"
  _x mkdir -p "$K/steering/guidelines" "$K/hooks" "$K/settings" "$P"/docs/issues "$P"/docs/reviews "$P"/docs/context "$P"/docs/tests-spec
  # steering do time (sobrescreve na atualização)
  _x cp -f "$SRC"/steering-base/escalation-rules.md "$K/steering/"
  _x cp -f "$SRC"/steering-base/quality-gates.md    "$K/steering/"
  _x cp -f "$SRC"/steering-base/workflow.md         "$K/steering/"
  for g in $(stack_guidelines); do
    _x cp -f "$SRC/steering-base/guidelines/$g" "$K/steering/guidelines/"
  done
  # steering do projeto (só se ausente — pertence ao projeto)
  for t in product tech structure retro-learnings; do
    [ -f "$K/steering/$t.md" ] || _x cp "$SRC/steering-base/templates/$t.md" "$K/steering/$t.md"
  done
  [ -f "$P/AGENTS.md" ] || { _x cp "$SRC/steering-base/templates/AGENTS.md" "$P/AGENTS.md"; echo "  ✔ AGENTS.md → raiz do projeto (padrão aberto p/ Codex/Cursor/etc.)"; }
  _x write_manifest "$K/$VERFILE" "$VER" "$SCOPE" "@keep@" "@keep@" "@keep@"
  _x rm -f "$K/$OLD_VERFILE"
  echo "  ✔ camada do projeto → $P (steering + docs/)"
}

uninstall_engine() {  # $1 = raiz .kiro instalada (engine) — remove só o que o manifesto lista
  local K="$1"
  if [ ! -f "$K/$VERFILE" ]; then echo "  ✘ sem manifesto em $K/$VERFILE — nada a desinstalar (ou instalação em formato legado; remova manualmente)"; return; fi
  local AG SK; AG="$(manifest_field "$K/$VERFILE" agents)"; SK="$(manifest_field "$K/$VERFILE" skills)"
  for f in $AG; do if [ -e "$K/agents/$f" ]; then _x rm -f "$K/agents/$f"; echo "  ✂ removido: agents/$f"; fi; done
  for d in $SK; do if [ -e "$K/skills/$d" ]; then _x rm -rf "$K/skills/$d"; echo "  ✂ removido: skills/$d"; fi; done
  _x rm -f "$K/$VERFILE"
  echo "  ✔ engine desinstalada de $K — steering/docs/AGENTS.md do projeto preservados (não são do time, são conteúdo do projeto)"
}

warn_version_mismatch() {
  local PV GV
  if [ -n "$DEST" ] && [ -f "$DEST/.kiro/$VERFILE" ]; then PV="$(manifest_field "$DEST/.kiro/$VERFILE" version)"
  elif [ -n "$DEST" ] && [ -f "$DEST/.kiro/$OLD_VERFILE" ]; then PV="$(cat "$DEST/.kiro/$OLD_VERFILE")"
  else PV=""; fi
  if [ -f "$KIRO_HOME/$VERFILE" ]; then GV="$(manifest_field "$KIRO_HOME/$VERFILE" version)"
  elif [ -f "$KIRO_HOME/$OLD_VERFILE" ]; then GV="$(cat "$KIRO_HOME/$OLD_VERFILE")"
  else GV=""; fi
  if [ -n "$PV" ] && [ -n "$GV" ] && [ "$PV" != "$GV" ]; then
    echo "  ⚠ versões divergentes: projeto=$PV global=$GV — no escopo hybrid, a engine GLOBAL vence; atualize um dos lados."
  fi
}

MSG="kiro-ai-team v$VER — escopo: $SCOPE"
if [ "$DRYRUN" = "1" ]; then MSG="$MSG (dry-run: nada será tocado)"; fi
echo "$MSG"

if [ "$MODE" = "uninstall" ]; then
  case "$SCOPE" in
    project) uninstall_engine "$DEST/.kiro";;
    global)  uninstall_engine "$KIRO_HOME";;
    hybrid)  uninstall_engine "$KIRO_HOME";;
  esac
  echo "✔ concluído"
  exit 0
fi

case "$SCOPE" in
  project)
    install_engine "$DEST/.kiro"
    install_project_layer "$DEST"
    ;;
  global)
    install_engine "$KIRO_HOME"
    _x mkdir -p "$KIRO_HOME/steering"
    if [ ! -f "$KIRO_HOME/steering/principios.md" ]; then
      _x cp "$SRC/steering-base/global/principios.md" "$KIRO_HOME/steering/principios.md"
      echo "  ✔ steering global → $KIRO_HOME/steering/principios.md (edite: são SEUS princípios)"
    else
      echo "  ↷ steering global já existe (preservado): $KIRO_HOME/steering/principios.md"
    fi
    echo "  ⚠ quirks: workspace vence global em conflito; evite fileMatch no global; arquivo real, sem symlink; IDE ignora KIRO_HOME (só a CLI respeita)."
    echo "  ℹ steering de PROJETO continua por workspace. Rode depois, em cada repo:"
    echo "      ./install.sh <projeto> --scope hybrid"
    echo "  ℹ MCP global: mescle fragmentos de $SRC/mcp em $KIRO_HOME/settings/mcp.json"
    ;;
  hybrid)
    install_engine "$KIRO_HOME"
    install_project_layer "$DEST"
    # sem engine local: evita duplicidade/conflito de nomes de agente
    warn_version_mismatch
    ;;
esac

if [ "$MODE" = "install" ]; then
  echo "  ℹ hooks opcionais em $SRC/hooks (copiar p/ .kiro/hooks do projeto)"
  echo "  ℹ fragmentos MCP em $SRC/mcp (projeto: .kiro/settings/mcp.json | global: $KIRO_HOME/settings/mcp.json)"
fi
echo "✔ concluído"
