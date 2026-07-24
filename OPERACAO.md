# OPERAÇÃO — setup, dia a dia e referência do kiro-ai-team

Documento único de operação. O [README](README.md) explica o _porquê_ da arquitetura (a dualidade central × projeto, o ciclo, os papéis); este documento é o _como_: instalar, operar, e a ficha de referência de cada peça (agente, skill, gate) e o ciclo de vida de cada artefato.

> Substitui QUICKSTART.md + MANUAL.md + CATALOGO.md (fundidos numa fonte só — três documentos derivando de forma independente é como a v1.5.1 acabou com a doc contradizendo o código; ver `docs/archive/`). Migrando de skills antigas (agent-skills)? Ver `docs/archive/MIGRATION-v1.md`.

---

## 1. Setup (uma vez por repo)

```bash
git clone <org>/kiro-ai-team
./kiro-ai-team/install.sh /caminho/do/projeto --stack dotnet    # repo só .NET — recomendado
./kiro-ai-team/install.sh /caminho/do/projeto                   # sem --stack: instala TODOS os stacks (dev-dotnet/webforms/flutter) — pode dele depois
./kiro-ai-team/install.sh /caminho/do/projeto --update          # atualizar (lembra o --stack original; poda o que saiu do central)
./kiro-ai-team/install.sh /caminho/do/projeto --dry-run         # mostra o que seria feito, sem tocar em nada
./kiro-ai-team/install.sh /caminho/do/projeto --uninstall       # remove agents/skills do time (preserva steering/docs do projeto)
```

`--stack dotnet|webforms|flutter` instala só o agente `dev-*` do stack informado (mais os 6 papéis stack-agnósticos: orchestrator, spec-analyst, qa-blackbox, reviewer-spec, reviewer-code, auditor). Os 4 arquivos de `steering/guidelines/` (dotnet/webforms/flutter/oracle) vão **sempre juntos, independente do `--stack`** — `reviewer-code`/`reviewer-spec` são core, instalados em todo stack, e revisam qualquer diff do repo; são `.md` pequenos, o custo de bloat é irrelevante. Repo multi-stack (ex.: backend .NET + app Flutter) → omita `--stack` e pode manualmente o(s) `dev-*` que sobrar sem uso (`.kiro/agents/dev-*.json` + `.md`) — instalar `dev-flutter` num repo sem Flutter é ruído que pode confundir o orchestrator na hora de rotear.

Cada agente vai em **dois formatos**: `.json` (a CLI do Kiro lê este) e `.md` com frontmatter (o IDE lê este) — gerados a partir da mesma fonte (`agents/*.json` no central; `scripts/gen-agent-md.sh` gera o `.md`). Os dois sempre convivem no destino; não edite o `.md` à mão.

Depois do install:

1. **MCP** — mescle em `.kiro/settings/mcp.json` apenas os fragmentos de `kiro-ai-team/mcp/` que este repo usa (Jira/Bitbucket? GitHub? Firebase? SQLcl?). Preencha credenciais locais. Donos e quirks de cada fragmento: [mcp/README.md](mcp/README.md).
2. **Hooks** — copie de `kiro-ai-team/hooks/` para `.kiro/hooks/` os que fizerem sentido: `format-dotnet`/`format-flutter` (build+format ao salvar), `format-oracle` (linter determinístico ao salvar `.sql`), `task-checkpoint` (build+teste automático após cada task marcada `[x]` — mecaniza o checkpoint do `task-preflight`), `preflight-branch` (avisa no início da sessão se a branch atual não é o worktree do PBI), `issue-intake` (triagem automática de brief novo). O guard "`qa-blackbox` nunca lê `src/`" já vem embutido no próprio `agents/qa-blackbox.json` (hook por-agente, não precisa copiar nada à parte) — é defesa em profundidade, não substitui o prompt (ver `steering/quality-gates.md`). Confirme depois no painel "Agent Hooks" que os hooks copiados aparecem.
3. **Steering do projeto** — preencha `product.md`, `tech.md` (build/test commands!) e `structure.md`. Atalho: rode a skill `reverse-engineer-project`, que gera `docs/context/` e preenche os templates vazios.
4. **Commit do `.kiro/` + `AGENTS.md`** — o time é versionado junto do código; quem clonar o repo herda o time.
5. **Reinicie o IDE/CLI (ou reload window)** — instalação nova adiciona agentes/skills; confirme no painel "Agent Steering & Skills" que os 6-9 agentes e as skills aparecem antes do primeiro PBI.
6. **(Recomendado) `kiroAgent.trustedCommands`** — sem isso, todo `dotnet test`/`flutter test`/`check-gates.sh` pede aprovação manual. Configure em Settings → Kiro Agent: Trusted Commands (global ou por workspace) os comandos de build/test do seu stack, com `*` no final pra aceitar argumentos (ex.: `"dotnet test *"`, `"git status *"`). Nunca confie largo em comandos destrutivos (`git push`, `git reset --hard`, `npx *`) nem em `check-gates.sh` (recebe `--test-cmd` arbitrário — aprovação manual aqui é intencional).

