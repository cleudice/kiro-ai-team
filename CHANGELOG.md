# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

> **IDs de auditoria** (`B1`, `M5`, `I4`, `A6`, `P0-1`...): rótulos internos das auditorias que precederam a 1.7/1.8 — o contexto de cada um está nas entradas de versão abaixo. A partir da 1.9 eles ficam restritos a comentários de script e a este arquivo; documentos de usuário e steering não os usam mais.

## [Unreleased]

### Adicionado

- **`steering-base/guidelines/typescript.md`** — projetos TS/Node (ex.: Firebase Functions) não tinham NENHUM guideline disparando (`dotnet.md`/`webforms.md`/`oracle.md`/`flutter.md` casam só com `.cs`/`.aspx*`/`.sql`/`.dart`; nenhum casa com `.ts`/`.tsx`). Sem `dev-*`/`--stack` dedicado (sem `dev-node` no elenco) — vai sempre junto dos outros 4, mesmo esquema (`fileMatch: **/*.ts*`), independente do `--stack`.
- **Auditoria do ecossistema contra o schema real do Kiro** (não mais só a doc pública): o bundle instalado (`kiro.kiro-agent/dist/extension.js`, versão `1.0.406`) foi lido diretamente, e quatro garantias centrais nunca funcionaram em nenhuma instalação — nenhuma falhava em voz alta (viravam `O.warn` num log que ninguém lê, ou simplesmente não disparavam). Itens abaixo.
- **`scripts/run-hook.sh`** — ponto de entrada único de todo `command` de hook (JSON e guards por-agente). Ver "Windows" em Corrigido.
- **`permissions` em `agents/orchestrator.md`/`reviewer-code.md`/`reviewer-spec.md`/`auditor.md`/`qa-blackbox.md`** — camada determinística de bloqueio (`deny` em `src/**`/`lib/**`), aplicada pelo próprio Kiro antes de qualquer tool rodar, confirmada no schema (`k3`/`resolveAgentPermissions`). Os guards por-agente (`readonly-guard`, `qa-blackbox-guard`) continuam como 2ª camada, best-effort e adaptativa (lê `Código-fonte:` do `tech.md` em runtime) — a `permissions` é a 1ª camada, mecânica, que nunca existiu antes.
- **`includeMcpJson: true` + tag `@mcp` em `agents/orchestrator.md`** — sem isso, nenhum agente tinha via de acesso a nenhum servidor MCP (`tools` nunca incluía `@mcp`, `includeMcpJson` nunca era setado); `triage-issue`/`resolve-issue` "contra Jira/Azure Boards/GitHub" rodavam sem conseguir de fato falar com um tracker. Detalhe e como estender a outros agentes: `mcp/README.md`.
- **`hooks/README.md`** — resposta direta e única a "quais hooks copiar, quando, e o script é só do repositório?": tabela do que é `install.sh` automático vs. cópia manual vs. nunca-instalar, e por que o `command` de cada hook usa `run-hook.sh`.
- **Testes**: `tests/test-hooks.sh` ganha casos pro payload real `{tool_name, tool_input}` (antes só o fallback por grep era exercitado — `tool_input` não estava na lista de chaves buscadas) e pro `run-hook.sh` (resolução de engine + propagação de stdin/exit code); `tests/test-install.sh` cobre `run-hook.sh` instalado/manifestado/removido nos 3 escopos.
- **`agents/explore.md`** — 10º papel do elenco (`CORE_AGENTS`, instalado sempre): pesquisa/mapeamento somente-leitura (`tools: [read]`, sem hooks nem permissions — não precisa, não tem tool de escrita). Preenche uma lacuna real: hoje `orchestrator`/`dev-*` fazem toda exploração no próprio modelo caro da sessão; nasceu comparando o elenco central com um agente equivalente que o usuário já mantinha no `~/.kiro` pessoal, adaptado ao idioma e às convenções do time (sem `model:` pinado — mesma política do resto do elenco, ver OPERACAO.md §7).
- **`skills/refine-brief`** — passo opcional entre `triage-issue` e `write-requirements`, só no trilho feature: quando o brief comporta mais de uma direção de PRODUTO razoável (não um detalhe faltando — isso já é `escalation-rules` dentro do `write-requirements`), explora 2-4 direções, critica risco/força de cada uma, converge com o humano, atualiza o próprio brief. Dono: `spec-analyst`. Preenche uma lacuna que o pipeline não tinha: ideação antes de comprometer com uma spec — inspirado numa skill de brainstorm genérica que o usuário já usava fora do kiro-ai-team, mas com saída no formato nativo do time (atualiza `docs/issues/<ID>.md`, não um arquivo novo) em vez de introduzir um artefato paralelo.
- **`CLAUDE.md` gerado pelo installer** — Claude Code não lê `AGENTS.md` automaticamente (confirmado: [anthropics/claude-code#34235](https://github.com/anthropics/claude-code/issues/34235); a própria Anthropic recomenda o import `@AGENTS.md` dentro de um `CLAUDE.md` como forma suportada). Sem isso, uma sessão Claude Code num projeto instalado nunca via as regras do time — o `AGENTS.md` "padrão aberto" do kiro-ai-team ficava mudo justamente pra uma das ferramentas mais comuns. `install_project_layer` agora grava `CLAUDE.md` (`@AGENTS.md`, 1 linha) se ausente; nunca sobrescreve um que já exista.
- **`install.sh --scope hybrid` agora semeia `~/.kiro/steering/principios.md`** — antes só `--scope global` puro fazia isso; hybrid (o caso mais comum de máquina pessoal com múltiplos repos) saía silencioso sem o template, e quem usava hybrid tinha que descobrir sozinho que precisava criar um steering pessoal por conta própria. Extraído pra `seed_global_steering()`, chamado nos dois escopos.
- **`skills/reverse-engineer-project` ganha modo atualização (drift)** — antes só descrevia geração do zero, com "re-rodar eixo quando o auditor detectar drift" como única saída; agora o próprio passo 2 distingue mapeamento (docs/context/ vazio) de atualização (já existe — relê, atualiza só o que divergiu, reporta a mudança), com a regra de que decisão marcada como deliberada vira conflito reportado, não sobrescrita silenciosa. Também documenta explicitamente `docs/context/` como fonte canônica vs. `AGENTS.md`/`CLAUDE.md` como ponteiros finos — princípio que já valia mas nunca estava escrito.

### Corrigido

- **`hooks` embutido em `orchestrator`/`qa-blackbox`/`reviewer-code`/`reviewer-spec`/`auditor` estava no formato ERRADO** — `agents/*.json` declarava `"hooks": {"preToolUse": [{"matcher","command"}]}` (objeto agrupado por trigger), mas o schema REAL do Kiro (confirmado lendo o zod schema embutido no bundle instalado, `kiro.kiro-agent/dist/extension.js`) exige um **array plano**: `[{name, trigger, matcher?, action:{type:"command"|"agent", command|prompt}, timeout?, enabled?, confirm?}]`. O log do Kiro já acusava isso (`Schema validation failed: hooks: Expected array, received object`) — provavelmente esses guards por-agente (defesa em profundidade do isolamento black-box) nunca dispararam de verdade em nenhuma instalação. Corrigido nos 5 `agents/*.json`, no gerador `scripts/gen-agent-md.sh` (agora emite o array correto no frontmatter `.md`) e no checador de `selftest.sh` (`hooks` como lista, não dict).
- **`scripts/gen-agent-md.sh` quebrava com `UnicodeEncodeError` em modo de escrita** (`✔ arquivo.md` no console cp1252) — só não tinha sido pego porque `selftest.sh` só chama `--check`, que não imprime nada quando está tudo sincronizado. Mesmo fix de `sys.stdout.reconfigure`.
- **As 3 causas Windows-only do `continue-on-error` — confirmadas e corrigidas numa máquina Windows real** (Git Bash/MSYS):
  - **`worktree.sh`: sparse-checkout do worktree QA não excluía `src/`** — causa raiz não era `extensions.worktreeConfig` (já correto): o MSYS/Git Bash auto-converte argumentos que parecem path POSIX absoluto, e o padrão `!/src/` passado a `git sparse-checkout set` virava `!C:/Program Files/Git/src/` — nunca casava com nada. Corrigido prefixando a chamada com `MSYS_NO_PATHCONV=1` (inócuo fora do MSYS).
  - **`tests/test-install.sh`: `--update` "não podava" skill removida do central** — não era bug do installer; o passo de setup do teste embutia um path `/tmp/...` dentro de uma string de script `python3 -c "..."` em vez de passá-lo via `sys.argv` — a auto-conversão de path do MSYS não alcança paths dentro do texto do script, e o Python nativo do Windows lia `/tmp/...` como raiz do drive atual (`FileNotFoundError`), corrompendo o setup do caso de teste. Corrigido passando o path via `sys.argv`, mesmo padrão já usado em `install.sh`.
  - **`tests/test-hooks.sh`: `format-dotnet.sh`/`format-flutter.sh` saíam 127 sob o PATH stubado do teste** — a suspeita de "`ln -sf` virando cópia sem modo desenvolvedor" era parcial: o problema real é que binários MSYS (`bash`, `git`, `grep`...) dependem de DLLs (`msys-2.0.dll` etc.) que vivem ao lado do executável real; symlink/cópia isolado sem essas DLLs falha ao carregar. Corrigido: em vez de reconstruir um PATH do zero, o teste agora filtra o `$PATH` real removendo só os diretórios que contêm `dotnet`/`dart`, preservando o resto (DLLs incluídas).
- **`selftest.sh` — bateria inteira de checagens (frontmatter, links quebrados, referências cruzadas com `OPERACAO.md`/`mcp/README.md`, `VERSION`×`CHANGELOG`, sincronia `review-spec`/`review-code`, `docs/archive`) quebrava silenciosamente em locale Windows não-UTF-8**: metade dos `open()` do heredoc Python não tinha `encoding='utf-8'` (herança do fix parcial do IndexError abaixo) — em locale `cp1252` (comum no Windows), a leitura de qualquer `.md`/`.json` com certos bytes UTF-8 lançava `UnicodeDecodeError` sem rodar nada daquele bloco. Corrigido `encoding='utf-8'` em todos os `open()` restantes.
- **`selftest.sh` — depois do fix acima, o próprio `print` do resultado quebrava** (`UnicodeEncodeError` ao emitir `✔`/`✘` no console cp1252), escondendo as falhas reais atrás do traceback. Corrigido com `sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')`.
- **`selftest.sh` — 2 checagens reprovavam por falso positivo no Windows** (mesma classe do IndexError original, em pontos que não foram cobertos por aquele fix): a checagem B1/B3 de `.kiro/<script>.sh` citado em doc comparava paths com `/` contra um `installed_sh` construído via `glob.glob` (que devolve `\` no Windows) — nunca batia; e a checagem de frontmatter `inclusion:` comparava `'templates/' in p` contra o mesmo tipo de path com `\`, reprovando `templates/AGENTS.md` (exceção intencional) em toda máquina Windows. Ambas normalizam o separador antes de comparar.
- **`selftest.sh` IndexError no Windows**: `p.split('/')[1]` assumia separador `/`; `glob.glob` no Windows devolve `\`. Trocado por `os.path.basename(os.path.dirname(p))`.
- **`skill://<nome>` sozinho NUNCA resolvia — nenhum agente carregava nenhuma skill, em nenhuma instalação.** O resolvedor real (`Pn5`, `custom-agents-*.js`) trata `skill://X` como caminho relativo ao workspace (`join(workspaceRoot, "X")`), não como um nome — `readFileSync` falhava e o Kiro só emitia `O.warn("resource-resolver.skill.read_failed")` e seguia sem a skill, silenciosamente. As 14 skills do time nunca foram lidas por nenhum dos 9 agentes. Corrigido: todo `resources:` agora usa as duas formas de caminho que o resolvedor aceita (`skill://.kiro/skills/<nome>/SKILL.md` e `skill://~/.kiro/skills/<nome>/SKILL.md`, cobrindo os 3 escopos). Agravante: `selftest.sh` validava ativamente o formato ERRADO (exigia a forma sem caminho) — o CI protegia o bug; o check foi reescrito pra exigir a forma que o Kiro de fato resolve.
- **`matcher` dos guards por-agente (`qa-blackbox-guard`, `readonly-guard`) citava CAPABILITY (`fs_read`/`fs_write`), não nome de tool — os guards nunca dispararam.** `matcher` de `preToolUse` casa contra `tool_name`, e o nome real nunca é `fs_read`/`fs_write` (confirmado em `TOOL_CAPABILITY_MAP`/`TOOL_NAME` no bundle) — é `read_file`, `str_replace`, `execute_bash` etc. `qa-blackbox-guard` com `matcher: "fs_read"` não casava com tool nenhuma; `readonly-guard` com `matcher: "fs_write"` casava só com a tool `fs_write`, deixando `str_replace` (o caminho mais comum de edição) passar direto. Corrigido: `matcher` agora é uma alternância dos nomes reais (lista em `hooks/README.md`); `selftest.sh` reprova qualquer matcher de `PreToolUse`/`PostToolUse` que cite algo fora dessa lista.
- **Todo hook quebrava no Windows — o `command` nunca rodava.** O Kiro executa `command` via `spawn(cmd, {shell:true})`; no Windows isso é cmd.exe, não bash. O `command` antigo (`bash "$(bash .kiro/scripts/kiro-paths.sh)/hooks/scripts/X.sh"`) usa `$(...)` e aspas aninhadas — sintaxe de bash que cmd.exe não interpreta (o argumento chegava literal, nunca resolvendo ao script). O CI cobre `windows-latest`, mas rodando `selftest.sh` sob Git Bash — outro caminho de execução; o `spawn` sob cmd.exe nunca foi exercitado por nada. Corrigido: novo `scripts/run-hook.sh` como única invocação de shell no `command` (sem `$()`/aninhamento — válido sob cmd.exe e sob bash/sh); todo `hooks/*.json` e os 5 guards embutidos em `agents/*.md` migrados. `selftest.sh` reprova qualquer `command` de hook que contenha `$(`, backtick, `&&`, `` || ``, ou `;`.
- **`agents/*.json` e `agents/*.md` do mesmo agente colidiam no `ProfileLoader` da IDE — só o `.md` vencia, com um aviso (`Duplicate agent ID ... overwriting`) que ninguém via.** O `ProfileLoader` varre `.kiro/agents/**` aceitando `.md` e `.json`, deriva o mesmo `agentId` dos dois (nome do arquivo sem extensão) e, num empate, o último por ordem alfabética vence (`.json` < `.md`) — ou seja, o `.json` nunca foi o perfil de verdade na IDE, mesmo sendo a fonte histórica do gerador. Corrigido: direção do gerador invertida (`scripts/gen-agent-md.sh` → `scripts/gen-agent-profiles.sh`) — `agents/*.md` (o que a IDE de fato usa) passa a ser a fonte autorada; `agents/*.json` (perfil CLI) é gerado, e leva `allowedTools` sem `permissions` — o par de condições que o próprio `ProfileLoader` usa pra reconhecer "perfil CLI-only" e IGNORAR o arquivo inteiro na IDE (`lt2`/`pe21` no bundle), eliminando a colisão. `permissions` (a camada determinística nova) fica só no `.md`, de propósito.
- **`hooks/scripts/guard-common.sh` nunca reconhecia o payload real do Kiro.** O payload de `preToolUse` (confirmado na função `j()` do bundle) é `{session_id, hook_event_name, cwd, tool_name, tool_input}` — `tool_input` não estava na lista de chaves buscadas por `guard_payload_path`, então todo guard caía sempre no fallback por grep, mesmo com payload JSON bem-formado. Corrigido: `tool_input` (e `paths`, pra tools de leitura múltipla) entram na busca, com suporte a descer em listas.

### Alterado

- **Direção de `agents/*.md`↔`agents/*.json` invertida** (ver Corrigido acima) — `scripts/gen-agent-md.sh` renomeado pra `scripts/gen-agent-profiles.sh`; edite sempre o `.md`, nunca o `.json` à mão. `CONTRIBUTING.md`/`OPERACAO.md`/`install.sh` atualizados.
- **`hooks/VERIFY.md` reescrito** — a postura "nenhum trigger confirmado" (doc pública apenas) dá lugar a "confirmado por leitura do schema real, pendente confirmação empírica": os 10 triggers existem no bundle com runner dedicado cada um, incluindo `PostTaskExec` (que a versão anterior deste documento registrava como ausente de qualquer doc pública). O payload de `preToolUse` e a causa raiz Windows também documentados ali, com o procedimento de confirmação empírica atualizado pra também provar carregamento de skill e do `command` via `run-hook.sh`.
- **README/OPERACAO corrigidos sobre o escopo global**: "IDE ignora `KIRO_HOME`" era impreciso — a IDE carrega `~/.kiro/agents`, `~/.kiro/steering` e `~/.kiro/skills` normalmente (`loadUserCustomAgents` etc. no bundle); o que ela ignora é especificamente a variável de ambiente `KIRO_HOME` (usa sempre `$HOME/.kiro`, fixo) — `--kiro-home <dir>` customizado só vale pra CLI.
- **`mcp/README.md`** ganha a seção "um agente só alcança MCP se declarar isso" — mesclar um fragmento em `mcp.json` nunca foi suficiente; documenta o mecanismo (`includeMcpJson`+`@mcp`) e que hoje só `orchestrator` o declara.

- **CI: `windows-latest` volta a ser bloqueante** — as 3 causas do `continue-on-error` anterior foram depuradas numa máquina Windows real (ver acima); `bash selftest.sh` roda limpo (`SELFTEST OK`) nesse ambiente agora. `windows-latest` tem a mesma exigência de `ubuntu-latest`/`macos-latest`.

## [1.10.0] — 2026-07-25

Release da análise crítica do ecossistema: fecha as três garantias que ainda furavam em silêncio — o isolamento black-box valia só para `src/` literal (errado para 2 dos 3 stacks suportados), o vínculo evidência↔commit era pulado sem aviso quando a branch não resolvia, e o vocabulário de trilho tinha um valor (`spec-completa`) que nenhum script reconhecia. Também corta gordura estrutural (skill redundante, harness de teste copiado 5×, guards duplicados byte-a-byte).

### Adicionado

- **`Código-fonte:` no `tech.md` — diretórios de implementação configuráveis** (default `src/`): o isolamento black-box inteiro (worktree `--qa`, `qa-blackbox-guard.sh`, `readonly-guard.sh`) dependia do literal `src/` — num repo Flutter (`lib/`) ou WebForms legado (raiz/módulos), o worktree QA baixava o código inteiro e os guards nunca disparavam, silenciosamente. Agora `worktree.sh` e os guards leem a linha `Código-fonte:` (lista separada por espaço; helper `code_dirs()` em `hooks/scripts/lib.sh`); a barreira segue o stack, não o literal. Testes com `lib/` em `test-worktree.sh` e `test-hooks.sh`.
- **`--allow-missing-branch "<motivo>"`** em `check-gates.sh`: sem branch `pbi/<ID>` resolvível, o vínculo evidência↔commit (B2) era **pulado em silêncio** — PBI feito em branch com outro nome, ou branch já deletada, virava aprovação sem vínculo nenhum (a única checagem do sistema que degradava para "passa" por omissão, contra a regra da 1.9). Agora reprova por padrão; o escape é explícito e registrado no `gate.md`, como todos os outros.
- **Validação de `--track`**: valor fora de `feature|manutencao` era engolido pelo `else` do G0 e virava trilho feature mudo — agora é `exit 2` com mensagem, mesma postura do `install.sh` com `--scope`/`--stack`.
- **Lock (`mkdir`, portável) no `bump-counter`**: o read-modify-write de `.merge-count` perdia contagem com dois merges concorrentes; a serialização era só convenção.
- **`hooks/scripts/guard-common.sh`** — extração de payload e casamento com os diretórios de código, únicos; `qa-blackbox-guard.sh` × `readonly-guard.sh` carregavam ~28 linhas byte-a-byte idênticas (a mesma classe de duplicação que motivou o `lib.sh` da 1.9, um nível acima).
- **`tests/lib.sh`** — harness (`pass`/`fail`/`expect_exit`/`assert_*`) único; estava copiado nas 5 suítes.
- **Testes de G0** (`test-check-gates.sh`): era o único gate com zero casos — ausente avisa sem bloquear, draft `APROVADO` reconhecido, trilho manutenção não o avalia.
- **Backup no installer**: `quality-gates.md`/`workflow.md`/`escalation-rules.md`/guidelines customizados localmente eram sobrescritos no `--update` sem aviso nem cópia; agora, se o arquivo difere do central, a versão anterior vai para `.bak` com aviso. Installer também aplica `chmod +x` nos scripts copiados (a forma `.kiro/scripts/worktree.sh start X` citada em prompts dependia do bit sobreviver ao `cp`).
- **Ledger registra o `--test-cmd` executado** — `tech.md` é código executável (`bash -c`); `SECURITY.md` agora declara essa superfície com todas as letras (tech.md e `.kiro-ai-team-paths` exigem revisão de PR como mudança de CI) e cada execução dos gates deixa o comando auditável em `.gate-ledger`.

### Corrigido

- **Vocabulário de trilho unificado de verdade**: a 1.9.0 declarou `tasks-minimas` → `manutencao`, mas o lado feature ficou pela metade — `triage-issue` e o brief do PBI-FEATURE ainda emitiam `Trilho recomendado: spec-completa`, valor que `check-gates.sh` nunca reconheceu. Agora é `feature` nos dois, e a regra do vocabulário está escrita na própria skill.
- **`preflight-branch.sh` acoplado ao literal `^- [ ]`**: `tasks.md` com bullet `*`/`+` nunca disparava o aviso — exatamente a rigidez que o `task-checkpoint.sh` já tinha corrigido na 1.9 (inconsistência entre scripts irmãos).
- **Regex de extração do `tech.md` era gulosa** (`extract_cmd` e o parser novo): com um segundo par de crases na mesma linha (ex.: exemplo dentro de comentário HTML do template), capturava o **último** par, não o comando — latente no `task-checkpoint.sh` desde sempre, exposto ao escrever o parser de `Código-fonte:`.
- **Duas semânticas de "G5" convivendo**: o bloco de gates do `write-tasks` dizia `G5. merge-gate`, enquanto `quality-gates.md` define G5 como a regressão de integração (o merge-gate é o executor de TODOS os gates). Agente lendo `tasks.md` e agente lendo o steering tinham modelos diferentes; o bloco (e os exemplos) agora nomeiam a regressão.
- **`OPERACAO.md` §3 mentia sobre o `PBI-EXEMPLO`** ("brief + spec + evidência dos 5 gates"): o exemplo é trilho manutenção — não tem `requirements.md`/`design.md`, e G5 é dispensado por `--skip-g5`. A descrição agora bate com o fixture; `hooks/VERIFY.md` apontava para um "§1.2" que não existe; a tabela de ciclo de vida (§11) ganhou a linha do `.merge-count` (gerado e gitignorado, mas ausente do inventário).

### Removido

- **Skill `triage-crash`** (13 linhas): era `triage-issue` com origem `crashlytics` — ela própria declarava "saída SEMPRE no formato padrão de brief". Fundida como passo da `triage-issue` (mesmos triggers na description); sai do `orchestrator.json` e é podada nos projetos pelo manifesto no `--update`. Mapa em `docs/archive/MIGRATION-v1.md`.
- **Tabela de renomeações v1 do README** (10% do arquivo, arqueologia para quem chega hoje) — movida para `docs/archive/MIGRATION-v1.md`; no lugar entrou **"Primeiros 5 minutos"**, o passo-a-passo pós-instalação que o README nunca teve (delegava tudo ao OPERACAO.md sem dizer nem o primeiro passo).

## [1.9.0] — 2026-07-25

Release da auditoria "padrão ouro": fecha as classes de fragilidade concentradas na _entrada_ do ciclo (spec sem revisão adversarial, G1 dispensável por omissão), no _isolamento_ (black-box sustentado só por prompt) e nos _hooks_ (290 linhas de shell sem um único teste comportamental).

### Adicionado

- **G0 — revisão adversarial da spec** (`review-spec` em modo draft, `docs/reviews/<PBI>-spec-draft.md`): a spec era a única etapa do ciclo aprovada por quem a escreveu — violava o princípio fundador ("nenhum agente aprova o próprio trabalho") justamente na etapa mais cara de errar. Nesta versão `check-gates.sh` avisa quando ausente (trilho feature); vira bloqueante na 2.0.
- **Isolamento físico do qa-blackbox** — `worktree.sh start <PBI> --qa` cria worktree próprio (branch `qa/pbi/<ID>`) com sparse-checkout **sem `src/`**: a regra central do sistema deixa de depender de prompt + guard que falha aberto e vira invariante estrutural.
- **`--no-new-criteria "<motivo>"`** — a dispensa do G1 no trilho manutenção era inferida da AUSÊNCIA de `docs/tests-spec/<slug>.md`: o único ponto do sistema onde falta de evidência virava aprovação, e a forma de burlar era não criar um arquivo. Agora a dispensa é flag explícita e registrada; ausência sem flag reprova.
- **`--allow-blocked "<motivo>"`** — G2 com `BLOCKED` legítimo (legado sem ambiente de smoke, ex.: WebForms/IIS) tinha um beco sem saída documentado e sem escape; agora tem o escape explícito, análogo ao `--skip-g5`.
- **`check-gates.sh reset-counter`** — zera o contador de merges e grava o marco (data+SHA) em `docs/reviews/.last-audit`; sem isso o aviso "AUDITORIA DEVIDA" disparava para sempre a partir do 5º merge (o rearme era um `echo 0` manual que ninguém tinha como passo), e a "janela desde a última auditoria" do `audit-integration` não tinha referência em disco.
- **`readonly-guard.sh`** embutido em orchestrator/reviewer-spec/reviewer-code/auditor (`preToolUse`/`fs_write`): a assimetria de mecanização protegia só a leitura do qa-blackbox enquanto 4 papéis "não corrigem nada" tinham `write` amplo vigiado só por prompt. Mesmo contrato honesto do qa-guard: falha aberto.
- **`tests/test-hooks.sh`** — 26 casos cobrindo os 6 scripts de hook + guards + `lib.sh` (antes: zero teste comportamental em 290 linhas com histórico de bug). O teste já pagou: expôs loop infinito no `find_up` com path relativo.
- **`tests/test-examples.sh`** — executa a promessa literal do README do PBI-EXEMPLO (`GATES OK`, exit 0) e valida a rastreabilidade tripla R#.# do PBI-FEATURE; os exemplos eram fixtures executáveis que nenhum CI executava (e já estiveram quebrados sem ninguém notar, ver 1.7.0).
- **`hooks/scripts/lib.sh`** — `newest_of`/`resolve_file`/`find_up`/`unfilled`/`require_tool`/`cd_repo_root` únicos; antes duplicados byte-a-byte nos dois format-* com `find_up` de MESMO nome e semântica divergente (um devolvia arquivo, outro diretório).
- **CI**: job `windows-latest` (o histórico de bugs do repo é majoritariamente Windows e nenhum CI cobria), `shellcheck -S warning` (3 bugs P0/P1 do histórico eram exatamente da classe que `-S error` deixa passar), `workflow_dispatch`, execução dos exemplos via selftest.
- **Processo**: `CONTRIBUTING.md` (as regras que o CI impõe, em prosa), `SECURITY.md`, templates de issue/PR (no formato de brief do próprio produto), `dependabot.yml`. Tags retroativas `v1.6.0`/`v1.6.1` criadas — o README promete "versionado por tag" e as duas maiores versões do CHANGELOG não tinham tag.

### Corrigido

- **Contradição doc×código sobrevivente da 1.7.0**: `OPERACAO.md` §9 e o cabeçalho do próprio `check-gates.sh` ainda diziam "HEAD atual" onde o código compara com o **último commit de código** (exclui `docs/reviews`/`docs/tests-spec`). O texto dos dois agora descreve o algoritmo real; a linha equivalente nos SKILL.md de review ganhou marcador de sincronia conferido pelo selftest.
- **`check-oracle.sh` reprovava todo package PL/SQL**: o regex de DDL casava `\b(CREATE)\b` — logo TODO `CREATE OR REPLACE PACKAGE/PROCEDURE` exigia rollback ao lado, hook vermelho em todo save (aviso constante é aviso ignorado — a mesma lição do I7, aplicada uma regra acima). Agora só DDL estrutural (DROP/TRUNCATE/ALTER TABLE/CREATE TABLE|INDEX|SEQUENCE); com fixtures de verdadeiro-positivo e verdadeiro-negativo.
- **`hooks/scripts/*.sh` órfãos no `--uninstall`**: eram copiados mas nunca registrados no manifesto — sobreviviam à desinstalação para sempre (mesma classe do I5, um nível abaixo). Novo campo `hook_scripts` no manifesto; instalação pré-1.9 remove pelo conjunto do central atual (melhor aproximação).
- **`worktree.sh start` não idempotente**: com 3 donos declarados na doc (orchestrator, qa, humano), quem chegasse em segundo morria com "branch já existe" sob `set -e` — falso bloqueio na sessão do agente. Agora reusa; dono único documentado (orchestrator).
- **`find_up` em loop infinito com path relativo** (`dirname "." == "."`) — pré-existente nos dois format-*, exposto pelo teste novo; o dir agora é canonicalizado.
- **Hooks de format sem guarda de toolchain**: máquina sem `dotnet`/`dart` (ou repo multi-stack com hook do stack errado) ficava com hook vermelho em TODO save; agora `require_tool` avisa e sai 0. `KIRO_HOOK_BUILD=0` desliga o build por save em solução onde o incremental custa caro. Todos os scripts de hook agora fazem `cd` pra raiz do repo (dependiam de cwd == raiz do workspace sem garantia nenhuma).
- **`--skip-g5` gravava `<PBI>-gate.md` por append**: 3 execuções = 3 blocos idênticos empilhados, e gravava mesmo com outros gates reprovados (contradizendo a doc "só quando recusado"). Agora: bloco único idempotente entre marcadores, gravado só quando a execução termina verde, cobrindo os 3 escapes.
- **`grep -ozE` GNU-only no qa-blackbox-guard**: em macOS/BSD falhava engolido por `2>/dev/null` e o guard ficava inerte — trocado por `grep -oE` portátil. `manifest_field`/selftest interpolavam path dentro de string python (path com `'` quebrava); agora `sys.argv`, como `write_manifest` já fazia.
- **`cp -rf` de skills nunca removia arquivo morto** dentro de uma skill no destino — agora remove-e-recopia por skill. Uninstall também limpa as 3 linhas que o installer adicionou ao `.gitignore` e os diretórios vazios.
- **`task-checkpoint.sh` acoplado ao literal `^- Build:`** do template — bullet trocado (`*`) quebrava silencioso com mensagem errada; o marcador de lista agora é tolerante.
- **Vocabulário de trilho unificado**: `tasks-minimas` → `manutencao` (o brief do PBI-EXEMPLO — "o modelo que se copia" — ensinava o valor que nenhuma skill reconhece, e ele também não tinha a linha `status:` introduzida na 1.8.0; mesma classe de bug de fixture da 1.7.0, reintroduzida por outro caminho).

### Alterado

- **Donos de skill corrigidos no fluxo**: `write-tasks` no trilho manutenção é do **orchestrator** (o trilho mais frequente tinha um passo cujo único dono declarado era o spec-analyst, definido como "só trilho feature"); `retrospective` também no orchestrator (os gatilhos — reprovação/escalação repetida — são eventos que ELE observa, não o auditor).
- **`steering-base/quality-gates.md` em dieta**: é `inclusion: always` (custa tokens em toda sessão de todo agente) e carregava justificativa de design em vez de regra — o racional da mecanização/B2 migrou pra `OPERACAO.md` §9; os IDs de auditoria saíram dos docs de usuário (legenda no topo deste arquivo). Dedup: a regra de build/env agora vive só em `escalation-rules.md` (era quase-verbatim nos dois).
- **`OPERACAO.md`**: documenta a máquina de estados `status:` (a feature-título da 1.8.0 nunca tinha chegado ao doc operacional), a exceção do dono do G2, os escapes novos, o `.last-audit`, troubleshooting de instalação e a nova seção §16 (upgrade entre versões — o que `--update` NÃO faz sozinho). `README.md`: pré-requisito `python3`, `--prune-unmanaged`, e a ressalva honesta de que os triggers de hook seguem não verificados (`hooks/VERIFY.md`) — a página de entrada silenciava a maior incerteza conhecida do produto.
- **`selftest.sh`**: link-check estendido (CHANGELOG, VERIFY, CONTRIBUTING, SECURITY, exemplos, SKILL.md, agents/*.md), allowlist de triggers de hook (typo de trigger = hook que nunca dispara, silencioso), check de sincronia do bloco compartilhado dos reviews, e as 2 suítes novas. `hooks/_canary.json` movido pra `hooks/diagnostics/` (instrumentação não fica no glob que o usuário copia).

## [1.8.0] — 2026-07-25

Fecha o backlog estrutural da quarta auditoria (itens que não dependiam de um Kiro real).

### Adicionado

- **Estado do PBI em disco** — linha `status:` no brief `docs/issues/<ID>.md` (`aberto → em-spec → em-dev → em-review → merged → done`), com a transição atualizada pela skill dona de cada etapa (`triage-issue`, `write-requirements`, `task-preflight`, `verify-change`, `merge-gate`, `resolve-issue`). Antes o orchestrator tinha que reconstruir o estado por inspeção de arquivos a cada sessão nova.
- **`examples/PBI-FEATURE/`** — exemplar do trilho feature (o que faltava): brief, `requirements.md` EARS completo (erro, borda, não-funcionais), `design.md` com contrato público completo (`Cobre: R#.#`) e `tests-spec` — rastreabilidade tripla R#.# demonstrada de ponta a ponta.
- **Esqueletos de saída em `write-requirements` e `write-design`** — eram as skills mais rasas do repo sendo a frente da pipeline; agora especificam o formato no nível das skills de gate, incluindo a definição operacional de "contrato completo" (assinatura + entrada + toda saída de sucesso e de erro + `Cobre:`).
- **Orientação de `model` por agente** (OPERACAO.md §7) — tiering recomendado (reviewers/auditor no tier forte) e como descobrir os IDs válidos (`/model`); IDs não são versionados no central porque variam por instalação.

### Alterado

- **`task-checkpoint`: `agent` → `command`** (`hooks/scripts/task-checkpoint.sh`) — checkpoint é determinístico (build+testes do `tech.md`); não precisa de um turno de modelo inteiro por task marcada `[x]` (mesma racional do I5 nos `format-*`). Detecta placeholder não preenchido e reporta só em falha.
- **`preflight-branch`: shell inline no JSON → `hooks/scripts/preflight-branch.sh`** — lintável (`bash -n`/shellcheck via glob do selftest) e testável; JSON resolve via `kiro-paths.sh` como os demais.
- **Linguagem dos hooks rebaixada para "experimental"** em `task-preflight/SKILL.md` e OPERACAO.md §2 — `PostTaskExec` segue não confirmado contra um Kiro real (`hooks/VERIFY.md`); chamar de "caminho padrão" contradizia a própria tese do repo (autorrelato não conta). O caminho padrão volta a ser o checkpoint manual até o VERIFY confirmar.

## [1.7.0] — 2026-07-25

Quarta auditoria de ecossistema (três varreduras paralelas: agents/hooks/mcp, skills/steering/docs, scripts/install/tests/CI), com verificação manual dos achados críticos antes de corrigir.

### Corrigido (bloqueantes)

- **Frontmatter YAML inválido em 4 agentes `.md`** — `gen-agent-md.sh` emitia `description:` sem aspas; `orchestrator`, `auditor`, `reviewer-code` e `reviewer-spec` têm `: ` na description, o que quebra o parse YAML (o IDE do Kiro podia falhar ao carregar os 4). Agora `description`/`matcher`/`command` saem via `json.dumps`; `selftest.sh` ganhou parse YAML real dos frontmatters (o check de sincronia comparava texto e nunca teria pego).
- **`.gate-ledger` era gravado no worktree do PBI** — que `worktree.sh finish` apaga; o dado de auto-avaliação do processo nunca sobrevivia. Agora vai pro repo principal, mesma resolução do `bump-counter` (I4).
- **G1b reprovava falso em worktree recém-criado** — o log era redirecionado pra `docs/reviews/` antes de qualquer `mkdir -p` (git não versiona diretório vazio): suíte verde aparecia como "G1b suíte FALHOU".
- **Hooks `format-*` quebravam em `hybrid`/`global`** — path relativo `.kiro/hooks/scripts/` hardcoded nos 3 JSONs; agora resolvem via `kiro-paths.sh`, mesmo padrão do guard do `qa-blackbox` (B3 completo).
- **Resolução de worktree truncava paths com espaço** — `awk '{p=$2}'` sobre `git worktree list --porcelain` pegava só o primeiro token (norma no Windows, ambiente declarado como suportado); trocado por `sub()`.
- **Fluxo literal do merge abortava no `finish`** — `worktree.sh finish` exige o merge presente em `origin/<main>` (`merge-base --is-ancestor`), mas nenhum documento mandava dar `git push`. `merge-gate/SKILL.md` e `OPERACAO.md` agora explicitam o push antes do `finish`.
- **Doc do B2 contradizia o código** — `quality-gates.md` (injetado em toda sessão) dizia "HEAD atual"; `check-gates.sh` compara com o último commit de **código** (exclui `docs/reviews/**`/`docs/tests-spec/**`). A versão errada induzia refazer gate sem necessidade. Corrigido também em `OPERACAO.md` §7.

### Corrigido (robustez)

- `install.sh`: `warn_version_mismatch` rodava depois dos installs gravarem a mesma versão nos dois manifestos (nunca disparava — código morto); movido pra antes. Flag desconhecida (ex.: `--updte`) e diretório inexistente viravam DEST e ganhavam uma instalação — agora reprovam cedo. Array vazio sob `set -u` abortava `--update` no bash < 4.4 (macOS 3.2, RHEL 7) — guard `${ARR[@]+...}`. `--uninstall` hybrid deixava o manifesto do projeto órfão apontando scripts removidos. `--help` despejava os comentários internos inteiros; agora só o bloco de uso.
- `format-{dotnet,flutter}.sh`: o fallback git pegava o último arquivo em ordem **alfabética** (`sort | tail -1`), não o salvo por último — agora por mtime (`newest_of`); logs em `mktemp` em vez de `/tmp/*.log` fixo (colisão entre worktrees concorrentes).
- Fixture `examples/PBI-EXEMPLO`: a evidência não tinha a linha-âncora `Commit:` que as skills exigem — o modelo que se copia ensinava o formato errado. Referências mortas a `MANUAL.md`/`QUICKSTART` (deletados na v1.6.0) removidas.

### Alterado

- Cláusulas comuns dos 3 `dev-*` (escopo travado, uma task por vez, verde por task, escalar ambiguidade, não aprova o próprio trabalho) estavam triplicadas literalmente nos prompts — drift esperando acontecer. Fonte única agora é `steering-base/workflow.md` (`inclusion: always`); cada prompt de dev só carrega o específico do stack.
- `OPERACAO.md` §9 declara `quality-gates.md` como fonte canônica da tabela de gates (a tabela ali é resumo derivado).
- `mcp/README.md`: critério explícito de `autoApprove` (só leituras de tracker; nunca escrita; nunca banco/experimental) e nota sobre `${AZDO_ORG}` em `args` (posicional, não-segredo, e o modo de falha quando ausente).

### Adicionado (testes e CI)

- `tests/test-check-gates.sh` (+3): ledger sobrevive ao worktree; G1b verde em worktree sem `docs/reviews/`; path com espaço resolve.
- `tests/test-install.sh`: `hooks/scripts/` instalados por escopo (regressão B3), manifesto removido no uninstall hybrid, logs em `$TMP` e impressos em falha (antes um assert vermelho no CI não dava diagnóstico nenhum).
- CI: shellcheck `-S error` em todo o shell; matriz `ubuntu`+`macos` (onde bash 3.2 pegaria o bug de array); `permissions: contents: read`; `timeout-minutes`; `concurrency`; gate de bump VERSION/CHANGELOG em PR que muda comportamento.

## [1.6.1] — 2026-07-24

Terceira auditoria de ecossistema — corrige bloqueantes que sobreviveram às duas anteriores: um passo estrutural do fluxo (`worktree.sh`) que nunca chegava a ser instalado, um agente sem a ferramenta necessária pra executar a própria skill, e dois dos três escopos de instalação quebrando caminhos hardcoded silenciosamente.

### Corrigido (bloqueantes)

- `scripts/worktree.sh` — nunca era instalado em lugar nenhum (`install.sh` copiava `agents/`, `skills/`, `hooks/scripts/`, mas não `scripts/`), apesar de todo prompt de `orchestrator`/`qa-blackbox` e toda skill (`task-preflight`, `write-blackbox-tests`, `merge-gate`) mandarem rodar `scripts/worktree.sh start <PBI>`. É o passo mais estrutural do sistema (1 PBI = 1 worktree) e o único que faltava. `install_engine`/`install_project_layer` agora copiam `worktree.sh` para `.kiro/scripts/`; todos os caminhos citados em agente/skill/hook/doc passam a `.kiro/scripts/worktree.sh`.
- `reviewer-spec` ganhou a tool `shell` — sem ela, o agente dono do gate G3 não conseguia rodar `git diff main...pbi/<ID>` (passo 1 da própria skill `review-spec`), o insumo básico da revisão de conformidade.
- Escopos `global`/`hybrid` — caminhos `.kiro/...` hardcoded (guard `preToolUse` do `qa-blackbox`, invocação de `check-gates.sh` em `merge-gate/SKILL.md`/`OPERACAO.md`/`AGENTS.md`) assumiam que a engine estava sempre em `.kiro/` do projeto; em hybrid/global ela mora em `$KIRO_HOME`, e o guard falhava aberto silenciosamente. Novo resolvedor `scripts/kiro-paths.sh` — instalado no caminho fixo `.kiro/scripts/kiro-paths.sh` em TODO escopo — imprime a raiz real da engine (lida de `.kiro/.kiro-ai-team-paths`, gravado pelo installer); consumidores passam a resolver via `ENGINE="$(bash .kiro/scripts/kiro-paths.sh)"` em vez de caminho fixo.
- Manifesto (`.kiro-ai-team-version`) ganha o campo `scripts` — resolve de quebra o I5 da auditoria anterior (`hooks/scripts/*.sh` não eram removidos no `--uninstall`; agora `scripts/` também é rastreado e removido corretamente, inclusive a camada fina do projeto no escopo hybrid via `uninstall_project_scripts`).

### Adicionado (testes e verificação)

- `tests/test-install.sh` — casos novos: `scripts/worktree.sh`/`kiro-paths.sh` instalados e resolvendo certo nos três escopos (`project`, `global`, `hybrid`); `--uninstall` limpa a camada fina do projeto em hybrid sem tocar steering/docs.
- `selftest.sh` — novo check mecânico: todo caminho `.kiro/<algo>.sh` citado em agente/skill/hook/doc precisa corresponder a um arquivo que `install.sh` de fato instala (é o check que teria pego o `worktree.sh` nunca instalado antes desta correção); e todo `skill://X` referenciado em `agents/*.json` precisa existir em `skills/`.

## [1.6.0] — 2026-07-24

Segunda auditoria completa do ecossistema, sobre o estado já corrigido em `[1.5.1]` — fecha os furos que ainda permitiam contornar a garantia central (poda apagando artefato do projeto, evidência de gate sem vínculo com commit, hooks nunca verificados empiricamente), mais bloqueantes/installer/mecanização herdados do trabalho anterior e ainda não lançados.

### Corrigido (segunda auditoria — furos na garantia central)

- `install.sh --update` não apaga mais agentes/skills próprios do projeto: a poda agora compara contra o que o **manifesto anterior** registra como instalado pelo time, não contra o diretório inteiro (o comportamento antigo apagava artefatos do projeto sem aviso — contradizia a "dualidade" do README). `--prune-unmanaged` restaura o comportamento antigo, explícito.
- `check-gates.sh` agora exige a linha-âncora `Commit: <sha>` em `docs/reviews/<PBI>-{verify,spec,code}.md` e no log de G5, batendo com o último commit de CÓDIGO de `pbi/<ID>` (não o HEAD literal — um commit que só toca `docs/reviews/**`/`docs/tests-spec/**`, ou seja, a própria evidência sendo commitada depois da revisão, não invalida o vínculo) — antes, aprovar um commit e commitar código novo no mesmo PBI ainda passava nos gates, porque a evidência não estava amarrada a nenhum commit específico.
- `hooks/VERIFY.md` + `hooks/_canary.json` — procedimento e instrumentação pra verificar empiricamente, num Kiro real, se cada `trigger` de hook (`PostFileSave`, `PostFileCreate`, `SessionStart`, `PostTaskExec`) de fato dispara. Nenhum desses triggers tinha sido confirmado contra o produto real antes desta auditoria.

### Corrigido (importantes)

- `team.yaml` removido — órfão, nenhum script/doc o lia, e duplicava `VERSION` (segunda fonte da verdade que só podia divergir).
- `worktree.sh finish` já recusava remover um worktree com alterações não commitadas; `merge-gate/SKILL.md` agora deixa explícito que a evidência dos gates (`docs/reviews/<PBI>-*.md`, `docs/tests-spec/<slug>.md`) precisa ser commitada em `pbi/<ID>` antes do merge — e que `--force` nunca é resposta pro aviso.
- `check-gates.sh bump-counter` sem `--repo` agora resolve o **repo principal** (primeiro bloco de `git worktree list --porcelain`), não o `cwd` — evitava que o contador de auditoria fosse gravado no worktree do PBI que `worktree.sh finish` está prestes a apagar.
- Hooks `format-dotnet`/`format-flutter` convertidos de `action.type=agent` pra `command` (`hooks/scripts/format-{dotnet,flutter}.sh`) — não precisam mais de um turno de modelo inteiro só pra rodar `dotnet format`/`dart format` a cada save; mesmo padrão já usado em `format-oracle` desde a auditoria anterior.
- `install.sh` verifica `python3` no PATH e falha cedo com mensagem acionável (dependência dura não declarada — problema real em Git Bash no Windows, ambiente que o repo suporta explicitamente).
- `check-oracle.sh`: heurística de concatenação `||` restrita a arquivos que também contêm SQL dinâmico de verdade (`EXECUTE IMMEDIATE`/`OPEN...FOR`/`DBMS_SQL`) — a versão anterior disparava em qualquer `||` perto de aspas, falso positivo garantido em PL/SQL comum.
- `preflight-branch` só avisa quando há spec com task **pendente** (`- [ ]`), não qualquer `tasks.md` — evitava aviso em toda sessão mesmo com PBI já fechado (aviso constante é aviso ignorado).
- `tests/test-worktree.sh` — nova suíte cobrindo `scripts/worktree.sh` (start/finish, evidência não commitada bloqueia remoção); `selftest.sh` passa a rodar também esta.

### Corrigido (higiene)

- Tabela quebrada em `README.md` ("Regra de ouro") — pipes não escapados estouravam as colunas.
- `.gitignore` adicionado ao central e ao template do projeto (`install_project_layer`) — `docs/reviews/.gate-ledger`, `.merge-count` e `*-g1-run.log` são artefatos gerados por `check-gates.sh`, não registro versionável.
- G2 (`verify-change`) aceita agora en dash (`–`) além de hífen e em-dash na linha de critério — a doc já prometia "hífen ou travessão", o regex só cobria dois dos três.
- `selftest.sh` passa a checar também: `VERSION` bate com o topo versionado do `CHANGELOG.md`; todo `hooks/*.json` e `mcp/*.json` está referenciado em `OPERACAO.md`/`mcp/README.md`; `docs/archive/` só retém `MIGRATION-v1.md` (os outros três — QUICKSTART/MANUAL/CATALOGO-v1 — foram removidos: mantê-los era reintroduzir o próprio risco documentado na introdução do `OPERACAO.md`, "três documentos derivando de forma independente"; preservados no histórico do git).

### Corrigido (bloqueantes)

- Agentes agora existem em **dois formatos**: `.json` (CLI) e `.md` com frontmatter (IDE) — `scripts/gen-agent-md.sh` gera o segundo a partir do primeiro; `install.sh` instala os dois. `selftest.sh` valida sincronia.
- `tools` dos 9 agentes corrigido para nomes válidos do Kiro (`read`/`write`/`shell`) — `grep`/`glob`/`skill` não existiam.
- `check-gates.sh` resolve sozinho o worktree do PBI (`git worktree list`) em vez de rodar a suíte no diretório corrente por acidente; reprova cedo se a branch `pbi/<ID>` existir sem worktree registrado.
- `scripts/worktree.sh`: fallback de branch principal corrigido (`|| echo main` nunca disparava — `MAIN` podia ficar vazio silenciosamente).
- G5 (regressão) agora é **bloqueante por padrão**; escape explícito e registrado via `--skip-g5 "<motivo>"`.
- G2 (`verify-change`) passa a exigir linha de critério ancorada (`R#.# - PASS|FAIL|BLOCKED`) em vez de `grep` livre no arquivo inteiro — evidência bruta colada não derruba nem inflaciona o veredicto por acidente.

### Corrigido (installer)

- `install.sh --update` agora **poda de verdade**: converge `agents/` e `skills/` pro conjunto atual, removendo o que saiu do central (antes, `cp -rf` só sobrescrevia, nunca removia).
- `--update` sem `--stack` lembra o stack da instalação original (manifesto `.kiro/.kiro-ai-team-version`, agora JSON: `version`/`scope`/`stack`/`agents`/`skills`).
- Novas flags `--dry-run` (mostra sem tocar) e `--uninstall` (remove agents/skills, preserva steering/docs do projeto).
- Doc corrigida: `--stack` poda só o agente `dev-*`; os 4 guidelines sempre vão juntos (comportamento do código já era esse — a doc é que dizia o contrário).

### Adicionado (mecanização)

- Hook `task-checkpoint` (`PostTaskExec`) — build/teste automático após cada task marcada `[x]`.
- Hook `preflight-branch` (`SessionStart`) — avisa se a branch atual não é o worktree de um PBI com spec ativa.
- Hook por-agente `qa-blackbox-guard` (`preToolUse`, embutido em `agents/qa-blackbox.json`) — defesa em profundidade pra "nunca lê `src/`"; falha aberto quando não reconhece o payload (contrato não documentado publicamente).
- `format-oracle` convertido de agente pra linter determinístico (`hooks/scripts/check-oracle.sh`); `format-webforms` removido (sem alternativa determinística barata e confiável).
- Ledger `docs/reviews/.gate-ledger` — 1 linha por execução de `check-gates.sh`, dado bruto pra decidir com números se algum gate compensa o custo.
- `check-gates.sh` detecta `--test-cmd` vazio/placeholder não preenchido (`tech.md` com template intacto) e reprova cedo e claro.

### Adicionado (MCP e contexto)

- `github.json`/`atlassian.json` migrados pro servidor remoto nativo do Kiro (`url`+`headers`), sem o shim `mcp-remote`.
- `mcp/README.md` — donos/quirks de cada fragmento (a chave `comment` não fazia parte do schema documentado).
- Removidos `resources: file://...` dos agentes que duplicavam steering já injetado automaticamente (`always`/`fileMatch`).

### Adicionado (docs e testes)

- `tests/test-check-gates.sh` e `tests/test-install.sh` — cobertura de fixtures para `check-gates.sh` e `install.sh`; `selftest.sh` passa a rodar os dois, mais checagem de sincronia `.json`↔`.md` e cobertura de agentes/skills em `OPERACAO.md`.
- `.github/workflows/ci.yml` — `selftest.sh` em push/PR.
- `LICENSE` (MIT) e este `CHANGELOG.md`.
- `OPERACAO.md` — funde QUICKSTART/MANUAL/CATALOGO (fonte única evita a doc contradizer o código, como aconteceu na v1.5.1). Originais preservados em `docs/archive/` nesta tag; removidos na mesma auditoria seguinte (ver "Corrigido (higiene)" acima) — manter 3 fontes paralelas era reintroduzir o próprio risco que motivou a fusão.
- `examples/PBI-EXEMPLO/` — ciclo completo em miniatura (brief, tasks, evidência dos 5 gates) pra ensaiar o fluxo sem tocar código real.

## [1.5.1] — 2026-07-24 (retroativo)

Estado do repo na auditoria de ecossistema que deu origem a este changelog. Ver `git log` para o histórico anterior (`e629c54` Initial … `9e95fba` fix: ecosystem audit follow-ups).

### Conhecido no momento desta tag (ver plano de remediação)

- Agentes só em `.json`: IDE do Kiro espera `.md` com frontmatter em `.kiro/agents/` — CLI e IDE divergem (kirodotdev/Kiro#8040).
- `tools` dos 9 agentes usa nomes inválidos (`grep`/`glob`/`skill` não existem nos built-ins do Kiro).
- `check-gates.sh` roda a suíte no diretório corrente, não no worktree do PBI.
- `scripts/worktree.sh` tem fallback de branch principal morto (`|| echo main` nunca dispara).
- G5 (regressão) não bloqueia o exit code por default.
- `install.sh --update` não poda skills/agentes removidos de versões anteriores nem memoriza `--scope`/`--stack`.

[Unreleased]: https://github.com/cleudice/kiro-ai-team/compare/v1.9.0...HEAD
[1.9.0]: https://github.com/cleudice/kiro-ai-team/compare/v1.8.0...v1.9.0
[1.8.0]: https://github.com/cleudice/kiro-ai-team/compare/v1.7.0...v1.8.0
[1.7.0]: https://github.com/cleudice/kiro-ai-team/compare/v1.6.1...v1.7.0
[1.6.1]: https://github.com/cleudice/kiro-ai-team/compare/v1.6.0...v1.6.1
[1.6.0]: https://github.com/cleudice/kiro-ai-team/compare/v1.5.1...v1.6.0
[1.5.1]: https://github.com/cleudice/kiro-ai-team/releases/tag/v1.5.1
