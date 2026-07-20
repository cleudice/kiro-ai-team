# MANUAL — Referência completa dos artefatos

Complementa o [README](README.md) (visão) e o [QUICKSTART](QUICKSTART.md) (operação): aqui está **como cada artefato nasce, vive e morre** — quem cria, quando muda, quem lê.

---

## 1. Mapa de artefatos

| Artefato                                             | Quem cria                                                           | Quando              | Quem atualiza                                                                    | Quem lê                          |
| ---------------------------------------------------- | ------------------------------------------------------------------- | ------------------- | -------------------------------------------------------------------------------- | -------------------------------- |
| `~/.kiro/steering/principios.md`                     | installer (template) → **você edita**                               | 1x por máquina      | só você; installer nunca sobrescreve                                             | todos os agentes, sempre         |
| `steering/escalation-rules\|quality-gates\|workflow` | installer                                                           | install/update      | **só via update do kiro-ai-team** (regra do time; mudança local = PR no central) | todos, sempre                    |
| `steering/guidelines/*`                              | installer                                                           | install/update      | via update do kiro-ai-team                                                       | agente do stack, por `fileMatch` |
| `steering/product.md`                                | template vazio → **humano escreve**                                 | onboarding do repo  | humano, quando o produto muda                                                    | todos, sempre                    |
| `steering/tech.md`                                   | template → `reverse-engineer-project` preenche → **humano confere** | onboarding          | humano, quando o stack/build muda                                                | todos, sempre (build/test cmds!) |
| `steering/structure.md`                              | template → `reverse-engineer-project` preenche                      | onboarding          | humano ou re-run do eixo                                                         | todos, sempre                    |
| `steering/retro-learnings.md`                        | template vazio                                                      | onboarding          | **só a skill `retrospective`** (nunca pré-popular)                               | todos, sempre                    |
| `docs/context/*` (8 eixos)                           | `reverse-engineer-project`                                          | onboarding          | re-run **por eixo** quando `audit-integration` detectar drift                    | por eixo — ver §3                |
| `.kiro/specs/<slug>/requirements.md`                 | `write-requirements` (spec-analyst)                                 | por PBI feature     | congelado; mudança só via nova rodada com humano + changelog no rodapé           | qa-blackbox, reviewer-spec, devs |
| `.kiro/specs/<slug>/design.md`                       | `write-design`                                                      | por PBI feature     | idem (decisões novas viram entrada, não edição silenciosa)                       | qa-blackbox (contratos), devs    |
| `.kiro/specs/<slug>/tasks.md`                        | `write-tasks`                                                       | por PBI (2 trilhos) | dev marca `[x]`; escopo não muda sem voltar à spec                               | dev, orchestrator                |
| `docs/issues/<ID>.md`                                | `triage-issue`/`triage-crash`/`audit-integration`                   | entrada de trabalho | `resolve-issue` anexa `## Resolução`                                             | orchestrator, spec-analyst       |
| `docs/tests-spec/<slug>.md`                          | `write-blackbox-tests` (qa-blackbox)                                | por PBI             | qa-blackbox apenas                                                               | merge-gate (G1), reviewer-spec   |
| `docs/reviews/<PBI>-{verify,spec,code,gate}.md`      | verify-change / revisores / merge-gate                              | por PBI             | ninguém (é registro, não documento vivo)                                         | merge-gate, auditor, humano      |

Regra transversal: **installer sobrescreve o que é do time, nunca toca o que é do projeto/pessoal** (templates copiados só se ausentes).

## 2. Steering — 3 camadas e ciclo de vida

```
principios.md (global, pessoal)      ← você, 1x, evolui raramente
   ▼ (workspace VENCE global em conflito)
regras do time (escalation/gates/workflow/guidelines)  ← kiro-ai-team, via update
   ▼
contexto do projeto (product/tech/structure) + retro-learnings  ← humano + retrospective
```

- **Prescritivo e injetado**: steering entra no contexto automaticamente (`always`/`fileMatch`). Por isso é curto — regra, não enciclopédia.
- `fileMatch` **só funciona no workspace** (bug conhecido no global) → guidelines por stack ficam no projeto mesmo sendo "do time".
- `retro-learnings.md` só cresce por falha real repetida (`retrospective`); revisar semestralmente e podar regra que nunca mais disparou.
- Nativo do Kiro que você pode usar junto: painel Steering → **"Generate Steering Docs"** gera os foundation files (product/tech/structure) analisando o código; `AGENTS.md` em `~/.kiro/steering/` ou na raiz do workspace é sempre incluído, sem modos. Docs: kiro.dev/docs/steering.

## 3. docs/context — descritivo, sob demanda, por eixo

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

- **qa-blackbox NUNCA lê docs/context** — os eixos derivam do código; ler seria black-box furado. Fontes dele: requirements + contratos do design + tech.md (como rodar).
- Manutenção: `audit-integration` detecta drift documentado×real → re-run **do eixo específico**, nunca do pacote inteiro.
- Steering responde "**como devo me comportar**"; context responde "**como este sistema é**". Se um conteúdo é regra, é steering; se é descrição, é context.

## 4. Onboarding de um repo — sequência canônica

1. `install.sh <repo>` (ou `--scope hybrid`) → esqueletos + regras do time.
2. `reverse-engineer-project` → `docs/context/` + `tech.md`/`structure.md` preenchidos.
3. Humano: **confere `tech.md`** (os comandos de build/teste são o que `implement-task`, `verify-change` e `merge-gate` executam — comando errado aqui quebra os gates) e **escreve `product.md`** (5–10 linhas; o _porquê_ não está no código).
4. Mesclar MCPs do repo; ativar hooks desejados.
5. Commit do `.kiro/` + `docs/context/`.
6. Primeiro PBI pelo trilho manutenção (menor ciclo que exercita todos os gates).

## 5. O que é nativo do Kiro vs. do kiro-ai-team

| Nativo (docs oficiais)                                                       | kiro-ai-team (este repo)                                                          |
| ---------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| specs requirements/design/tasks, execução de tasks                           | conteúdo/formato EARS + gates embutidos via skills `write-*`                      |
| steering workspace + global (`~/.kiro/steering`), AGENTS.md, inclusion modes | as 3 camadas, templates, política de sobrescrita                                  |
| agents, skills SKILL.md, hooks, MCP (user+workspace)                         | os 9 papéis, 15 skills, fragmentos, escopos do installer                          |
| "Generate Steering Docs" (foundation files)                                  | `reverse-engineer-project` (docs/context por eixos + preenchimento dos templates) |

Quirks conhecidos consolidados: fileMatch global não injeta; symlink em `~/.kiro` ignorado; IDE ignora `KIRO_HOME`; workspace vence global; campo `model` em custom agents; sintaxe `${VAR}` vs `${env:VAR}`.
