#!/usr/bin/env bash
# kiro-ai-team installer — escopos: project (padrão) | global | hybrid
#
# uso:
#   ./install.sh <projeto>                      # tudo no repo do projeto (padrão)
#   ./install.sh <projeto> --stack dotnet       # só agente(s)+guideline(s) do stack informado
#   ./install.sh --scope global                 # engine (agents+skills) em ~/.kiro
#   ./install.sh <projeto> --scope hybrid       # engine global + camada fina no projeto
#   flags extras: --update    --kiro-home <dir>  (default: $HOME/.kiro)    --version
#   --stack dotnet|webforms|flutter|multi  (default: multi = instala tudo, sem podar — poda manual depois)
#   --dry-run     mostra o que seria feito (copiado/removido/gravado) sem tocar em nada
#   --uninstall   remove agents/skills instalados por este installer (a partir do
#                 próprio manifesto) do destino/--kiro-home; NUNCA toca steering do
#                 projeto (product/tech/structure/retro-learnings), docs/ nem AGENTS.md
#                 (são conteúdo do projeto, não do time)
#   --prune-unmanaged   (só --update) poda TODO agents/*.json|*.md e skills/* que não
#                 estiver no conjunto atual do central — inclusive agentes/skills
#                 próprios do projeto que não vieram daqui. Sem esta flag, --update
#                 poda só o que o manifesto anterior registra como instalado pelo
#                 time (agentes específicos do projeto sobrevivem). Sem manifesto
#                 anterior (instalação legada) e sem esta flag, --update NÃO poda —
#                 só avisa e sugere rodar com --prune-unmanaged.
#
# O que vai para onde:
#   engine  (agents/, skills/)                → project ou global, conforme escopo
#   scripts/{worktree,kiro-paths}.sh          → SEMPRE no projeto também (.kiro/scripts/), mesmo em
#                                                hybrid/global — caminho fixo citado em todo prompt/
#                                                skill/hook; kiro-paths.sh resolve o resto (skills/
#                                                hooks) via .kiro-ai-team-paths quando a engine mora
#                                                em $KIRO_HOME (B1/B3)
#   steering compartilhado + guidelines       → SEMPRE projeto (steering do Kiro é por workspace)
#   steering do projeto (templates), docs/    → SEMPRE projeto
#   mcp/ (fragmentos)                         → mesclar manualmente (projeto ou ~/.kiro/settings)
set -euo pipefail
# I6 — python3 é dependência dura (manifesto JSON: write_manifest/manifest_field
# abaixo). Não vem com todo Git Bash no Windows (um dos ambientes que este repo
# suporta explicitamente, ver mcp/README.md) — falhar cedo com mensagem acionável
# em vez de um traceback python obscuro no meio da instalação.
command -v python3 >/dev/null 2>&1 || {
  echo "✘ python3 não encontrado no PATH — necessário pro manifesto JSON (.kiro-ai-team-version)." >&2
  echo "  No Windows via Git Bash, instale Python e confirme que 'python3' (ou um alias/symlink pra 'python') está no PATH." >&2
  exit 1
}
SRC="$(cd "$(dirname "$0")" && pwd)"
VER="$(cat "$SRC/VERSION")"
KIRO_HOME="${KIRO_HOME:-$HOME/.kiro}"
VERFILE=".kiro-ai-team-version"
OLD_VERFILE=".ai-team-version"
SCOPE="project"; MODE="install"; DEST=""; STACK=""; DRYRUN=0; PRUNE_UNMANAGED=0

while [ $# -gt 0 ]; do
  case "$1" in
    --scope) SCOPE="${2:?project|global|hybrid}"; shift 2;;
    --stack) STACK="${2:?dotnet|webforms|flutter|multi}"; shift 2;;
    --update) MODE="update"; shift;;
    --uninstall) MODE="uninstall"; shift;;
    --dry-run) DRYRUN=1; shift;;
    --prune-unmanaged) PRUNE_UNMANAGED=1; shift;;
    --kiro-home) KIRO_HOME="${2:?dir}"; shift 2;;
    -h|--help) awk 'NR>1 && /^#/{sub(/^# ?/,""); print} NR>1 && !/^#/{exit}' "$0"; exit 0;;
    --version) cat "$SRC/VERSION"; exit 0;;
    -*) echo "flag desconhecida: $1 (veja --help)"; exit 1;;
    *) DEST="$1"; shift;;
  esac
