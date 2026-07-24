#!/usr/bin/env bash
# selftest do kiro-ai-team — os gates aplicados ao próprio repo. exit 0 = íntegro.
set -uo pipefail; cd "$(dirname "$0")"; FAIL=0
bad(){ echo "✘ $1"; FAIL=1; }; ok(){ echo "✔ $1"; }
for f in install.sh selftest.sh scripts/*.sh skills/*/scripts/*.sh hooks/scripts/*.sh; do
  [ -e "$f" ] || continue; bash -n "$f" && ok "bash: $f" || bad "sintaxe bash: $f"; done
for f in agents/*.json mcp/*.json hooks/*.json; do
  python3 -c "import json;json.load(open('$f'))" 2>/dev/null && ok "json: $f" || bad "JSON inválido: $f"; done
python3 - << 'PY' || FAIL=1
import re,sys,glob,os,json
fail=[]
for p in glob.glob('skills/*/SKILL.md'):
    s=open(p).read(); folder=p.split('/')[1]
    m=re.match(r'^---\n(.*?)\n---\n', s, re.S)
    if not m: fail.append(f"{p}: sem frontmatter"); continue
    fm=m.group(1)
    n=re.search(r'^name:\s*(\S+)\s*$', fm, re.M); d=re.search(r'^description:\s*(.+)$', fm, re.M)
    if not n or not d: fail.append(f"{p}: name/description ausentes"); continue
    if n.group(1)!=folder: fail.append(f"{p}: name '{n.group(1)}' != pasta '{folder}'")
    if not re.fullmatch(r'[a-z0-9-]{1,64}', n.group(1)): fail.append(f"{p}: name fora do padrão [a-z0-9-]")
    if len(d.group(1))>1024: fail.append(f"{p}: description >1024 chars")
    if len(s.splitlines())>500: fail.append(f"{p}: corpo >500 linhas")
for p in glob.glob('agents/*.json'):
    d = json.load(open(p))
    for entries in d.get('hooks', {}).values():
        for e in entries:
            cmd = e.get('command', '')
            m = re.search(r'\.kiro/hooks/(scripts/\S+\.sh)', cmd)
            if m and not os.path.exists(os.path.join('hooks', m.group(1))):
                fail.append(f"{p}: hook referencia {m.group(1)} que não existe em hooks/")
for p in glob.glob('steering-base/**/*.md', recursive=True):
    s=open(p).read()
    if 'templates/' in p or '/global/' in p: continue
    if not s.startswith('---'): fail.append(f"{p}: sem frontmatter inclusion")
for doc in ['README.md','OPERACAO.md','mcp/README.md']:
    if not os.path.exists(doc): continue
    for l in re.findall(r'\]\(([^)#]+)\)', open(doc).read()):
        if l.startswith('http'): continue
        if not os.path.exists(l): fail.append(f"{doc}: link quebrado -> {l}")
# OPERACAO.md é o único doc operacional agora — se um agente/skill sumir dele, é o
# próximo CATALOGO desatualizado nascendo (M4).
op = open('OPERACAO.md').read() if os.path.exists('OPERACAO.md') else ''
for p in glob.glob('agents/*.json'):
    name = json.load(open(p)).get('name') or os.path.splitext(os.path.basename(p))[0]
    if f"`{name}`" not in op: fail.append(f"OPERACAO.md: agente '{name}' não referenciado")
for p in glob.glob('skills/*/SKILL.md'):
    name = p.split('/')[1]
    if f"`{name}`" not in op: fail.append(f"OPERACAO.md: skill '{name}' não referenciada")
print('\n'.join('✘ '+f for f in fail) if fail else '✔ frontmatters, nomes, limites e links OK')
sys.exit(1 if fail else 0)
PY
bash scripts/gen-agent-md.sh --check && ok "agents/*.md em sincronia com agents/*.json" || bad "agents/*.md fora de sincronia — rode scripts/gen-agent-md.sh"
bash tests/test-check-gates.sh || bad "tests/test-check-gates.sh reprovou"
bash tests/test-install.sh || bad "tests/test-install.sh reprovou"
[ $FAIL -eq 0 ] && echo "SELFTEST OK" || { echo "SELFTEST REPROVADO"; exit 1; }
