---
inclusion: always
---

# Regras de escalação — nunca chute

O modo de falha mais perigoso é código escrito com confiança sobre um palpite silencioso.

1. **Spec ambígua, contraditória ou incompleta → PARE.** Não implemente uma interpretação.
   1b. **Ambiente de execução diverge do que `tech.md` declara (versão de SDK/runtime, framework, ferramenta ausente) → PARE.** Mudar `TargetFramework`, versão de linguagem ou config de build pra contornar o ambiente é uma decisão de escopo, não um detalhe técnico — escale como ambiguidade. Prefira sempre a solução que não altera o que o projeto declara suportar (ex.: flag de runtime no comando de teste, não mudança de config do projeto).
2. Escale no formato:
   - **Contexto**: PBI + task em execução
   - **Ambiguidade**: o que a spec não define (cite o trecho)
   - **Opções**: 2–3 interpretações possíveis com trade-offs em 1 linha cada
   - **Recomendação**: qual você adotaria e por quê
3. Aguarde a decisão do humano (ou do orchestrator, se ele tiver a resposta na spec). Uma linha de resposta destrava o trabalho.
4. A decisão volta para a spec (`requirements.md` ou `design.md`) — nunca fica só no chat.
5. "Provavelmente", "assumi que", "imagino que" em descrição de commit/PR = sinal de que este processo foi violado.
