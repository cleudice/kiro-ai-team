#!/usr/bin/env bash
# selftest do kiro-ai-team — os gates aplicados ao próprio repo. exit 0 = íntegro.
set -uo pipefail; cd "$(dirname "$0")" || exit 1; FAIL=0
bad(){ echo "✘ $1"; FAIL=1; }; ok(){ echo "✔ $1"; }
for f in install.sh selftest.sh scripts/*.sh skills/*/scripts/*.sh hooks/scripts/*.sh tests/*.sh; do
  [ -e "$f" ] || continue; bash -n "$f" && ok "bash: $f" || bad "sintaxe bash: $f"; done
for f in agents/*.json mcp/*.json hooks/*.json hooks/diagnostics/*.json; do
  [ -e "$f" ] || continue
  # path via sys.argv (não interpolado): path com aspa simples quebraria o literal
  python3 -c "import json,sys;json.load(open(sys.argv[1]))" "$f" 2>/dev/null && ok "json: $f" || bad "JSON inválido: $f"; done
python3 - << 'PY' || FAIL=1
import re,sys,glob,os,json
fail=[]
for p in glob.glob('skills/*/SKILL.md'):
    # basename(dirname(p)), não split('/')[1]: glob.glob no Windows devolve
    # separador '\\' — split('/') não achava nada e IndexError quebrava o
    # selftest inteiro antes de chegar nos testes de verdade.
    s=open(p).read(); folder=os.path.basename(os.path.dirname(p))
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
link_docs = (['README.md','OPERACAO.md','mcp/README.md','CHANGELOG.md','hooks/VERIFY.md',
              'CONTRIBUTING.md','SECURITY.md']
             + glob.glob('examples/*/README.md') + glob.glob('skills/*/SKILL.md') + glob.glob('agents/*.md'))
for doc in link_docs:
    if not os.path.exists(doc): continue
    base = os.path.dirname(doc)
    for l in re.findall(r'\]\(([^)#]+)\)', open(doc).read()):
        if l.startswith('http'): continue
        # link relativo resolve a partir do próprio doc
        if not (os.path.exists(os.path.join(base, l)) or os.path.exists(l)):
            fail.append(f"{doc}: link quebrado -> {l}")
# OPERACAO.md é o único doc operacional agora — se um agente/skill sumir dele, é o
# próximo CATALOGO desatualizado nascendo (M4).
op = open('OPERACAO.md').read() if os.path.exists('OPERACAO.md') else ''
for p in glob.glob('agents/*.json'):
    name = json.load(open(p)).get('name') or os.path.splitext(os.path.basename(p))[0]
    if f"`{name}`" not in op: fail.append(f"OPERACAO.md: agente '{name}' não referenciado")
for p in glob.glob('skills/*/SKILL.md'):
    name = os.path.basename(os.path.dirname(p))
    if f"`{name}`" not in op: fail.append(f"OPERACAO.md: skill '{name}' não referenciada")
# hooks/*.json e mcp/*.json também precisam aparecer referenciados em algum doc
# operacional — mesmo raciocínio anti-drift acima (M4), agora cobrindo o que
# ficou de fora na primeira rodada (B3 da segunda auditoria).
mcp_readme = open('mcp/README.md').read() if os.path.exists('mcp/README.md') else ''
HOOK_TRIGGERS = {'PostFileSave', 'PostFileCreate', 'PostTaskExec', 'SessionStart', 'preToolUse'}
for p in sorted(glob.glob('hooks/*.json')):
    base = os.path.basename(p)
    name = base[:-len('.json')]
    if f"`{name}`" not in op: fail.append(f"OPERACAO.md: hook '{name}' não referenciado")
    # trigger fora do conjunto conhecido = typo silencioso (hook nunca dispara)
    hj = json.load(open(p))
    trg = (hj.get('when') or {}).get('type') or hj.get('trigger')
    if trg and trg not in HOOK_TRIGGERS:
        fail.append(f"{p}: trigger '{trg}' fora do conjunto conhecido {sorted(HOOK_TRIGGERS)}")
# bloco sincronizado entre review-spec e review-code (marcador <!-- sync: veredicto-commit -->):
# a linha imediatamente após o marcador precisa ser idêntica nos dois — duplicação
# aceita conscientemente, drift não.
sync = {}
for p in ('skills/review-spec/SKILL.md', 'skills/review-code/SKILL.md'):
    lines = open(p, encoding='utf-8').read().splitlines()
    for i, l in enumerate(lines):
        if 'sync: veredicto-commit' in l and i + 1 < len(lines):
            sync[p] = lines[i + 1]
if len(sync) == 2 and len(set(sync.values())) != 1:
    fail.append("bloco 'sync: veredicto-commit' divergiu entre review-spec e review-code — sincronize as duas linhas")
elif len(sync) < 2:
    fail.append("marcador 'sync: veredicto-commit' ausente em review-spec ou review-code")
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
bash tests/test-hooks.sh || bad "tests/test-hooks.sh reprovou"
bash tests/test-examples.sh || bad "tests/test-examples.sh reprovou"
[ $FAIL -eq 0 ] && echo "SELFTEST OK" || { echo "SELFTEST REPROVADO"; exit 1; }