Sanidade: `.kiro/.kiro-ai-team-version` é um manifesto JSON (`version`, `scope`, `stack`, `agents`, `skills`) — confira o campo `version`. `--update` sem `--stack` reaproveita o `stack` gravado aqui e poda agentes/skills que saíram do central (o próprio `install.sh` converge o diretório real pro conjunto atual, autocura mesmo se o manifesto estiver ausente/legado).

### Escopos de instalação

| Escopo               | Comando                             | Quando usar                                                                              |
| -------------------- | ----------------------------------- | ---------------------------------------------------------------------------------------- |
| **project** (padrão) | `./install.sh /repo`                | Recomendado: time versionado no git do repo, versão pinada por projeto                   |
| **global**           | `./install.sh --scope global`       | Engine (agents+skills) uma vez em `~/.kiro`, compartilhada por todos os repos da máquina |
| **hybrid**           | `./install.sh /repo --scope hybrid` | Engine global + camada fina no projeto (steering, docs, templates)                       |

Notas:

- **Steering global existe** (`~/.kiro/steering/`): o escopo `global` instala `principios.md` — seu "system prompt" pessoal, sempre incluído. Regras: workspace **vence** global em conflito; evite `fileMatch` no global (bug de não-injeção); arquivo real, sem symlink; IDE ignora `KIRO_HOME`. Contexto do projeto e retro-learnings continuam **sempre por workspace**.
- No hybrid, a engine local é omitida de propósito (evita conflito de nomes de agente); se as versões global × projeto divergirem, o installer avisa.
- Trade-off do global: você perde o pin de versão por repo — todos os projetos da máquina passam a usar a mesma engine. Em times, prefira `project`; global/hybrid brilham na máquina pessoal com muitos repos.
- MCP pode ir para os dois lugares: credenciais/servidores comuns em `~/.kiro/settings/mcp.json`, específicos do repo no `mcp.json` do projeto.

---

## 2. Operação diária

Você conversa quase só com o **orchestrator**. Fluxo típico:

**Como a ativação funciona de fato:**

- **Skill**: você nunca digita o nome da skill — o Kiro casa sua frase contra o campo `description` de cada `SKILL.md` (por isso as descriptions são escritas como lista de gatilhos: "Use quando disserem 'X', 'Y'"). Fale em linguagem natural o que quer fazer.
- **Agente**: cada agente é selecionável no seletor de agente do chat (canto do painel, ao lado do model picker). Trocar de agente **nesse mesmo seletor mantém o histórico da conversa** — o agente novo enxerga tudo que foi dito antes. Isso é o oposto do que "sessão limpa" precisa (ver Passo 4).

### Passo 1 — Entrada

> "orchestrator, faça a triagem da PROJ-1234"

Ele roda `triage-issue` (busca no Jira/Azure Boards/GitHub via MCP, ou você cola o texto), gera o brief em `docs/issues/` e recomenda o trilho. Crash do app? `triage-crash` gera o brief no mesmo formato. Se o hook `issue-intake` estiver ativo, um brief novo já dispara essa triagem sozinho.

### Passo 2 — Spec

