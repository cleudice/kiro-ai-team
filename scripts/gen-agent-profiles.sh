#!/usr/bin/env bash
# gen-agent-profiles.sh — gera agents/*.json (perfil CLI) a partir de agents/*.md
# (fonte única, formato IDE: YAML frontmatter + prompt no corpo).
#
# Direção invertida na 1.11 (era .json → .md até a 1.10): o ProfileLoader real do
# Kiro (schema zod embutido no bundle instalado, `kiro.kiro-agent/dist/extension.js`)
# varre .kiro/agents/**, aceita .md E .json, e deriva o mesmo agentId dos dois (nome
# do arquivo sem extensão) — com os dois presentes, ele carregava o par inteiro e
# ficava com o ÚLTIMO por ordem alfabética ('orchestrator.json' < 'orchestrator.md'
# → o .md sempre vencia, silenciosamente, com um "Duplicate agent ID ... overwriting"
# no log que ninguém lê). Ou seja: o .json nunca foi o perfil de verdade na IDE — só
# o .md era. Manter os dois como fontes independentes (a MD antiga era gerada do
# JSON) inevitavelmente colidia; gerar o CLI a partir do que a IDE já usa resolve.
#
# O .json gerado usa o truque que o próprio bundle documenta para o caso oposto
# (perfil que só a CLI deve enxergar): um objeto com 'allowedTools' e SEM
# 'permissions' é reconhecido pelo ProfileLoader como "perfil CLI-only" e IGNORADO
# inteiro pela IDE (função lt2/pe21 no bundle) — nem chega a validar contra o schema.
# Por isso o .json aqui nunca inclui 'permissions' (essa camada de defesa fica só no
# .md/IDE — ver comentário 'permissions' em cada agents/*.md) e sempre inclui
# 'allowedTools'.
#
# uso: scripts/gen-agent-profiles.sh            regenera agents/*.json
#      scripts/gen-agent-profiles.sh --check    não escreve; sai 1 se algum .json
#                                                estiver fora de sincronia com o .md
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

command -v python3 >/dev/null 2>&1 || { echo "✘ python3 não encontrado no PATH" >&2; exit 1; }
python3 -c "import yaml" 2>/dev/null || {
  echo "✘ PyYAML não encontrado (import yaml falhou) — necessário pra ler o frontmatter de agents/*.md." >&2
  echo "  pip install pyyaml" >&2
  exit 1
}

python3 - "$ROOT" "$CHECK" << 'PY'
import sys, glob, os, json
import yaml

# stdout no Windows usa o codepage do console (cp1252 etc.) por padrão, não UTF-8 —
# os símbolos ✔/✘ abaixo quebravam com UnicodeEncodeError em modo de escrita (mesma
# classe de bug já corrigida em selftest.sh e no gerador anterior).
sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')

root, check = sys.argv[1], sys.argv[2] == "1"
fail = False

for mpath in sorted(glob.glob(os.path.join(root, "agents", "*.md"))):
    name = os.path.splitext(os.path.basename(mpath))[0]
    jpath = os.path.join(root, "agents", f"{name}.json")

    raw = open(mpath, encoding="utf-8").read()
    if not raw.startswith("---\n"):
        fail = True; print(f"✘ {mpath}: sem frontmatter"); continue
    end = raw.find("\n---\n", 4)
    if end < 0:
        fail = True; print(f"✘ {mpath}: frontmatter não fechado"); continue
    fm = yaml.safe_load(raw[4:end]) or {}
    prompt = raw[end + 5:].strip()

    profile = {
        "name": name,
        "description": fm.get("description", ""),
        "prompt": prompt,
        "tools": fm.get("tools", []),
        # anti-colisão (ver cabeçalho): marca este arquivo como CLI-only pro
        # ProfileLoader da IDE. Dobra também como "sem confirmação" pro escopo já
        # coberto por 'tools' — mesmo acesso que o agente já tem, não mais.
        "allowedTools": fm.get("tools", []),
    }
    if fm.get("includeMcpJson"):
        profile["includeMcpJson"] = True
    if fm.get("resources"):
        profile["resources"] = fm["resources"]
    if fm.get("hooks"):
        # array plano — mesmo shape do .md (confirmado contra o schema real do
        # Kiro: agents/*.json e agents/*.md compartilham o mesmíssimo formato de
        # 'hooks', ao contrário do que uma leitura só da doc pública sugeriria).
        profile["hooks"] = fm["hooks"]

    content = json.dumps(profile, ensure_ascii=False, indent=2) + "\n"

    if check:
        existing = open(jpath, encoding="utf-8").read() if os.path.exists(jpath) else None
        if existing != content:
            print(f"✘ fora de sincronia (ou ausente): {jpath} — rode scripts/gen-agent-profiles.sh")
            fail = True
        continue

    with open(jpath, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"✔ {jpath}")

sys.exit(1 if fail else 0)
PY
