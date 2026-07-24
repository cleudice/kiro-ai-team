# CATALOGO — o que é, quando usar, como usar

Um lugar só. README explica o *porquê* da arquitetura, QUICKSTART o *fluxo*, MANUAL o *ciclo de vida dos arquivos* — este documento é a ficha técnica de cada peça: agente por agente, skill por skill.

---

## Como ler cada ficha

**O quê** — em uma frase. **Quando usar** — o gatilho, a frase que você diria. **Como usar** — o comando/interação real. **Entrada → Saída** — o que consome e o que produz. **Não faz** — o limite deliberado do papel.

---

## 1. Agentes

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
- **Como usar**: "dev-dotnet, prepare o worktree do PBI-1234" (pré-flight) → vá ao painel `.kiro/specs/<slug>/tasks.md` e clique **Start task** em cada item (execução nativa do Kiro) → depois de cada `[x]`, "checkpoint" com o mesmo agente.
- **Entrada**: `tasks.md` + guidelines do stack. **Saída**: código commitado por task, `docs/reviews/<PBI>-notes.md` se houver sugestão fora de escopo.
- **Não faz**: não escreve os testes de aceitação; não decide sozinho diante de spec ambígua — escala.

### `qa-blackbox`
- **O quê**: escreve os testes de aceitação só a partir da spec — nunca vê `src/`.
- **Quando usar**: assim que `requirements.md`/`design.md` estiverem prontos, em paralelo ao dev (sessão separada).
- **Como usar**: "qa-blackbox, escreva os testes de aceitação do PBI-1234" — em uma sessão/janela que NÃO tem o histórico de implementação.
- **Entrada**: `requirements.md` + contratos de `design.md`. **Saída**: `docs/tests-spec/<slug>.md` + código de teste.
- **Não faz**: não lê `src/`, `docs/context/` nem a conversa dos devs. Não ajusta teste para acomodar implementação.
- **Regra especial**: se o PBI não tiver nenhuma task de `dev-*` (design decidiu zero mudança em `src/`), ele também é dono do gate G2 — roda `verify-change` e produz `docs/reviews/<PBI>-verify.md`. Trabalha sempre dentro do worktree do PBI, nunca no working tree principal. Nomes/comentários do código de teste seguem o idioma do código-fonte real (detectado pelos contratos do `design.md`), não o idioma padrão do time.

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

## 2. Skills — entrada

### `triage-issue`
**O quê**: normaliza qualquer issue (Jira/Azure Boards/GitHub/texto colado) no brief padrão — inclusive descrevendo textualmente o que um anexo de imagem (screenshot, mockup) mostra, nunca ignorando o anexo. **Quando**: chegou trabalho novo. **Como**: dono é o `orchestrator`; "triagem da PROJ-1234". **Saída**: `docs/issues/<TRACKER>-<ID>.md` — template de bug/manutenção (Reprodução) ou de feature/tarefa (Objetivo/Escopo esperado/Fora de escopo), conforme o trilho.

### `triage-crash`
**O quê**: investiga crash via MCP Firebase e emite brief no mesmo formato. **Quando**: crash/ANR novo ou pedido de investigação. **Como**: dono é o `orchestrator` (nenhum agente fixo de stack é dono — ele aciona quando o assunto é crash). **Saída**: `docs/issues/CRASH-<id>.md`.

### `reverse-engineer-project`
**O quê**: mapeia repo desconhecido → `docs/context/` por eixos + preenche `tech.md`/`structure.md`. **Quando**: onboarding de qualquer repo, antes do 1º PBI. **Como**: dono é o `orchestrator`; "mapeia este repo". **Saída**: 8 arquivos em `docs/context/`.

## 3. Skills — spec (trilho feature)

### `write-requirements` → `write-design` → `write-tasks`
Cadeia executada pelo `spec-analyst`. Detalhe de cada uma nas fichas de agente acima e no README (tabela de skills). `write-tasks` é quem embute o bloco de gates G1–G5 no final do `tasks.md` — não pule esse passo mesmo no trilho manutenção. **Toda task e todo gate leva o agente dono entre parênteses** (`dev-dotnet`, `qa-blackbox`...) — é o que permite ao orchestrator rotear sem chutar; PBI sem nenhuma mudança de produção (bugfix só de teste) tem todas as tasks do `qa-blackbox`, sem inventar task de `dev-*` que não existe no design.

## 4. Skills — execução

### `task-preflight`
**O quê**: pré-flight (worktree/branch/build) + checkpoint por task — **não substitui** o "Start task" nativo do Kiro, que é quem implementa de fato. **Quando**: antes de começar as tasks e depois de cada `[x]`. **Como**: dono é o dev do stack; ver ficha do agente acima.