- **Trilho feature** → agente `spec-analyst`:
  `write-requirements` (ele **pergunta antes de congelar** — responda e siga) → `write-design` → `write-tasks`.
- **Trilho manutenção** → direto `write-tasks` mínimo a partir do brief.

Resultado: `.kiro/specs/<slug>/tasks.md` com os gates G1–G5 já embutidos no final.

### Passo 3 — Execução (paralela, contextos separados)

```bash
./kiro-ai-team/scripts/worktree.sh start PROJ-1234
```

- No worktree: agente `dev-dotnet` | `dev-webforms` | `dev-flutter` → "prepare o worktree do PBI PROJ-1234" (`task-preflight`: confirma branch + build verde). O hook `preflight-branch` já avisa sozinho no início da sessão se a branch atual não bater com uma spec ativa.
- No painel da spec (`.kiro/specs/<slug>/tasks.md`): clique **"Start task"** nativo do Kiro em cada item, na ordem — é o Kiro quem implementa. Após cada `[x]`: o hook `task-checkpoint` roda build/teste sozinho e só reporta se algo falhar (sem o hook instalado, peça "checkpoint" manualmente ao mesmo agente).
- "**Outra sessão**" pro `qa-blackbox` (e pros reviewers no Passo 4) significa **aba de chat nova** (ícone "+" no painel, ou `/chat new` na CLI) **com o agente selecionado nessa aba nova** — nunca só trocar o agente na mesma aba onde o dev trabalhou. Ele lê só a spec, nunca `src/` (reforçado por um hook próprio, `qa-blackbox-guard` — defesa em profundidade, não confie só nele) — não interfira nisso, é o mecanismo central.
- Dev terminou → `verify-change` com evidência real (não aceite "pronto").

### Passo 4 — Qualidade e merge

- **Sessão limpa de verdade = aba nova.** Trocar de agente no seletor do MESMO painel mantém o histórico — o revisor veria a conversa do dev e a revisão deixa de ser adversarial. Abra aba nova ("+" ou `/chat new`) pra cada revisor abaixo:
  - Sessão limpa 1 (aba nova): `reviewer-spec` → `review-spec` (diff × requirements).
  - Sessão limpa 2 (outra aba nova): `reviewer-code` → `review-code`.
- > "orchestrator, merge-gate do PROJ-1234"
  > Ele confere as 5 evidências **em disco** (G5 é bloqueante por padrão — sem log de regressão, reprova; escape explícito é `--skip-g5 "<motivo>"`), roda a regressão, mescla serializado, `worktree.sh finish`, e fecha no tracker de origem com `resolve-issue`.

### Seu papel humano (só 3 momentos)

1. Responder as perguntas do spec-analyst.
2. Decidir escalações (spec ambígua — o agente para e pergunta, por regra).
3. Bater o martelo quando um gate reprova.

---

## 3. Quando usar o quê

| Situação                                                                        | Caminho                                                                                   |
| ------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Tela/endpoint novo, regra de negócio, ≥ meio dia, toca contrato público         | **Trilho feature** (spec completa)                                                        |
| Bugfix com reprodução, ajuste pontual, crash Crashlytics                        | **Trilho manutenção** (tasks mínimas; gates 2–5 obrigatórios; G1 se houver critério novo) |
| Spike, protótipo descartável, dúvida de código, ajuste de 5 min em texto/config | **Kiro puro, sem o time** — governança em protótipo é desperdício de tokens               |
| A cada 5 merges                                                                 | `audit-integration` (o merge-gate agenda sozinho)                                         |
| Mesma falha pela 2ª vez                                                         | `retrospective` na hora — vira regra em `retro-learnings.md`                              |
| Repo desconhecido / onboarding                                                  | `reverse-engineer-project` antes de qualquer PBI                                          |
| Quer ensaiar o ciclo sem risco                                                  | `examples/PBI-EXEMPLO/` — brief + spec + evidência dos 5 gates prontos pra estudo         |

**Regra de bolso:** vai para produção → passa pelos gates. É descartável → não passe.

---

## 4. Multi-repo

