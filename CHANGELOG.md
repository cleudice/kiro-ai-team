# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

## [Unreleased]

Sem mudanças pendentes desde o `[1.8.0]` abaixo.

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
