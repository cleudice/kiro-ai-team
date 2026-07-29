#!/usr/bin/env bash
# selftest do kiro-ai-team — os gates aplicados ao próprio repo. exit 0 = íntegro.
set -uo pipefail; cd "$(dirname "$0")" || exit 1; FAIL=0
bad(){ echo "✘ $1"; FAIL=1; }; ok(){ echo "✔ $1"; }
for f in install.sh selftest.sh scripts/*.sh skills/*/scripts/*.sh hooks/scripts/*.sh tests/*.sh; do
  [ -e "$f" ] || continue; bash -n "$f" && ok "bash: $f" || bad "sintaxe bash: $f"; done
for f in agents/*.json mcp/*.json hooks/*.json hooks/diagnostics/*.json; do
  [ -e "$f" ] || continue
  # path via sys.argv (não interpolado): path com aspa simples quebraria o literal
  python3 -c "import json,sys;json.load(open(sys.argv[1], encoding='utf-8'))" "$f" 2>/dev/null && ok "json: $f" || bad "JSON inválido: $f"; done
python3 - << 'PY' || FAIL=1
import re,sys,glob,os,json
# stdout no Windows usa o codepage do console (cp1252 etc.) por padrão, não
# UTF-8 — os símbolos ✔/✘ usados nas mensagens abaixo quebravam o print com
# UnicodeEncodeError, escondendo o resultado real (a falha ficava atrás do
# traceback). reconfigure força UTF-8 na saída, igual ao 'errors' abaixo evita
# nova exceção se ainda assim algum caractere não for mapeável.
sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')
fail=[]
for p in glob.glob('skills/*/SKILL.md'):
    # basename(dirname(p)), não split('/')[1]: glob.glob no Windows devolve
    # separador '\\' — split('/') não achava nada e IndexError quebrava o
    # selftest inteiro antes de chegar nos testes de verdade.
    s=open(p, encoding='utf-8').read(); folder=os.path.basename(os.path.dirname(p))
    m=re.match(r'^---\n(.*?)\n---\n', s, re.S)
    if not m: fail.append(f"{p}: sem frontmatter"); continue
    fm=m.group(1)
    n=re.search(r'^name:\s*(\S+)\s*$', fm, re.M); d=re.search(r'^description:\s*(.+)$', fm, re.M)
    if not n or not d: fail.append(f"{p}: name/description ausentes"); continue
    if n.group(1)!=folder: fail.append(f"{p}: name '{n.group(1)}' != pasta '{folder}'")
    if not re.fullmatch(r'[a-z0-9-]{1,64}', n.group(1)): fail.append(f"{p}: name fora do padrão [a-z0-9-]")
    if len(d.group(1))>1024: fail.append(f"{p}: description >1024 chars")
    if len(s.splitlines())>500: fail.append(f"{p}: corpo >500 linhas")
# Checagem unificada de todo hook (hooks/*.json, hooks/diagnostics/*.json e os
# embutidos em agents/*.json — array plano nos dois, confirmado contra o schema
# real do Kiro, ver scripts/gen-agent-profiles.sh): script referenciado existe,
# trigger é um dos reconhecidos pelo Kiro (confirmado no bundle instalado,
# kiro.kiro-agent/dist/extension.js — canônicos + aliases camelCase que o próprio
# Kiro normaliza), matcher de PreToolUse/PostToolUse só cita nome de tool real
# (não capability — 'fs_read'/'fs_write' NUNCA batem com tool_name de verdade, é
# a causa raiz de C2/1.11: os guards por-agente nunca dispararam), e o command não
# usa sintaxe que só bash entende — no Windows o Kiro roda "command" sob cmd.exe
# (spawn shell:true → ComSpec), onde `$(...)`/backtick/`&&`/`||`/`;` não são
# substituição/encadeamento (causa raiz de C3/1.11: hook nenhum rodava no Windows).
VALID_HOOK_TRIGGERS = {
    'SessionStart', 'Stop', 'PreToolUse', 'PostToolUse', 'PreTaskExec', 'PostTaskExec',
    'UserPromptSubmit', 'PostFileCreate', 'PostFileSave', 'PostFileDelete', 'Manual',
    'sessionStart', 'agentStop', 'promptSubmit', 'preTaskExecution', 'postTaskExecution',
    'preToolUse', 'postToolUse', 'fileEdited', 'fileCreated', 'fileDeleted', 'userTriggered',
    'agentSpawn', 'stop', 'userPromptSubmit', 'SessionEnd', 'AfterFileEdit',
}
TOOLUSE_TRIGGERS = {'PreToolUse', 'PostToolUse', 'preToolUse', 'postToolUse'}
KNOWN_TOOL_NAMES = {
    'read_file', 'read_files', 'read_code', 'list_directory', 'file_search', 'grep_search', 'glob', 'grep',
    'fs_write', 'fs_append', 'str_replace', 'delete_file', 'edit_code', 'semantic_rename', 'smart_relocate',
    'execute_bash', 'execute_pwsh', 'run_command',
}
UNPORTABLE_TOKENS = ('$(', '`', '&&', '||', ';')