PBI que atravessa backend + app = **um brief por repo, vinculados** (campo `vinculado a:` do brief). Cada um passa pelos próprios gates no próprio worktree; `resolve-issue` só fecha a issue externa quando **todos** os irmãos passarem no merge-gate.

## 5. Anti-padrões (não faça)

- Pedir ao dev para "já escrever os testes junto" — mata o black-box.
- Colar a conversa do dev para o reviewer — mata a revisão adversarial.
- Mesclar "só dessa vez" sem merge-gate — o valor do sistema é exatamente não abrir essa exceção.
- Editar teste do qa-blackbox para passar — teste vermelho legítimo significa implementação errada **ou spec errada**; escale.
- Usar `--skip-g5` como padrão — é escape explícito pra quando não há ambiente de integração disponível, não um atalho de conveniência.

## 6. Problemas comuns

| Sintoma                                | Causa provável                                         | Ação                                                                      |
| -------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------- |
| Agente "assumiu" algo na spec          | escalation-rules não carregado                         | conferir steering `inclusion: always`                                     |
| qa-blackbox não consegue testar        | contrato público ausente no design                     | devolver ao spec-analyst (é feature do sistema, não bug)                  |
| merge-gate reprovou com tudo "pronto"  | evidência não está em disco                            | gerar os arquivos de `docs/reviews/` — relato verbal não conta            |
| G1b/G5 falham de um jeito confuso      | `tech.md` com comando de build/teste vazio/placeholder | preencher `tech.md`; `check-gates.sh` agora detecta e reprova cedo (M5)   |
| Agentes não aparecem no seletor do IDE | só o `.json` foi instalado (formato da CLI)            | reinstalar/atualizar — `install.sh` agora sempre grava o `.md` junto (B1) |
| MCP falha no Windows                   | quirks conhecidos (portproxy Bitbucket, wrapper SQLcl) | ver [mcp/README.md](mcp/README.md)                                        |

---

## 7. Referência — agentes

### `orchestrator`

- **O quê**: único ponto de contato humano; roteia trabalho, acompanha estado do PBI, executa o merge-gate.
- **Quando usar**: para qualquer coisa que não seja "escrever spec" ou "escrever código" — triagem, dúvida de estado, decisão de mesclar, crash chegando, onboarding de repo novo.
- **Como usar**: "orchestrator, triagem da PROJ-1234" · "orchestrator, merge-gate do PBI-1234" · "orchestrator, chegou um crash novo" · "orchestrator, mapeia este repo".
- **Entrada**: brief de tracker, estado dos gates. **Saída**: brief em `docs/issues/`, decisão de trilho, merge autorizado/recusado, issue fechada.
- **Não faz**: não escreve código em `src/`, não aprova o próprio trabalho.

### `spec-analyst`

- **O quê**: transforma brief em spec Kiro (requirements EARS → design → tasks).
- **Quando usar**: assim que o orchestrator classificar o trilho como **feature**.
- **Como usar**: "spec-analyst, escreva os requirements da PROJ-1234" → responda as perguntas dele → "agora o design" → "agora as tasks".
- **Entrada**: `docs/issues/<ID>.md`. **Saída**: `.kiro/specs/<slug>/{requirements,design,tasks}.md`.
- **Não faz**: não implementa; não congela requisito sem esclarecer ambiguidade com você.

### `dev-dotnet` / `dev-webforms` / `dev-flutter`

- **O quê**: implementam as tasks do PBI no worktree, no stack correspondente.
- **Quando usar**: spec/tasks prontas (ou brief de manutenção com tasks mínimas) e worktree criado.
- **Como usar**: "dev-dotnet, prepare o worktree do PBI-1234" (pré-flight) → vá ao painel `.kiro/specs/<slug>/tasks.md` e clique **Start task** em cada item (execução nativa do Kiro) → checkpoint automático via hook (ou manual: "checkpoint" com o mesmo agente).
- **Entrada**: `tasks.md` + guidelines do stack. **Saída**: código commitado por task, `docs/reviews/<PBI>-notes.md` se houver sugestão fora de escopo.
- **Não faz**: não escreve os testes de aceitação; não decide sozinho diante de spec ambígua — escala.

### `qa-blackbox`

