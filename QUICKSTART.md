# QUICKSTART — operando o kiro-ai-team

Guia de onboarding: como instalar, operar o dia a dia e decidir quando usar (ou não usar) o time.

> Ciclo de vida completo de steering, specs e `docs/context/` (quem cria, quando muda, quem lê): [MANUAL.md](MANUAL.md)

---

## 1. Setup (uma vez por repo)

```bash
git clone <org>/kiro-ai-team
./kiro-ai-team/install.sh /caminho/do/projeto --stack dotnet    # repo só .NET — recomendado
./kiro-ai-team/install.sh /caminho/do/projeto                   # sem --stack: instala TODOS os stacks (dev-dotnet/webforms/flutter + guidelines) — pode dele depois
./kiro-ai-team/install.sh /caminho/do/projeto --update          # atualizar versão (mesmo --stack usado na instalação original)
```

`--stack dotnet|webforms|flutter` instala só o(s) agente(s) `dev-*` e guideline(s) do stack informado (mais os 6 papéis stack-agnósticos: orchestrator, spec-analyst, qa-blackbox, reviewer-spec, reviewer-code, auditor). Repo multi-stack (ex.: backend .NET + app Flutter) → omita `--stack` e pode manualmente os agentes/guidelines que sobrarem sem uso (`.kiro/agents/dev-*.json`, `.kiro/steering/guidelines/*.md`) — instalar `dev-flutter` num repo sem Flutter é ruído que pode confundir o orchestrator na hora de rotear.

Depois do install:

1. **MCP** — mescle em `.kiro/settings/mcp.json` apenas os fragmentos de `kiro-ai-team/mcp/` que este repo usa (Jira/Bitbucket? GitHub? Firebase? SQLcl?). Preencha credenciais/workarounds locais.
2. **Hooks** — copie de `kiro-ai-team/hooks/` para `.kiro/hooks/` os que fizerem sentido (format-dotnet, format-flutter, issue-intake…). Alguns já vêm com `"enabled": false` de propósito (ex.: `post-merge-audit`, é `"when": {"type": "manual"}` — dispara só quando você pedir, não por gatilho automático). Pra ativar por gatilho automático: edite o campo `"enabled"` do `.kiro.hook` pra `true` e confirme o `"when"` desejado (`fileEdited`, `fileCreated` etc.) — não há necessidade de painel de UI, é edição direta do JSON.
3. **Steering do projeto** — preencha `product.md`, `tech.md` (build/test commands!) e `structure.md`. Atalho: rode a skill `reverse-engineer-project`, que gera `docs/context/` e preenche os templates vazios.
4. **Vindo do agent-skills antigo?** Siga [MIGRATION.md](MIGRATION.md) ANTES do primeiro PBI (duplicata de skill = trigger errático).
5. **Commit do `.kiro/` + `AGENTS.md`** — o time é versionado junto do código; quem clonar o repo herda o time.
6. **Reinicie o IDE/CLI (ou reload window)** — instalação nova adiciona agentes/skills; o Kiro tem quirk conhecido de indexação (mesmo quirk documentado no [MIGRATION.md](MIGRATION.md) pra quem já tinha skills antigas). Confirme no painel "Agent Steering & Skills" que os 6-9 agentes e as skills aparecem antes do primeiro PBI.
7. **(Recomendado) `kiroAgent.trustedCommands`** — sem isso, todo `dotnet test`/`flutter test`/`check-gates.sh` pede aprovação manual. Configure em Settings → Kiro Agent: Trusted Commands (global ou por workspace) os comandos de build/test do seu stack, com `*` no final pra aceitar argumentos (ex.: `"dotnet test *"`, `"git status *"`). Nunca confie largo em comandos destrutivos (`git push`, `git reset --hard`, `npx *`) nem em `check-gates.sh` (recebe `--test-cmd` arbitrário — aprovação manual aqui é intencional).

Sanidade: `.kiro/.kiro-ai-team-version` deve mostrar a versão instalada.

### Escopos de instalação

| Escopo               | Comando                             | Quando usar                                                                              |
| -------------------- | ----------------------------------- | ---------------------------------------------------------------------------------------- |
| **project** (padrão) | `./install.sh /repo`                | Recomendado: time versionado no git do repo, versão pinada por projeto                   |
| **global**           | `./install.sh --scope global`       | Engine (agents+skills) uma vez em `~/.kiro`, compartilhada por todos os repos da máquina |
| **hybrid**           | `./install.sh /repo --scope hybrid` | Engine global + camada fina no projeto (steering, docs, templates)                       |

Notas:

- **Steering global existe** (`~/.kiro/steering/`, desde a v0.5): o escopo `global` instala `principios.md` — seu "system prompt" pessoal, sempre incluído. Regras: workspace **vence** global em conflito; evite `fileMatch` no global (bug de não-injeção); arquivo real, sem symlink; IDE ignora `KIRO_HOME`. Contexto do projeto e retro-learnings continuam **sempre por workspace**.
- No hybrid, a engine local é omitida de propósito (evita conflito de nomes de agente); se as versões global × projeto divergirem, o installer avisa.
- Trade-off do global: você perde o pin de versão por repo — todos os projetos da máquina passam a usar a mesma engine. Em times, prefira `project`; global/hybrid brilham na máquina pessoal com muitos repos.
- MCP pode ir para os dois lugares: credenciais/servidores comuns em `~/.kiro/settings/mcp.json`, específicos do repo no `mcp.json` do projeto.

