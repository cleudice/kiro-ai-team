---
inclusion: fileMatch
fileMatchPattern: "**/*.dart"
---
# Guidelines Flutter/Dart
- Seguir a arquitetura e o gerenciador de estado JÁ adotados no app — consistência vence preferência.
- `flutter analyze` limpo e `dart format` aplicado a cada task.
- Widgets: composição sobre herança; extrair widget quando o build passar de ~1 tela de código.
- Async: tratar erro de todo `Future`; nunca engolir exceção de stream.
- Firebase: crashlytics para erro não-fatal relevante; nada de dado sensível em logs/keys de analytics.
- Null safety idiomático; evitar `!` — preferir fluxo que prova o não-nulo.
