---
name: audit-integration
description: (Somente auditor) Audita o repo inteiro atrás do que a revisão por PBI não vê — duplicação entre PBIs, drift spec×código, segurança inconsistente — e emite briefs. Use a cada ~5 merges (o merge-gate avisa) ou quando pedirem 'auditoria', 'varre o repo inteiro', 'tem duplicação?'.
---
# audit-integration
## Passos
1. Delimitar a janela: merges `pbi/*` desde a última auditoria.
2. Caçar: (a) implementações duplicadas/quase-duplicadas entre PBIs da janela; (b) drift entre specs congeladas e comportamento atual; (c) padrões de segurança divergentes (um PBI valida, outro não); (d) débito que contradiz design registrado.
3. Cada achado confirmado → brief em `docs/issues/AUDIT-<n>.md` (formato padrão, `origem: audit`), com severidade e evidência.
4. Padrão de falha REPETIDO (2+ PBIs) → acionar retrospective.
## Regras
- Só reporta; nunca corrige. Achado sem evidência concreta não vira brief.