---

## 2. Operação diária

Você conversa quase só com o **orchestrator**. Fluxo típico:

**Como a ativação funciona de fato:**

- **Skill**: você nunca digita o nome da skill — o Kiro casa sua frase contra o campo `description` de cada `SKILL.md` (por isso as descriptions são escritas como lista de gatilhos: "Use quando disserem 'X', 'Y'"). Fale em linguagem natural o que quer fazer.
- **Agente**: cada `.kiro/agents/*.json` é um agente customizado selecionável no seletor de agente do chat (canto do painel, ao lado do model picker). Trocar de agente **nesse mesmo seletor mantém o histórico da conversa** — o agente novo enxerga tudo que foi dito antes. Isso é o oposto do que "sessão limpa" precisa (ver Passo 4).

### Passo 1 — Entrada

> "orchestrator, faça a triagem da PROJ-1234"

Ele roda `triage-issue` (busca no Jira/Azure Boards/GitHub via MCP, ou você cola o texto), gera o brief em `docs/issues/` e recomenda o trilho. Crash do app? `triage-crash` gera o brief no mesmo formato.

### Passo 2 — Spec

- **Trilho feature** → agente `spec-analyst`:
  `write-requirements` (ele **pergunta antes de congelar** — responda e siga) → `write-design` → `write-tasks`.
- **Trilho manutenção** → direto `write-tasks` mínimo a partir do brief.

Resultado: `.kiro/specs/<slug>/tasks.md` com os gates G1–G5 já embutidos no final.

### Passo 3 — Execução (paralela, contextos separados)

```bash
./kiro-ai-team/scripts/worktree.sh start PROJ-1234
```

- No worktree: agente `dev-dotnet` | `dev-webforms` | `dev-flutter` → "execute as tasks do PBI PROJ-1234" (`implement-task`, uma task por commit).
- "**Outra sessão**" pro `qa-blackbox` (e pros reviewers no Passo 4) significa **aba de chat nova** (ícone "+" no painel, ou `/chat new` na CLI) **com o agente selecionado nessa aba nova** — nunca só trocar o agente na mesma aba onde o dev trabalhou. Ele lê só a spec, nunca `src/` — não interfira nisso, é o mecanismo central.
- Dev terminou → `verify-change` com evidência real (não aceite "pronto").

### Passo 4 — Qualidade e merge

- **Sessão limpa de verdade = aba nova.** Trocar de agente no seletor do MESMO painel mantém o histórico — o revisor veria a conversa do dev e a revisão deixa de ser adversarial. Abra aba nova ("+" ou `/chat new`) pra cada revisor abaixo:
  - Sessão limpa 1 (aba nova): `reviewer-spec` → `review-spec` (diff × requirements).
  - Sessão limpa 2 (outra aba nova): `reviewer-code` → `review-code`.
- > "orchestrator, merge-gate do PROJ-1234"
  > Ele confere as 5 evidências **em disco**, roda a regressão, mescla serializado, `worktree.sh finish`, e fecha no tracker de origem com `resolve-issue`.

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

**Regra de bolso:** vai para produção → passa pelos gates. É descartável → não passe.

---

## 4. Multi-repo

PBI que atravessa backend + app = **um brief por repo, vinculados** (campo `vinculado a:` do brief). Cada um passa pelos próprios gates no próprio worktree; `resolve-issue` só fecha a issue externa quando **todos** os irmãos passarem no merge-gate.

## 5. Anti-padrões (não faça)

- Pedir ao dev para "já escrever os testes junto" — mata o black-box.
- Colar a conversa do dev para o reviewer — mata a revisão adversarial.
- Mesclar "só dessa vez" sem merge-gate — o valor do sistema é exatamente não abrir essa exceção.
- Editar teste do qa-blackbox para passar — teste vermelho legítimo significa implementação errada **ou spec errada**; escale.

## 6. Problemas comuns

| Sintoma                               | Causa provável                                         | Ação                                                           |
| ------------------------------------- | ------------------------------------------------------ | -------------------------------------------------------------- |
| Agente "assumiu" algo na spec         | escalation-rules não carregado                         | conferir steering `inclusion: always`                          |
| qa-blackbox não consegue testar       | contrato público ausente no design                     | devolver ao spec-analyst (é feature do sistema, não bug)       |
| merge-gate reprovou com tudo "pronto" | evidência não está em disco                            | gerar os arquivos de `docs/reviews/` — relato verbal não conta |
| MCP falha no Windows                  | quirks conhecidos (portproxy Bitbucket, wrapper SQLcl) | ver comentários nos fragmentos de `mcp/`                       |