def check_hook_entry(doc_path, h):
    hname = h.get('name', '?')
    trg = h.get('trigger')
    if trg and trg not in VALID_HOOK_TRIGGERS:
        fail.append(f"{doc_path}: hook '{hname}' trigger '{trg}' fora do conjunto reconhecido pelo Kiro")
    if trg in TOOLUSE_TRIGGERS:
        matcher = h.get('matcher')
        if not matcher:
            fail.append(f"{doc_path}: hook '{hname}' ({trg}) sem matcher — dispara pra QUALQUER tool")
        else:
            cited = set(re.findall(r'[a-z][a-z_]{2,}', matcher))
            unknown = sorted(cited - KNOWN_TOOL_NAMES)
            if unknown:
                fail.append(f"{doc_path}: hook '{hname}' matcher '{matcher}' cita nome(s) de tool desconhecido(s) {unknown} — nomes reais confirmados no bundle do Kiro: {sorted(KNOWN_TOOL_NAMES)}")
    action = h.get('action') or {}
    cmd = action.get('command', '') if action.get('type') == 'command' else ''
    if any(tok in cmd for tok in UNPORTABLE_TOKENS):
        fail.append(f"{doc_path}: hook '{hname}' command usa sintaxe que cmd.exe (Windows) não interpreta: {cmd!r}")
    m = re.search(r'run-hook\.sh\s+(\S+\.sh)\b', cmd)
    if m and not os.path.exists(os.path.join('hooks', 'scripts', m.group(1))):
        fail.append(f"{doc_path}: hook '{hname}' referencia hooks/scripts/{m.group(1)}, que não existe")

for p in glob.glob('agents/*.json') + glob.glob('hooks/*.json') + glob.glob('hooks/diagnostics/*.json'):
    d = json.load(open(p, encoding='utf-8'))
    for e in d.get('hooks', []):
        check_hook_entry(p, e)
# P0-1 — frontmatter dos agents/*.md precisa ser YAML parseável de verdade: o check
# de sincronia (gen-agent-profiles.sh --check) compara texto, não valida YAML — foi
# assim que 4 agentes com ':' na description ficaram com frontmatter inválido sem
# ninguém reprovar. Usa PyYAML se existir; senão, checa que valores com ': ' estão
# entre aspas.
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
    # .replace('\\','/'): glob.glob no Windows devolve separador '\\' — os
    # caminhos citados em doc/agente usam '/', então a comparação abaixo (`rel
    # not in installed_sh`) nunca batia e todo agente/skill que cita um .sh
    # reprovava aqui, mesmo instalado corretamente (mesma classe de bug do
    # IndexError do frontmatter, corrigido acima, mas neste check separado).
    installed_sh.update(f.replace('\\', '/') for f in glob.glob(pat, recursive=True))
sh_doc_sources = (glob.glob('agents/*.json') + glob.glob('agents/*.md') + glob.glob('hooks/*.json')
                   + glob.glob('skills/*/SKILL.md')
                   + [d for d in ('OPERACAO.md', 'README.md', 'steering-base/templates/AGENTS.md') if os.path.exists(d)])
for p in sh_doc_sources:
    s = open(p, encoding='utf-8').read()
    for m in re.finditer(r'\.kiro/([A-Za-z0-9_./-]+\.sh)\b', s):
        rel = m.group(1)
        if rel not in installed_sh:
            fail.append(f"{p}: cita .kiro/{rel}, mas install.sh não instala esse caminho (installed_sh não bate)")
# M5/C1 — skill://X citado em agents/*.md precisa: (a) usar a forma de CAMINHO que
# o resolvedor real do Kiro aceita — confirmado no bundle (kiro.kiro-agent/dist/
# extension.js): 'skill://<nome>' sozinho resolve pra join(workspaceRoot, '<nome>')
# e NUNCA aponta pro SKILL.md de verdade (readFileSync falha, silencioso — a skill
# simplesmente não carrega, nenhum agente jamais viu nenhuma das 14 skills antes
# desta correção); só 'skill://.kiro/skills/<nome>/SKILL.md' (relativo ao
# workspace) e 'skill://~/.kiro/skills/<nome>/SKILL.md' (home, expansão de '~')
# resolvem de verdade; (b) corresponder a uma skill real em skills/.
SKILL_URI_RE = re.compile(r'^skill://(?:\.kiro|~/\.kiro)/skills/([a-z0-9-]+)/SKILL\.md$')
skill_names = {os.path.basename(os.path.dirname(p)) for p in glob.glob('skills/*/SKILL.md')}
for p in glob.glob('agents/*.md'):
    s = open(p, encoding='utf-8').read()
    m = re.match(r'^---\n(.*?)\n---\n', s, re.S)
    if not m: continue  # já reprovado acima (sem frontmatter)
    for uri in re.findall(r'skill://\S+', m.group(1)):
        um = SKILL_URI_RE.match(uri)
        if not um:
            fail.append(f"{p}: resource '{uri}' não usa a forma de caminho que o Kiro resolve "
                         f"(skill://.kiro/skills/<nome>/SKILL.md ou skill://~/.kiro/skills/<nome>/SKILL.md) — "
                         f"'skill://<nome>' sozinho nunca resolve, confirmado no bundle do Kiro")
        elif um.group(1) not in skill_names:
            fail.append(f"{p}: resource {uri} não corresponde a nenhuma pasta em skills/")