### `write-blackbox-tests`
Ver ficha do `qa-blackbox` acima.

### `verify-change`
**O quê**: exercita o comportamento real (HTTP/CLI/tela/procedure) e captura evidência por critério — PASS/FAIL/BLOCKED. **Quando**: depois que as tasks terminam. **Como**: dono é o dev do stack; "verify-change do PBI-1234". **Saída**: `docs/reviews/<PBI>-verify.md`. É o insumo do gate G2.

## 5. Skills — qualidade e fechamento

### `review-spec` / `review-code`
Ver fichas dos `reviewer-*` acima.

### `merge-gate`
**O quê**: checklist mecânico final — roda `scripts/check-gates.sh` (G1–G4 por evidência em disco), confirma que o trabalho está mesmo no branch `pbi/<ID>` (nunca solto na branch alvo) e só então orienta o G5 (regressão) e autoriza o merge serializado. **Quando**: os dois reviews estão APROVADO. **Como**: dono é o `orchestrator`; "merge-gate do PBI-1234" — ele executa o script, não interpreta além dele.
```bash
bash .kiro/skills/merge-gate/scripts/check-gates.sh <PBI> <slug> --test-cmd "<cmd do tech.md>" [--track manutencao]
```
**Saída**: exit 0/1 + `docs/reviews/<PBI>-gate.md` se recusado.

### `resolve-issue`
**O quê**: fecha o ciclo no tracker de origem (comenta causa/solução, transiciona status). **Quando**: logo após o merge efetivo. **Como**: dono é o `orchestrator`; automático ao fim do `merge-gate`.

## 6. Skills — loops

### `audit-integration`
Ver ficha do `auditor` acima.

### `retrospective`
**O quê**: converte falha recorrente (2ª vez) em UMA regra objetiva em `retro-learnings.md`. **Quando**: gate reprovado repetidamente pelo mesmo motivo, ou achado repetido do auditor. **Como**: qualquer agente pode acionar; tipicamente o `orchestrator`. **Regra**: máx. 1–2 regras por retro; se vale para todos os projetos, vira PR no `kiro-ai-team` central, não duplicação local.

---

## 7. Gates — o que cada um checa, mecanicamente

| Gate | Confere | Arquivo-evidência | Quem produz a evidência |
|---|---|---|---|
| G1 | testes black-box existem e passam | `docs/tests-spec/<slug>.md` + execução | `qa-blackbox` |
| G2 | comportamento real, sem FAIL/BLOCKED | `docs/reviews/<PBI>-verify.md` | dev via `verify-change` |
| G3 | diff cumpre a spec | `docs/reviews/<PBI>-spec.md` = APROVADO | `reviewer-spec` |
| G4 | qualidade técnica | `docs/reviews/<PBI>-code.md` = APROVADO | `reviewer-code` |
| G5 | regressão da integração | suíte verde no merge simulado | `merge-gate` |

Script único, determinístico: `skills/merge-gate/scripts/check-gates.sh`. Reprovação em qualquer G devolve ao dono da coluna 4 — o `merge-gate` não julga, só confere.

---

## 8. Steering — o que rege o comportamento, sem você invocar nada

| Arquivo | Regra em 1 linha |
|---|---|
| `~/.kiro/steering/principios.md` | seus princípios pessoais (global, só você edita) |
| `steering/escalation-rules.md` | ambiguidade → parar e perguntar, nunca chutar |
| `steering/quality-gates.md` | a tabela da seção 7 acima, injetada sempre |
| `steering/workflow.md` | o diagrama do ciclo completo |
| `steering/guidelines/{dotnet,webforms,flutter,oracle}.md` | convenções por stack, só carregam no arquivo certo (`fileMatch`) |
| `steering/product.md` / `tech.md` / `structure.md` | o que é este projeto (você escreve/confirma) |
| `steering/retro-learnings.md` | regras nascidas de falhas reais deste projeto |

Esses arquivos valem **mesmo sem você invocar skill nenhuma** — é por isso que um dev, mesmo só usando "Start task" nativo, já herda "nunca chutar" e "não aprovar o próprio trabalho".

---

## 9. Fluxo completo em uma linha por etapa

```
triage-issue/triage-crash → write-requirements → write-design → write-tasks
  → task-preflight + Start task (nativo) ∥ write-blackbox-tests
  → verify-change → review-spec + review-code → merge-gate → resolve-issue
  → (a cada 5 merges) audit-integration → (falha repetida) retrospective
```

Ver também: [README](README.md) (arquitetura e por quê) · [QUICKSTART](QUICKSTART.md) (setup e operação passo a passo) · [MANUAL](MANUAL.md) (ciclo de vida de cada arquivo) · [MIGRATION](MIGRATION.md) (saindo do agent-skills antigo).