- **O quê**: escreve os testes de aceitação só a partir da spec — nunca vê `src/`.
- **Quando usar**: assim que `requirements.md`/`design.md` estiverem prontos, em paralelo ao dev (sessão separada).
- **Como usar**: "qa-blackbox, escreva os testes de aceitação do PBI-1234" — em uma sessão/janela que NÃO tem o histórico de implementação.
- **Entrada**: `requirements.md` + contratos de `design.md`. **Saída**: `docs/tests-spec/<slug>.md` + código de teste.
- **Não faz**: não lê `src/`, `docs/context/` nem a conversa dos devs. Não ajusta teste para acomodar implementação.
- **Regra especial**: se o PBI não tiver nenhuma task de `dev-*` (design decidiu zero mudança em `src/`), ele também é dono do gate G2 — roda `verify-change` e produz `docs/reviews/<PBI>-verify.md`. Trabalha sempre dentro do worktree do PBI, nunca no working tree principal. Nomes/comentários do código de teste seguem o idioma do código-fonte real (detectado pelos contratos do `design.md`), não o idioma padrão do time.
- **Mecanização (defesa em profundidade)**: um hook `preToolUse` embutido no próprio `agents/qa-blackbox.json` tenta bloquear leitura de `src/`. O contrato exato de payload que o Kiro passa a esse tipo de hook não é documentado publicamente — o script falha ABERTO (não bloqueia) quando não reconhece o formato, então isto reforça a regra, não a garante sozinho.

### `reviewer-spec` / `reviewer-code`

- **O quê**: revisão adversarial em sessão limpa — o primeiro confere se o diff cumpre `requirements.md`; o segundo, qualidade técnica.
- **Quando usar**: depois do `verify-change` verde, antes do merge-gate.
- **Como usar**: "reviewer-spec, revise o PBI-1234 contra a spec" / "reviewer-code, revise o diff do PBI-1234" — sessão nova, sem colar a conversa dos devs.
- **Entrada**: diff do PBI + (spec | guidelines do stack). **Saída**: `docs/reviews/<PBI>-{spec,code}.md` com APROVADO/REPROVADO.
- **Não faz**: não corrige nada — só reporta.

### `auditor`

- **O quê**: varre o repo inteiro atrás do que a revisão por PBI não vê (duplicação, drift, segurança inconsistente).
- **Quando usar**: a cada 5 merges (o `merge-gate` avisa) ou sob demanda.
- **Como usar**: "auditor, rode a auditoria de integração".
- **Entrada**: histórico de merges `pbi/*` desde a última auditoria. **Saída**: briefs `docs/issues/AUDIT-*.md`.
- **Não faz**: não corrige — só gera issues para o próximo ciclo.

---

## 8. Referência — skills

### Entrada

- **`triage-issue`** — normaliza qualquer issue (Jira/Azure Boards/GitHub/texto colado) no brief padrão, inclusive descrevendo textualmente anexos de imagem. Dono: `orchestrator`. Saída: `docs/issues/<TRACKER>-<ID>.md`.
- **`triage-crash`** — investiga crash via MCP Firebase, brief no mesmo formato. Dono: `orchestrator`. Saída: `docs/issues/CRASH-<id>.md`.
- **`reverse-engineer-project`** — mapeia repo desconhecido → `docs/context/` por eixos + preenche `tech.md`/`structure.md`. Dono: `orchestrator`. Saída: 8 arquivos em `docs/context/`.

### Spec (trilho feature)

- **`write-requirements` → `write-design` → `write-tasks`** — cadeia executada pelo `spec-analyst`. `write-tasks` embute o bloco de gates G1–G5 no final do `tasks.md` — não pule esse passo mesmo no trilho manutenção. Toda task e todo gate leva o agente dono entre parênteses (`dev-dotnet`, `qa-blackbox`...) — é o que permite ao orchestrator rotear sem chutar.

### Execução

