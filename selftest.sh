#!/usr/bin/env bash
# selftest do kiro-ai-team — os gates aplicados ao próprio repo. exit 0 = íntegro.
set -uo pipefail; cd "$(dirname "$0")"; FAIL=0
bad(){ echo "✘ $1"; FAIL=1; }; ok(){ echo "✔ $1"; }
for f in install.sh selftest.sh scripts/*.sh skills/*/scripts/*.sh hooks/scripts/*.sh tests/*.sh; do
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
# P0-1 — frontmatter dos agents/*.md precisa ser YAML parseável de verdade: o check
# de sincronia (gen-agent-md.sh --check) compara texto, não valida YAML — foi assim
# que 4 agentes com ':' na description ficaram com frontmatter inválido sem ninguém
# reprovar. Usa PyYAML se existir; senão, checa que valores com ': ' estão entre aspas.
try:
    import yaml as _yaml
except ImportError:
    _yaml = None
for p in glob.glob('agents/*.md'):
    s = open(p, encoding='utf-8').read()
    m = re.match(r'^---\n(.*?)\n---\n', s, re.S)
    if not m: fail.append(f"{p}: sem frontmatter"); continue
    fm = m.group(1)
    if _yaml:
        try: _yaml.safe_load(fm)
        except Exception as e: fail.append(f"{p}: frontmatter YAML inválido — {e}")
    else:
        for line in fm.splitlines():
            lm = re.match(r'^\s*(?:- )?[A-Za-z_-]+: (.+)$', line)
            if lm and ': ' in lm.group(1) and not lm.group(1).startswith(('"', "'")):
                fail.append(f"{p}: valor com ': ' sem aspas no frontmatter — YAML quebrado: {line.strip()}")
# B1/B3 — todo caminho `.kiro/<algo>.sh` citado em agente/skill/hook/doc precisa
# corresponder a um arquivo que install.sh de fato instala (agents/, skills/**,
# hooks/scripts/, scripts/) — é este check que teria pego scripts/worktree.sh
# nunca sendo instalado (B1 da terceira auditoria). Caminhos resolvidos em
# runtime via kiro-paths.sh (variável $ENGINE, não literal ".kiro/...") não
# entram nesta checagem — são cobertos pelos casos por escopo em test-install.sh.
installed_sh = set()
for pat in ('skills/**/*.sh', 'hooks/scripts/*.sh', 'scripts/*.sh'):
    installed_sh.update(glob.glob(pat, recursive=True))
sh_doc_sources = (glob.glob('agents/*.json') + glob.glob('agents/*.md') + glob.glob('hooks/*.json')
                   + glob.glob('skills/*/SKILL.md')
                   + [d for d in ('OPERACAO.md', 'README.md', 'steering-base/templates/AGENTS.md') if os.path.exists(d)])
for p in sh_doc_sources:
    s = open(p, encoding='utf-8').read()
    for m in re.finditer(r'\.kiro/([A-Za-z0-9_./-]+\.sh)\b', s):
        rel = m.group(1)
        if rel not in installed_sh:
            fail.append(f"{p}: cita .kiro/{rel}, mas install.sh não instala esse caminho (installed_sh não bate)")
# M5 — skill://X citado em agents/*.json precisa corresponder a uma skill real
# (hoje bate por sorte nos 15; isto vira reprovação mecânica se algum dia divergir).
skill_names = {os.path.basename(os.path.dirname(p)) for p in glob.glob('skills/*/SKILL.md')}
for p in glob.glob('agents/*.json'):
    d = json.load(open(p))
    for r in d.get('resources', []):
        if r.startswith('skill://') and r[len('skill://'):] not in skill_names:
            fail.append(f"{p}: resource {r} não corresponde a nenhuma pasta em skills/")
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
# hooks/*.json e mcp/*.json também precisam aparecer referenciados em algum doc
# operacional — mesmo raciocínio anti-drift acima (M4), agora cobrindo o que
# ficou de fora na primeira rodada (B3 da segunda auditoria).
mcp_readme = open('mcp/README.md').read() if os.path.exists('mcp/README.md') else ''
for p in sorted(glob.glob('hooks/*.json')):
    base = os.path.basename(p)
    if base.startswith('_'): continue  # _canary.json é instrumentação de VERIFY.md, não hook de produto
    name = base[:-len('.json')]
    if f"`{name}`" not in op: fail.append(f"OPERACAO.md: hook '{name}' não referenciado")
for p in sorted(glob.glob('mcp/*.json')):
    base = os.path.basename(p)
    if base not in mcp_readme: fail.append(f"mcp/README.md: fragmento '{base}' não referenciado")
# VERSION bate com o topo VERSIONADO do CHANGELOG (ignora [Unreleased]) — deriva
# duas vezes é como a doc contradisse o código antes (ver OPERACAO.md intro).
if os.path.exists('VERSION') and os.path.exists('CHANGELOG.md'):
    ver = open('VERSION').read().strip()
    chg = open('CHANGELOG.md').read()
    m = re.search(r'^## \[(\d+\.\d+\.\d+)\]', chg, re.M)
    if m and m.group(1) != ver:
        fail.append(f"VERSION ({ver}) != topo versionado do CHANGELOG.md ({m.group(1)})")
# docs/archive/ só deve reter o que tem valor de AÇÃO pra quem migra (MIGRATION-v1.md)
# — manter os outros reintroduz o risco que causou a doc contradizer o código
# (3 documentos derivando de forma independente, ver OPERACAO.md intro).
for p in glob.glob('docs/archive/*'):
    base = os.path.basename(p)
    if base != 'MIGRATION-v1.md':
        fail.append(f"docs/archive/{base}: só MIGRATION-v1.md deveria sobrar em docs/archive/ (risco de doc derivando em paralelo)")
print('\n'.join('✘ '+f for f in fail) if fail else '✔ frontmatters, nomes, limites e links OK')
sys.exit(1 if fail else 0)
PY
bash scripts/gen-agent-md.sh --check && ok "agents/*.md em sincronia com agents/*.json" || bad "agents/*.md fora de sincronia — rode scripts/gen-agent-md.sh"
bash tests/test-check-gates.sh || bad "tests/test-check-gates.sh reprovou"
bash tests/test-install.sh || bad "tests/test-install.sh reprovou"
bash tests/test-worktree.sh || bad "tests/test-worktree.sh reprovou"
[ $FAIL -eq 0 ] && echo "SELFTEST OK" || { echo "SELFTEST REPROVADO"; exit 1; }