for p in glob.glob('steering-base/**/*.md', recursive=True):
    s=open(p, encoding='utf-8').read()
    # p.replace('\\','/'): glob.glob no Windows devolve separador '\\' — o teste
    # 'templates/' in p (literal com '/') nunca batia, então templates/AGENTS.md
    # (que não tem inclusion: de propósito) reprovava aqui em toda máquina Windows.
    pn = p.replace('\\', '/')
    if 'templates/' in pn or '/global/' in pn: continue
    if not s.startswith('---'): fail.append(f"{p}: sem frontmatter inclusion")
link_docs = (['README.md','OPERACAO.md','mcp/README.md','CHANGELOG.md','hooks/VERIFY.md','hooks/README.md',
              'CONTRIBUTING.md','SECURITY.md']
             + glob.glob('examples/*/README.md') + glob.glob('skills/*/SKILL.md') + glob.glob('agents/*.md'))
for doc in link_docs:
    if not os.path.exists(doc): continue
    base = os.path.dirname(doc)
    for l in re.findall(r'\]\(([^)#]+)\)', open(doc, encoding='utf-8').read()):
        if l.startswith('http'): continue
        # link relativo resolve a partir do próprio doc
        if not (os.path.exists(os.path.join(base, l)) or os.path.exists(l)):
            fail.append(f"{doc}: link quebrado -> {l}")
# OPERACAO.md é o único doc operacional agora — se um agente/skill sumir dele, é o
# próximo CATALOGO desatualizado nascendo (M4).
op = open('OPERACAO.md', encoding='utf-8').read() if os.path.exists('OPERACAO.md') else ''
for p in glob.glob('agents/*.json'):
    name = json.load(open(p, encoding='utf-8')).get('name') or os.path.splitext(os.path.basename(p))[0]
    if f"`{name}`" not in op: fail.append(f"OPERACAO.md: agente '{name}' não referenciado")
for p in glob.glob('skills/*/SKILL.md'):
    name = os.path.basename(os.path.dirname(p))
    if f"`{name}`" not in op: fail.append(f"OPERACAO.md: skill '{name}' não referenciada")
# hooks/*.json e mcp/*.json também precisam aparecer referenciados em algum doc
# operacional — mesmo raciocínio anti-drift acima (M4), agora cobrindo o que
# ficou de fora na primeira rodada (B3 da segunda auditoria). Trigger/matcher/
# command de cada hook já são checados no bloco unificado acima.
mcp_readme = open('mcp/README.md', encoding='utf-8').read() if os.path.exists('mcp/README.md') else ''
hooks_readme = open('hooks/README.md', encoding='utf-8').read() if os.path.exists('hooks/README.md') else ''
if not hooks_readme: fail.append("hooks/README.md ausente — é onde 'o que copiar' precisa estar respondido")
for p in sorted(glob.glob('hooks/*.json')):
    base = os.path.basename(p)
    name = base[:-len('.json')]
    if f"`{name}`" not in op and f"`{name}`" not in hooks_readme:
        fail.append(f"OPERACAO.md/hooks/README.md: hook '{name}' não referenciado em nenhum dos dois")
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
    ver = open('VERSION', encoding='utf-8').read().strip()
    chg = open('CHANGELOG.md', encoding='utf-8').read()
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
bash scripts/gen-agent-profiles.sh --check && ok "agents/*.json em sincronia com agents/*.md" || bad "agents/*.json fora de sincronia — rode scripts/gen-agent-profiles.sh"
bash tests/test-check-gates.sh || bad "tests/test-check-gates.sh reprovou"
bash tests/test-install.sh || bad "tests/test-install.sh reprovou"
bash tests/test-worktree.sh || bad "tests/test-worktree.sh reprovou"
bash tests/test-hooks.sh || bad "tests/test-hooks.sh reprovou"
bash tests/test-examples.sh || bad "tests/test-examples.sh reprovou"
[ $FAIL -eq 0 ] && echo "SELFTEST OK" || { echo "SELFTEST REPROVADO"; exit 1; }
