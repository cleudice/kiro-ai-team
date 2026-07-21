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
SCOPE="project"; MODE="install"; DEST=""; STACK=""

while [ $# -gt 0 ]; do
  case "$1" in
    --scope) SCOPE="${2:?project|global|hybrid}"; shift 2;;
    --stack) STACK="${2:?dotnet|webforms|flutter|multi}"; shift 2;;
    --update) MODE="update"; shift;;
    --kiro-home) KIRO_HOME="${2:?dir}"; shift 2;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) DEST="$1"; shift;;
  esac
done
case "$SCOPE" in project|global|hybrid) ;; *) echo "escopo inválido: $SCOPE"; exit 1;; esac
case "$STACK" in ""|dotnet|webforms|flutter|multi) ;; *) echo "stack inválido: $STACK"; exit 1;; esac
[ "$SCOPE" = "global" ] || [ -n "$DEST" ] || { echo "informe o caminho do projeto (ou use --scope global)"; exit 1; }

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
  case "$STACK" in
    dotnet) echo "dotnet.md";;
    webforms) echo "webforms.md oracle.md";;
    flutter) echo "flutter.md";;
    multi|"") echo "dotnet.md webforms.md flutter.md oracle.md";;
  esac
}

install_engine() {  # $1 = raiz .kiro de destino
  local K="$1"
  mkdir -p "$K/agents" "$K/skills"
  for a in $CORE_AGENTS $(stack_dev_agents); do
    cp -f "$SRC/agents/$a" "$K/agents/"
  done
  cp -rf "$SRC"/skills/*      "$K/skills/"
  echo "$VER" > "$K/$VERFILE"
  rm -f "$K/$OLD_VERFILE"
  if [ -z "$STACK" ]; then
    echo "  ✔ engine v$VER → $K (agents + skills — todos os stacks; use --stack dotnet|webforms|flutter pra instalar só o necessário)"
  else
    echo "  ✔ engine v$VER → $K (agents + skills — stack: $STACK)"
  fi
}

install_project_layer() {  # $1 = raiz do projeto
  local P="$1" K="$1/.kiro"
  mkdir -p "$K/steering/guidelines" "$K/hooks" "$K/settings" "$P"/docs/issues "$P"/docs/reviews "$P"/docs/context "$P"/docs/tests-spec
  # steering do time (sobrescreve na atualização)
  cp -f "$SRC"/steering-base/escalation-rules.md "$K/steering/"
  cp -f "$SRC"/steering-base/quality-gates.md    "$K/steering/"
  cp -f "$SRC"/steering-base/workflow.md         "$K/steering/"
  for g in $(stack_guidelines); do
    cp -f "$SRC/steering-base/guidelines/$g" "$K/steering/guidelines/"
  done
  # steering do projeto (só se ausente — pertence ao projeto)
  for t in product tech structure retro-learnings; do
    [ -f "$K/steering/$t.md" ] || cp "$SRC/steering-base/templates/$t.md" "$K/steering/$t.md"
  done
  [ -f "$P/AGENTS.md" ] || { cp "$SRC/steering-base/templates/AGENTS.md" "$P/AGENTS.md"; echo "  ✔ AGENTS.md → raiz do projeto (padrão aberto p/ Codex/Cursor/etc.)"; }
  echo "$VER" > "$K/$VERFILE"
  rm -f "$K/$OLD_VERFILE"
  echo "  ✔ camada do projeto → $P (steering + docs/)"
}

warn_version_mismatch() {
  local PV GV
  if [ -n "$DEST" ] && [ -f "$DEST/.kiro/$VERFILE" ]; then PV="$(cat "$DEST/.kiro/$VERFILE")"
  elif [ -n "$DEST" ] && [ -f "$DEST/.kiro/$OLD_VERFILE" ]; then PV="$(cat "$DEST/.kiro/$OLD_VERFILE")"
  else PV=""; fi
  if [ -f "$KIRO_HOME/$VERFILE" ]; then GV="$(cat "$KIRO_HOME/$VERFILE")"
  elif [ -f "$KIRO_HOME/$OLD_VERFILE" ]; then GV="$(cat "$KIRO_HOME/$OLD_VERFILE")"
  else GV=""; fi
  if [ -n "$PV" ] && [ -n "$GV" ] && [ "$PV" != "$GV" ]; then
    echo "  ⚠ versões divergentes: projeto=$PV global=$GV — no escopo hybrid, a engine GLOBAL vence; atualize um dos lados."
  fi
}

echo "kiro-ai-team v$VER — escopo: $SCOPE"
case "$SCOPE" in
  project)
    install_engine "$DEST/.kiro"
    install_project_layer "$DEST"
    ;;
  global)
    install_engine "$KIRO_HOME"
    mkdir -p "$KIRO_HOME/steering"
    if [ ! -f "$KIRO_HOME/steering/principios.md" ]; then
      cp "$SRC/steering-base/global/principios.md" "$KIRO_HOME/steering/principios.md"
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