- **`task-preflight`** — pré-flight (worktree/branch/build) + checkpoint por task; não substitui o "Start task" nativo. Dono: dev do stack.
- **`write-blackbox-tests`** — ver ficha do `qa-blackbox`.
- **`verify-change`** — exercita o comportamento real e captura evidência por critério (linha `R#.# - PASS|FAIL|BLOCKED - evidência`, formato que `check-gates.sh` lê mecanicamente). Dono: dev do stack. Saída: `docs/reviews/<PBI>-verify.md` — insumo do G2.

### Qualidade e fechamento

- **`review-spec` / `review-code`** — ver fichas dos `reviewer-*`.
- **`merge-gate`** — checklist mecânico final:
  ```bash
  bash .kiro/skills/merge-gate/scripts/check-gates.sh <PBI> <slug> --test-cmd "<cmd do tech.md>" [--track manutencao]
  ```
  Sem `--repo`, resolve sozinho o worktree do PBI a partir da branch `pbi/<ID>`. G5 é bloqueante por padrão — precisa de `--g5-log <arquivo>` (com a linha `G5: PASS`) ou de `--skip-g5 "<motivo>"` como escape explícito. Saída: exit 0/1 + `docs/reviews/<PBI>-gate.md` se recusado. Cada execução grava 1 linha em `docs/reviews/.gate-ledger` (dado bruto pra decidir com números, não opinião, se algum gate custa mais do que pega).
- **`resolve-issue`** — fecha o ciclo no tracker de origem. Dono: `orchestrator`, automático ao fim do `merge-gate`.

### Loops

- **`audit-integration`** — ver ficha do `auditor`.
- **`retrospective`** — converte falha recorrente (2ª vez) em UMA regra objetiva em `retro-learnings.md`. Máx. 1–2 regras por retro; se vale para todos os projetos, vira PR no `kiro-ai-team` central.

---

## 9. Gates — o que cada um checa, mecanicamente

| Gate | Confere                                                   | Arquivo-evidência                                               | Quem produz a evidência | Bloqueante?                                                           |
| ---- | --------------------------------------------------------- | --------------------------------------------------------------- | ----------------------- | --------------------------------------------------------------------- |
| G1   | testes black-box existem e passam                         | `docs/tests-spec/<slug>.md` + execução (`--test-cmd`)           | `qa-blackbox`           | sempre (dispensável só em manutenção sem critério novo)               |
| G2   | comportamento real, sem FAIL/BLOCKED em linha de critério | `docs/reviews/<PBI>-verify.md`                                  | dev via `verify-change` | sempre                                                                |
| G3   | diff cumpre a spec                                        | `docs/reviews/<PBI>-spec.md` = `Veredicto: APROVADO` (1ª linha) | `reviewer-spec`         | sempre                                                                |
| G4   | qualidade técnica                                         | `docs/reviews/<PBI>-code.md` = `Veredicto: APROVADO` (1ª linha) | `reviewer-code`         | sempre                                                                |
| G5   | regressão da integração                                   | log com linha `G5: PASS` (`--g5-log`)                           | `merge-gate`            | sim, por padrão — `--skip-g5 "<motivo>"` é o único escape, registrado |

Script único, determinístico: `skills/merge-gate/scripts/check-gates.sh`. Reprovação em qualquer G devolve ao dono da coluna 3 — o `merge-gate` não julga, só confere. `bump-counter` (rodado após merge efetivo) agenda `audit-integration` a cada 5.

---

## 10. Steering — o que rege o comportamento, sem você invocar nada

| Arquivo                                                   | Regra em 1 linha                                                 |
| --------------------------------------------------------- | ---------------------------------------------------------------- |
| `~/.kiro/steering/principios.md`                          | seus princípios pessoais (global, só você edita)                 |
| `steering/escalation-rules.md`                            | ambiguidade → parar e perguntar, nunca chutar                    |
| `steering/quality-gates.md`                               | a tabela da seção 9 acima, injetada sempre                       |
| `steering/workflow.md`                                    | o diagrama do ciclo completo                                     |
| `steering/guidelines/{dotnet,webforms,flutter,oracle}.md` | convenções por stack, só carregam no arquivo certo (`fileMatch`) |
| `steering/product.md` / `tech.md` / `structure.md`        | o que é este projeto (você escreve/confirma)                     |
| `steering/retro-learnings.md`                             | regras nascidas de falhas reais deste projeto                    |

