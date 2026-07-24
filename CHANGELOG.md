# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

## [Unreleased]

Sem mudanças pendentes desde o `[1.6.0]` abaixo.

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