done
case "$SCOPE" in project|global|hybrid) ;; *) echo "escopo inválido: $SCOPE"; exit 1;; esac
case "$STACK" in ""|dotnet|webforms|flutter|multi) ;; *) echo "stack inválido: $STACK"; exit 1;; esac
[ "$SCOPE" = "global" ] || [ -n "$DEST" ] || { echo "informe o caminho do projeto (ou use --scope global)"; exit 1; }
# DEST precisa existir: antes, um typo de flag (ex.: --updte) caía no case '*' e o
# installer criava .kiro/, docs/ e AGENTS.md num diretório literalmente com esse nome.
[ -z "$DEST" ] || [ -d "$DEST" ] || { echo "✘ diretório do projeto não existe: $DEST"; exit 1; }

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
# texto puro); guarda também scope/stack/agents/skills/scripts instalados, pra
# --update saber o que podar (A1), lembrar --stack sem precisar repassar (A2) e
# --uninstall saber o que remover (inclusive scripts/*.sh — B1/I5, antes órfãos).
# Migra transparentemente o formato antigo na primeira atualização.
# uso: write_manifest <path> <version> <scope> <stack|@keep@> <"agentes"|@keep@> <"skills"|@keep@> <"scripts"|@keep@> [<"hook_scripts"|@keep@>]
write_manifest() {
  python3 - "$1" "$2" "$3" "$4" "$5" "$6" "$7" "${8:-@keep@}" << 'PY'
import json, sys, os
path, ver, scope, stack, agents, skills, scripts, hook_scripts = sys.argv[1:9]
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
if scripts != "@keep@":
    data["scripts"] = scripts.split()
if hook_scripts != "@keep@":
    data["hook_scripts"] = hook_scripts.split()
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2, sort_keys=True)
    f.write("\n")
PY
}

manifest_field() {  # manifest_field <path> <campo> -- vazio se ausente/arquivo não-JSON (formato antigo)
  # path/campo via sys.argv, nunca interpolados na string python: path com aspa
  # simples (ex.: /Users/O'Brien) quebraria o literal — write_manifest já fazia certo.
  [ -f "$1" ] || return 0
  python3 -c "
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding='utf-8'))
except Exception:
    raise SystemExit
