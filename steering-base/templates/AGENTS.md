# AGENTS.md — regras para QUALQUER agente de IA neste repositório

(Padrão aberto agents.md — vale para Kiro, Claude, Codex, Cursor etc.)

Este repo é governado pelo **kiro-ai-team**. Antes de qualquer mudança:

1. Leia `.kiro/steering/workflow.md`, `escalation-rules.md` e `quality-gates.md`.
2. Trabalho entra por `docs/issues/`; specs em `.kiro/specs/<slug>/` (requirements → design → tasks).
3. **Nenhum merge sem os gates G1–G5** — verificados por `.kiro/skills/merge-gate/scripts/check-gates.sh`.
4. Ambiguidade na spec: PARE e pergunte (formato do escalation-rules). Nunca assuma.
5. "Pronto" sem evidência observada não conta — mostre comando e saída.
6. Convenções por stack em `.kiro/steering/guidelines/`. A consistência do repo vence o seu default.
7. Comandos de build/teste/verificação: `.kiro/steering/tech.md`.

**Cross-review (ex.: Codex como segundo modelo):** assuma o papel reviewer-code — siga `.kiro/skills/review-code/SKILL.md` e grave o veredicto em `docs/reviews/<PBI>-code.md`. Não leia a conversa dos devs.