Esses arquivos valem **mesmo sem você invocar skill nenhuma** — é por isso que um dev, mesmo só usando "Start task" nativo, já herda "nunca chutar" e "não aprovar o próprio trabalho". Agentes não carregam mais os guidelines/escalation-rules via `resources: file://` explícito (removido — duplicava contexto já injetado automaticamente pelo steering `always`/`fileMatch`).

---

## 11. Ciclo de vida dos artefatos

| Artefato                                             | Quem cria                                                           | Quando              | Quem atualiza                                                                                                                                      | Quem lê                                 |
| ---------------------------------------------------- | ------------------------------------------------------------------- | ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| `~/.kiro/steering/principios.md`                     | installer (template) → **você edita**                               | 1x por máquina      | só você; installer nunca sobrescreve                                                                                                               | todos os agentes, sempre                |
| `steering/escalation-rules\|quality-gates\|workflow` | installer                                                           | install/update      | **só via update do kiro-ai-team** (regra do time; mudança local = PR no central)                                                                   | todos, sempre                           |
| `steering/guidelines/*`                              | installer                                                           | install/update      | via update do kiro-ai-team                                                                                                                         | agente do stack, por `fileMatch`        |
| `steering/product.md`                                | template vazio → **humano escreve**                                 | onboarding do repo  | humano, quando o produto muda                                                                                                                      | todos, sempre                           |
| `steering/tech.md`                                   | template → `reverse-engineer-project` preenche → **humano confere** | onboarding          | humano, quando o stack/build muda                                                                                                                  | todos, sempre (build/test cmds!)        |
| `steering/structure.md`                              | template → `reverse-engineer-project` preenche                      | onboarding          | humano ou re-run do eixo                                                                                                                           | todos, sempre                           |
| `steering/retro-learnings.md`                        | template vazio                                                      | onboarding          | **só a skill `retrospective`** (nunca pré-popular)                                                                                                 | todos, sempre                           |
| `docs/context/*` (8 eixos)                           | `reverse-engineer-project`                                          | onboarding          | re-run **por eixo** quando `audit-integration` detectar drift                                                                                      | por eixo — ver §12                      |
| `.kiro/specs/<slug>/requirements.md`                 | `write-requirements` (spec-analyst)                                 | por PBI feature     | congelado; mudança só via nova rodada com humano + changelog no rodapé                                                                             | qa-blackbox, reviewer-spec, devs        |
| `.kiro/specs/<slug>/design.md`                       | `write-design`                                                      | por PBI feature     | idem (decisões novas viram entrada, não edição silenciosa)                                                                                         | qa-blackbox (contratos), devs           |
| `.kiro/specs/<slug>/tasks.md`                        | `write-tasks`                                                       | por PBI (2 trilhos) | execução é o "Start task" nativo do Kiro (marca `[x]`); `task-preflight`/hooks cercam com pré-flight/checkpoint; escopo não muda sem voltar à spec | dev (via nativo), orchestrator          |
| `docs/issues/<ID>.md`                                | `triage-issue`/`triage-crash`/`audit-integration`                   | entrada de trabalho | `resolve-issue` anexa `## Resolução`                                                                                                               | orchestrator, spec-analyst              |
| `docs/tests-spec/<slug>.md`                          | `write-blackbox-tests` (qa-blackbox)                                | por PBI             | qa-blackbox apenas                                                                                                                                 | merge-gate (G1), reviewer-spec          |
| `docs/reviews/<PBI>-{verify,spec,code,gate}.md`      | verify-change / revisores / merge-gate                              | por PBI             | ninguém (é registro, não documento vivo)                                                                                                           | merge-gate, auditor, humano             |
| `docs/reviews/.gate-ledger`                          | `check-gates.sh`                                                    | toda execução       | ninguém (append-only)                                                                                                                              | humano (decidir se algum gate compensa) |

Regra transversal: **installer sobrescreve o que é do time, nunca toca o que é do projeto/pessoal** (templates copiados só se ausentes; poda de agents/skills nunca toca steering/docs).

## 12. docs/context — descritivo, sob demanda, por eixo

