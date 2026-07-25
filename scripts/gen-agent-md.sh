#!/usr/bin/env bash
# gen-agent-md.sh — gera agents/*.md (formato que o IDE do Kiro lê: YAML
# frontmatter + prompt no corpo) a partir de agents/*.json (fonte única, que
# é o formato que a CLI do Kiro lê). Nunca edite os .md à mão — eles são
# derivados; a fonte da verdade é sempre o .json correspondente.
# uso: scripts/gen-agent-md.sh            regenera agents/*.md
#      scripts/gen-agent-md.sh --check    não escreve; sai 1 se algum .md
#                                         estiver fora de sincronia com o .json
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

python3 - "$ROOT" "$CHECK" << 'PY'
import json, sys, glob, os

root, check = sys.argv[1], sys.argv[2] == "1"
fail = False

def yaml_str_list(items):
    return "[" + ", ".join(items) + "]"

for jpath in sorted(glob.glob(os.path.join(root, "agents", "*.json"))):
    with open(jpath, encoding="utf-8") as f:
        data = json.load(f)
    name = data.get("name") or os.path.splitext(os.path.basename(jpath))[0]
    mpath = os.path.join(root, "agents", f"{name}.md")

    fm = []
    # json.dumps: descriptions contêm ': ' e quebrariam o YAML sem aspas (P0-1)
    fm.append(f"description: {json.dumps(data['description'], ensure_ascii=False)}")
    if "model" in data:
        fm.append(f"model: {data['model']}")
    if "tools" in data:
        fm.append(f"tools: {yaml_str_list(data['tools'])}")
    if "resources" in data and data["resources"]:
        fm.append("resources:")
        for r in data["resources"]:
            fm.append(f"  - {r}")
    if "hooks" in data and data["hooks"]:
        # best-effort: o contrato de hooks por-agente no formato .md do IDE não é
        # documentado publicamente; propaga mesmo assim (inofensivo se ignorado).
        fm.append("hooks:")
        for trigger, entries in data["hooks"].items():
            fm.append(f"  {trigger}:")
            for e in entries:
                fm.append(f"    - matcher: {json.dumps(e['matcher'], ensure_ascii=False)}")
                fm.append(f"      command: {json.dumps(e['command'], ensure_ascii=False)}")

    content = "---\n" + "\n".join(fm) + "\n---\n" + data["prompt"].rstrip() + "\n"

    if check:
        existing = open(mpath, encoding="utf-8").read() if os.path.exists(mpath) else None
        if existing != content:
            print(f"✘ fora de sincronia (ou ausente): {mpath} — rode scripts/gen-agent-md.sh")
            fail = True
        continue

    with open(mpath, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"✔ {mpath}")

sys.exit(1 if fail else 0)
PY