v = d.get(sys.argv[2])
print(' '.join(v) if isinstance(v, list) else (v or ''))
" "$1" "$2" 2>/dev/null || true
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
  # remove-e-recopia por skill: cp -rf sozinho nunca apaga arquivo que MORREU dentro
  # de uma skill no central (ex.: um script antigo em skills/X/scripts/) — ficaria
  # órfão no destino para sempre.
  local NEW_SKILLS=()
  for d in "$SRC"/skills/*/; do
    local sb; sb="$(basename "$d")"
    [ -d "$K/skills/$sb" ] && _x rm -rf "$K/skills/$sb"
    _x cp -rf "$d" "$K/skills/$sb"
    NEW_SKILLS+=("$sb")
  done

  # scripts referenciados por hooks EMBUTIDOS em agente (ex.: qa-blackbox-guard.sh em
  # agents/qa-blackbox.json) são dependência de carga, não opcionais como os
  # hooks/*.json de conveniência (esses continuam cópia manual, ver OPERACAO.md) —
  # sempre vão junto da engine, e entram no manifesto pra saírem no --uninstall.
  local NEW_HOOK_SCRIPTS=()
  if [ -d "$SRC/hooks/scripts" ]; then
    _x mkdir -p "$K/hooks/scripts"
    _x cp -f "$SRC"/hooks/scripts/*.sh "$K/hooks/scripts/"
    for f in "$SRC"/hooks/scripts/*.sh; do NEW_HOOK_SCRIPTS+=("$(basename "$f")"); done
  fi

  # scripts/{worktree,kiro-paths}.sh (B1) — worktree.sh é dependência de carga
  # (orchestrator/qa-blackbox citam "1 PBI = 1 worktree" no próprio prompt) e
  # antes desta correção NUNCA era instalado em lugar nenhum; kiro-paths.sh é o
  # resolvedor que faz o caminho fixo `.kiro/scripts/...` funcionar também em
  # hybrid/global, onde a engine mora em $KIRO_HOME (B3). Sempre vão junto.
  _x mkdir -p "$K/scripts"
  _x cp -f "$SRC/scripts/worktree.sh"   "$K/scripts/"
  _x cp -f "$SRC/scripts/kiro-paths.sh" "$K/scripts/"
  local NEW_SCRIPTS=(worktree.sh kiro-paths.sh)
  # auto-referência: se alguém rodar os scripts direto daqui (ex.: escopo global
  # puro, sem camada de projeto por perto), kiro-paths.sh já resolve pra si mesmo
  # sem este arquivo — mas gravá-lo deixa explícito e uniforme com install_project_layer.
  if [ "$DRYRUN" != "1" ]; then
    printf 'KIRO_ENGINE=%q\n' "$K" > "$K/.kiro-ai-team-paths"
  else
    echo "  (dry-run) gravar $K/.kiro-ai-team-paths → KIRO_ENGINE=$K"
  fi

  # poda (A1, revisado B1): por padrão poda só o que o MANIFESTO ANTERIOR registra
  # como instalado pelo time — nunca o diretório inteiro. Agente/skill próprio do
  # projeto (ex.: analista de crashes do app X, ver README "a dualidade") não está
  # no manifesto anterior como "nosso", então sobrevive. --prune-unmanaged restaura
  # o comportamento antigo (converge o diretório real pro conjunto atual — útil só
  # pra autocura de instalação legada/corrompida, nunca automático).
  local PREV_AGENTS=() PREV_SKILLS=()
  if [ -f "$K/$VERFILE" ]; then
    read -r -a PREV_AGENTS <<< "$(manifest_field "$K/$VERFILE" agents)"
    read -r -a PREV_SKILLS <<< "$(manifest_field "$K/$VERFILE" skills)"
  fi
  if [ "$PRUNE_UNMANAGED" = "1" ]; then
    echo "  ⚠ --prune-unmanaged: podando TUDO fora do conjunto atual, inclusive agentes/skills próprios do projeto não reconhecidos"
    for f in "$K"/agents/*.json "$K"/agents/*.md; do
      [ -e "$f" ] || continue
      b="$(basename "$f")"
      array_contains "$b" "${NEW_AGENTS[@]}" || { _x rm -f "$f"; echo "  ✂ podado (fora do conjunto atual): agents/$b"; }
    done
    for d in "$K"/skills/*/; do
      [ -e "$d" ] || continue
      b="$(basename "$d")"
      array_contains "$b" "${NEW_SKILLS[@]}" || { _x rm -rf "$d"; echo "  ✂ podado (fora do conjunto atual): skills/$b"; }
    done
  elif [ ${#PREV_AGENTS[@]} -eq 0 ] && [ ${#PREV_SKILLS[@]} -eq 0 ]; then
    if [ -f "$K/$VERFILE" ] || ls "$K"/agents/*.json >/dev/null 2>&1; then
      echo "  ℹ manifesto anterior ausente/legado — pulando poda pra não arriscar remover agentes/skills próprios do projeto. Rode com --prune-unmanaged se quiser convergir $K pro conjunto atual do central."
    fi
  else
    for f in "$K"/agents/*.json "$K"/agents/*.md; do
      [ -e "$f" ] || continue
      b="$(basename "$f")"
      array_contains "$b" "${NEW_AGENTS[@]}" && continue
      # ${ARR[@]+...}: array vazio sob set -u aborta no bash <4.4 (macOS 3.2, RHEL7)
      array_contains "$b" ${PREV_AGENTS[@]+"${PREV_AGENTS[@]}"} && { _x rm -f "$f"; echo "  ✂ podado (saiu do central): agents/$b"; }
    done
    for d in "$K"/skills/*/; do
      [ -e "$d" ] || continue
      b="$(basename "$d")"
      array_contains "$b" "${NEW_SKILLS[@]}" && continue
      array_contains "$b" ${PREV_SKILLS[@]+"${PREV_SKILLS[@]}"} && { _x rm -rf "$d"; echo "  ✂ podado (saiu do central): skills/$b"; }
    done
  fi

  _x write_manifest "$K/$VERFILE" "$VER" "$SCOPE" "$STACK" "${NEW_AGENTS[*]}" "${NEW_SKILLS[*]}" "${NEW_SCRIPTS[*]}" "${NEW_HOOK_SCRIPTS[*]}"
  _x rm -f "$K/$OLD_VERFILE"
  if [ -z "$STACK" ]; then
    echo "  ✔ engine v$VER → $K (agents + skills — todos os stacks; use --stack dotnet|webforms|flutter pra instalar só o necessário)"
  else
    echo "  ✔ engine v$VER → $K (agents + skills — stack: $STACK)"
  fi
}

install_project_layer() {  # $1 = raiz do projeto, $2 = raiz da engine (default: $1/.kiro, escopo project)
  local P="$1" K="$1/.kiro" ENGINE="${2:-$1/.kiro}"
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
  # camada fina de scripts (B1/B3): worktree.sh + kiro-paths.sh SEMPRE aqui, no
  # caminho fixo .kiro/scripts/, mesmo em hybrid onde agents/skills reais moram
  # em $KIRO_HOME — é o que faz `.kiro/scripts/worktree.sh start <PBI>` (citado
  # em todo prompt/skill/hook) resolver igual nos 3 escopos. kiro-paths.sh lê o
  # .kiro-ai-team-paths gravado logo abaixo pra apontar o resto (skills/hooks) pra
  # onde a engine de fato está.
  _x mkdir -p "$K/scripts"
  _x cp -f "$SRC/scripts/worktree.sh"   "$K/scripts/"
  _x cp -f "$SRC/scripts/kiro-paths.sh" "$K/scripts/"
  if [ "$DRYRUN" != "1" ]; then
    printf 'KIRO_ENGINE=%q\n' "$ENGINE" > "$K/.kiro-ai-team-paths"
  else
    echo "  (dry-run) gravar $K/.kiro-ai-team-paths → KIRO_ENGINE=$ENGINE"
  fi
  # .gitignore: só os artefatos GERADOS por check-gates.sh (não a evidência em si,
  # que é registro versionado do PBI) — append idempotente, nunca sobrescreve um
  # .gitignore existente do projeto.
  if [ "$DRYRUN" != "1" ]; then
    touch "$P/.gitignore"
    for line in "docs/reviews/.gate-ledger" "docs/reviews/.merge-count" "docs/reviews/*-g1-run.log"; do
      grep -qxF "$line" "$P/.gitignore" 2>/dev/null || echo "$line" >> "$P/.gitignore"
    done
  else
    echo "  (dry-run) garantir entradas de .gate-ledger/.merge-count/*-g1-run.log em $P/.gitignore"
  fi
  _x write_manifest "$K/$VERFILE" "$VER" "$SCOPE" "@keep@" "@keep@" "@keep@" "worktree.sh kiro-paths.sh"
  _x rm -f "$K/$OLD_VERFILE"
  echo "  ✔ camada do projeto → $P (steering + docs/)"
}

uninstall_engine() {  # $1 = raiz .kiro instalada (engine) — remove só o que o manifesto lista
  local K="$1"
  if [ ! -f "$K/$VERFILE" ]; then echo "  ✘ sem manifesto em $K/$VERFILE — nada a desinstalar (ou instalação em formato legado; remova manualmente)"; return; fi
  local AG SK SC HS; AG="$(manifest_field "$K/$VERFILE" agents)"; SK="$(manifest_field "$K/$VERFILE" skills)"; SC="$(manifest_field "$K/$VERFILE" scripts)"; HS="$(manifest_field "$K/$VERFILE" hook_scripts)"
  for f in $AG; do if [ -e "$K/agents/$f" ]; then _x rm -f "$K/agents/$f"; echo "  ✂ removido: agents/$f"; fi; done
  for d in $SK; do if [ -e "$K/skills/$d" ]; then _x rm -rf "$K/skills/$d"; echo "  ✂ removido: skills/$d"; fi; done
  for f in $SC; do if [ -e "$K/scripts/$f" ]; then _x rm -f "$K/scripts/$f"; echo "  ✂ removido: scripts/$f"; fi; done
  # manifesto pré-1.9 não tem hook_scripts — fallback: remover os que o CENTRAL atual
  # conhece (melhor aproximação disponível; antes eles ficavam órfãos para sempre)
  if [ -z "$HS" ] && [ -d "$K/hooks/scripts" ] && [ -d "$SRC/hooks/scripts" ]; then
    for f in "$SRC"/hooks/scripts/*.sh; do HS="$HS $(basename "$f")"; done
  fi
  for f in $HS; do if [ -e "$K/hooks/scripts/$f" ]; then _x rm -f "$K/hooks/scripts/$f"; echo "  ✂ removido: hooks/scripts/$f"; fi; done
  _x rm -f "$K/.kiro-ai-team-paths"
  _x rm -f "$K/$VERFILE"
  # diretórios que o installer criou e ficaram vazios não devem sobrar como ruído
  for d in "$K/hooks/scripts" "$K/hooks" "$K/agents" "$K/skills" "$K/scripts"; do
    [ -d "$d" ] && _x rmdir "$d" 2>/dev/null || true
  done
  echo "  ✔ engine desinstalada de $K — steering/docs/AGENTS.md do projeto preservados (não são do time, são conteúdo do projeto)"
}

# uninstall_gitignore_lines <raiz do projeto> — remove APENAS as 3 linhas que
# install_project_layer acrescentou; o resto do .gitignore é do projeto.
uninstall_gitignore_lines() {
  local P="$1" tmp
  [ -f "$P/.gitignore" ] || return 0
  if [ "$DRYRUN" = "1" ]; then echo "  (dry-run) remover entradas do time de $P/.gitignore"; return 0; fi
  tmp="$(mktemp -t gitignore.XXXXXX)"
  grep -vxF -e "docs/reviews/.gate-ledger" -e "docs/reviews/.merge-count" -e "docs/reviews/*-g1-run.log" "$P/.gitignore" > "$tmp" || true
  mv "$tmp" "$P/.gitignore"
}

# uninstall_project_scripts <raiz .kiro do projeto> — escopo hybrid: a engine
# real some de $KIRO_HOME via uninstall_engine acima, mas a camada FINA de
# scripts (worktree.sh/kiro-paths.sh + .kiro-ai-team-paths) instalada no
# projeto por install_project_layer (B1/B3) fica órfã se não for limpa aqui.
# Nunca toca steering/docs/AGENTS.md — mesma regra do uninstall_engine.
uninstall_project_scripts() {
  local K="$1"
  [ -f "$K/$VERFILE" ] || return 0
  local SC; SC="$(manifest_field "$K/$VERFILE" scripts)"
  for f in $SC; do if [ -e "$K/scripts/$f" ]; then _x rm -f "$K/scripts/$f"; echo "  ✂ removido: scripts/$f"; fi; done
  _x rm -f "$K/.kiro-ai-team-paths"
  # sem isto o manifesto ficava órfão apontando scripts inexistentes — um --update
  # posterior leria 'scripts' de um manifesto mentiroso
  _x rm -f "$K/$VERFILE"
  echo "  ✔ camada fina de scripts removida de $K (steering/docs preservados)"
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
    project) uninstall_engine "$DEST/.kiro"
             uninstall_gitignore_lines "$DEST";;
    global)  uninstall_engine "$KIRO_HOME";;
    hybrid)  uninstall_engine "$KIRO_HOME"
             uninstall_project_scripts "$DEST/.kiro"
             uninstall_gitignore_lines "$DEST";;
  esac
  echo "✔ concluído"
  exit 0
fi

case "$SCOPE" in
  project)
    install_engine "$DEST/.kiro"
    install_project_layer "$DEST" "$DEST/.kiro"
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
    # ANTES dos installs: depois deles os dois manifestos já teriam $VER e o aviso
    # de divergência nunca dispararia (era código morto)
    warn_version_mismatch
    install_engine "$KIRO_HOME"
    # sem engine local: evita duplicidade/conflito de nomes de agente
    install_project_layer "$DEST" "$KIRO_HOME"
    ;;
esac

if [ "$MODE" = "install" ]; then
  echo "  ℹ hooks opcionais em $SRC/hooks (copiar p/ .kiro/hooks do projeto)"
  echo "  ℹ fragmentos MCP em $SRC/mcp (projeto: .kiro/settings/mcp.json | global: $KIRO_HOME/settings/mcp.json)"
fi
echo "✔ concluído"
