# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

## [Unreleased]

Auditoria completa do ecossistema pós-v1.5.1 — bloqueantes, mecanização de disciplina humana e consolidação de docs.

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
- `OPERACAO.md` — funde QUICKSTART/MANUAL/CATALOGO (fonte única evita a doc contradizer o código, como aconteceu na v1.5.1). Originais preservados em `docs/archive/`.
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
