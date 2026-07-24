# MIGRATION — do agent-skills antigo para o kiro-ai-team

Instalar o kiro-ai-team num ambiente que já tem as skills anteriores cria **duplicatas concorrendo pelo trigger** (duas descriptions parecidas = disparo errático). Migre antes do primeiro PBI.

## Mapa de migração

| Skill antiga | No kiro-ai-team | Ação |
|---|---|---|
| `write-prd` | `write-requirements` (formato Kiro/EARS) | **remover** a antiga |
| `plan-change` | `write-tasks` | **remover** |
| `implement-change` | `task-preflight` (pré-flight/checkpoint; execução é o "Start task" nativo do Kiro) | **remover** |
| `review-change` | `review-spec` + `review-code` (split adversarial) | **remover** |
| `dotnet-guidelines` (skill) | `steering/guidelines/dotnet.md` (fileMatch) | **remover** a skill |
| `issue-analysis`, `feature-spec` (era OpenCode) | `triage-issue` / `write-requirements` | **remover** |
| `write-design`, `verify-change`, `triage-issue`, `resolve-issue`, `triage-crash`, `reverse-engineer-project` | mesmo nome | sobrescritas pelo install — nada a fazer |

## Passos

1. Detectar colisões local × global:
   ```bash
   comm -12 <(ls .kiro/skills 2>/dev/null | sort) <(ls ~/.kiro/skills 2>/dev/null | sort)
   ```
2. Remover as renomeadas (nos DOIS níveis, se existirem):
   ```bash
   for s in write-prd plan-change implement-change review-change implement-task dotnet-guidelines issue-analysis feature-spec dotnet-backend; do
     rm -rf ".kiro/skills/$s" "$HOME/.kiro/skills/$s"
   done
   ```
3. Rodar `install.sh` no escopo escolhido.
4. **Reindexar**: o Kiro tem quirk conhecido de indexação de skills — reinicie o IDE/CLI após adicionar/remover skills e confirme no painel "Agent Steering & Skills" que só a versão nova aparece.
5. Repositórios que referenciam nomes antigos em steering/hooks/docs: `grep -rl 'plan-change\|write-prd\|implement-change\|review-change' .kiro/ docs/ || true` e atualize.

## Regra permanente
Um nome de skill existe em **um** lugar (local OU global, nunca ambos) e com **uma** versão. Duplicata é bug, não redundância.