Gerado 1x pelo `reverse-engineer-project`; cada eixo ≤ ~1 página com caminhos reais. **Ninguém carrega o pacote inteiro** — token-efficiency por carga seletiva:

| Eixo          | Conteúdo                                       | Quem carrega                                     |
| ------------- | ---------------------------------------------- | ------------------------------------------------ |
| overview      | o que o sistema faz, mapa de alto nível        | spec-analyst (requirements), orchestrator        |
| architecture  | camadas, componentes, dependências             | spec-analyst (design)                            |
| integrations  | APIs externas, MCPs, filas                     | spec-analyst, dev-* quando o PBI toca integração |
| data-flow     | modelos, persistência, transações              | dev-* em PBI de dados; reviewer-code             |
| security      | authn/z, segredos, superfícies                 | reviewer-code, auditor                           |
| conventions   | idiomas do repo, nomes, padrões                | dev-* (sempre), reviewer-code                    |
| gotchas       | armadilhas conhecidas, débito, "não mexa sem…" | dev-* (sempre), auditor                          |
| feature-guide | onde nasce código novo, passo a passo          | dev-* em PBI feature                             |

- **qa-blackbox NUNCA lê docs/context** — os eixos derivam do código; ler seria black-box furado.
- Manutenção: `audit-integration` detecta drift documentado×real → re-run **do eixo específico**, nunca do pacote inteiro.
- Steering responde "**como devo me comportar**"; context responde "**como este sistema é**".

## 13. Onboarding de um repo — sequência canônica

1. `install.sh <repo>` (ou `--scope hybrid`) → esqueletos + regras do time.
2. `reverse-engineer-project` → `docs/context/` + `tech.md`/`structure.md` preenchidos.
3. Humano: **confere `tech.md`** (comando errado aqui quebra G1b/G5 — agora `check-gates.sh` detecta placeholder vazio/não preenchido e reprova cedo) e **escreve `product.md`** (5–10 linhas).
4. Mesclar MCPs do repo (ver [mcp/README.md](mcp/README.md)); ativar hooks desejados.
5. Commit do `.kiro/` + `docs/context/`.
6. Primeiro PBI pelo trilho manutenção — ou ensaie primeiro com `examples/PBI-EXEMPLO/`.

## 14. O que é nativo do Kiro vs. do kiro-ai-team

| Nativo (docs oficiais)                                                                                            | kiro-ai-team (este repo)                                                          |
| ----------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| specs requirements/design/tasks, execução de tasks                                                                | conteúdo/formato EARS + gates embutidos via skills `write-*`                      |
| steering workspace + global (`~/.kiro/steering`), AGENTS.md, inclusion modes                                      | as 3 camadas, templates, política de sobrescrita                                  |
| agents (CLI `.json` / IDE `.md`+frontmatter), skills SKILL.md, hooks (globais + por-agente), MCP (user+workspace) | os 9 papéis, 15 skills, fragmentos, escopos do installer, gerador `.md`↔`.json`   |
| "Generate Steering Docs" (foundation files)                                                                       | `reverse-engineer-project` (docs/context por eixos + preenchimento dos templates) |

Quirks conhecidos consolidados: fileMatch global não injeta; symlink em `~/.kiro` ignorado; IDE ignora `KIRO_HOME`; workspace vence global; CLI lê `.json`/IDE lê `.md` em `.kiro/agents/` (kirodotdev/Kiro#8040 — por isso o installer grava os dois); hooks por-agente usam nomes internos de tool (`fs_read`, não `read`) e seu contrato de payload não é documentado publicamente.

---

## 15. Fluxo completo em uma linha por etapa

```
triage-issue/triage-crash → write-requirements → write-design → write-tasks
  → task-preflight + Start task (nativo) ∥ write-blackbox-tests
  → verify-change → review-spec + review-code → merge-gate → resolve-issue
  → (a cada 5 merges) audit-integration → (falha repetida) retrospective
```

Ver também: [README](README.md) (arquitetura e por quê) · [mcp/README.md](mcp/README.md) (fragmentos MCP) · `docs/archive/` (documentos históricos).
