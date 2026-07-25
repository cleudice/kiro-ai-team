# kiro-ai-team — Time de IA para Kiro

Camada de governança multiagente sobre o Kiro: papéis separados, gates mecânicos e specs nativas (requirements → design → tasks), cobrindo o ciclo completo de features **e** manutenção.

> **Filosofia (loop engineering):** não apostamos em agentes que não erram; apostamos em estrutura onde o erro é detectado, contido e aprendido. Nenhum agente aprova o próprio trabalho.

## Regra de ouro (a "dualidade")

| Vive no **kiro-ai-team** (central)                       | Vive no **repo do projeto**                                        |
| -------------------------------------------------------- | ------------------------------------------------------------------ |
| Agentes (papéis genéricos)                               | `.kiro/specs/` (requirements/design/tasks)                         |
| Skills (procedimentos do ciclo)                          | `steering/product.md`, `tech.md`, `structure.md`                   |
| Steering-base (regras universais + guidelines por stack) | `steering/retro-learnings.md` (aprendizados do projeto)            |
| Templates de hooks e MCP                                 | `docs/{issues,reviews,context}/`, `mcp.json` efetivo               |
| Scripts (install, worktree)                              | Agentes específicos do projeto (ex.: analista de crashes do app X) |

O central é **versionado por tag**; cada projeto instala uma versão e atualiza via `install.sh`.

## O ciclo completo

```
            ┌────────────── ENTRADA (multi-tracker) ──────────────┐
Jira / Azure Boards / GitHub Issues / Crashlytics → triage-issue │ triage-crash
            └──────────────────────┬──────────────────────────────┘
                                   ▼  docs/issues/<ID>.md (brief normalizado)
                    ┌── trilho FEATURE ──┐        ┌─ trilho MANUTENÇÃO ─┐
                    write-requirements    │        │ (pula spec formal)
                    write-design          │        │
                    G0 review-spec draft  │        │
                    write-tasks ──────────┴────────┴─ write-tasks (mínimo, orchestrator)
                                   ▼  .kiro/specs/<slug>/tasks.md
    task-preflight + "Start task" nativo (dev-* em worktree)   ∥   write-blackbox-tests (qa-blackbox,
                                   ▼                        worktree QA sem src/, só lê a spec)
                              verify-change (evidência observada)
                                   ▼
                    review-spec  +  review-code  (sessões limpas)
                                   ▼
                              merge-gate (orchestrator: 5 checks ✔)
                                   ▼
                              resolve-issue → tracker de origem
                                   ▼
          a cada N merges: audit-integration → issues p/ próximo ciclo
          falha recorrente: retrospective → steering/retro-learnings.md
```

## Papéis (agents/)

| Agente          | Faz                                                  | Não faz                 |
| --------------- | ---------------------------------------------------- | ----------------------- |
| `orchestrator`  | roteia, acompanha estado, executa merge-gate         | escrever código         |
| `spec-analyst`  | brief → spec Kiro (EARS); pergunta antes de congelar | implementar             |
| `dev-dotnet`    | .NET 8/10, Clean Arch, CQRS                          | tocar spec de outro PBI |
| `dev-webforms`  | WebForms 4.8, ADO.NET, PL/SQL                        | idem                    |
| `dev-flutter`   | Flutter/Dart + Firebase                              | idem                    |
| `qa-blackbox`   | testes só a partir da spec                           | **ler `src/`**          |
| `reviewer-spec` | diff vs requirements.md                              | ler conversa dos devs   |
| `reviewer-code` | qualidade, convenção, segurança                      | aprovar requisito       |
| `auditor`       | auditoria pós-integração do repo inteiro             | corrigir (só reporta)   |

> 📖 Setup, operação diária e referência completa (agentes, skills, gates, ciclo de vida dos artefatos): [OPERACAO.md](OPERACAO.md)

## Instalação num projeto

Pré-requisito: `python3` no PATH (o installer usa pro manifesto JSON e falha cedo com mensagem clara se ausente — no Git Bash do Windows, confirme antes).

```bash
./install.sh /caminho/do/projeto --stack dotnet   # recomendado: só o dev do stack deste repo
./install.sh /caminho/do/projeto                  # sem --stack: instala os 3 devs (dotnet/webforms/flutter)
./install.sh --scope global                       # engine em ~/.kiro (todos os repos)
./install.sh /caminho/do/projeto --scope hybrid   # engine global + camada do projeto
./install.sh /caminho/do/projeto --update         # atualizar (lembra o --stack da instalação original; poda só o que O TIME instalou e saiu do central — agentes/skills próprios do projeto sobrevivem; --prune-unmanaged converge TUDO, use com cautela)
./install.sh /caminho/do/projeto --dry-run        # mostra o que seria feito, sem tocar em nada
./install.sh /caminho/do/projeto --uninstall      # remove agents/skills/hooks-scripts do time e limpa o que o installer pôs no .gitignore (preserva steering/docs do projeto)
```

> Sobre os hooks: nenhum dos triggers (`PostFileSave`, `PostTaskExec`, `SessionStart`, `PostFileCreate`) foi verificado empiricamente contra um Kiro real ainda — coerência com a nossa própria filosofia ("autorrelato não conta") exige dizer isso aqui. Procedimento e status: [hooks/VERIFY.md](hooks/VERIFY.md). Trate a mecanização por hook como best-effort; os gates em disco não dependem dela.

Steering e docs/ são sempre por projeto (steering do Kiro é por workspace). Detalhes, `--stack` e trade-offs: [OPERACAO.md](OPERACAO.md).

Copia agentes + skills + steering-base, instancia os templates de steering do projeto (se ausentes) e grava a versão em `.kiro/.kiro-ai-team-version`.

## Renomeações (v1 → kiro-ai-team)

| Antes                      | Agora                                | Motivo                                                                                                                              |
| -------------------------- | ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| scrum-master               | `orchestrator`                       | descreve a função, não a cerimônia                                                                                                  |
| requirements-analyst       | `spec-analyst`                       | alinhado ao conceito de spec do Kiro                                                                                                |
| dev-legacy                 | `dev-webforms`                       | nome pelo stack, não pelo juízo                                                                                                     |
| test-writer-blackbox       | `qa-blackbox`                        | papel curto e reutilizável                                                                                                          |
| reviewer-requisitos/codigo | `reviewer-spec` / `reviewer-code`    | padrão `reviewer-<eixo>`                                                                                                            |
| write-prd / plan-change    | `write-requirements` / `write-tasks` | espelham os arquivos nativos do Kiro                                                                                                |
| audit-sprint               | `audit-integration`                  | nomeia o que audita                                                                                                                 |
| implement-task             | `task-preflight`                     | deixou de "implementar" — quem executa a task é o "Start task" nativo do Kiro; o skill só prepara (worktree/build) e faz checkpoint |
