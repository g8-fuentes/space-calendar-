# Rotina Quest

A rotina semanal do Guilherme Fuentes como uma jornada espacial em pixel art.
Cada evento da agenda "Rotina" é uma missão; cumprir missões dá XP e moedas,
leva o astronauta mirim por Terra, Lua, Marte… até Proxima Centauri, e depois
por mundos gerados sem fim.

## Gerar o APK

### Opção 1: GitHub (sem instalar nada)

1. Crie um repositório no GitHub e envie esta pasta.
2. A ação **Android APK** roda sozinha (ou em *Actions → Android APK → Run workflow*).
3. Ao terminar, baixe o artefato **rotina-quest-apk** e instale o `app-release.apk` no celular
   (permita "instalar apps de fontes desconhecidas").

### Opção 2: no seu computador

Requer Flutter 3.27 ou mais novo, Android SDK e Java 17.

```bash
bash tool/prepare_android.sh   # gera a pasta android/ na primeira vez
flutter pub get
flutter test
flutter build apk --release
# APK em build/app/outputs/flutter-apk/app-release.apk
```

O APK de release é assinado com a chave de debug, o que basta para instalar no seu
próprio celular. Para publicar na Play Store, configure uma chave de assinatura própria.

## Arquitetura

Clean Architecture por feature, com estado em Riverpod:

```
lib/
  main.dart                     composição: cria dependências e injeta no Riverpod
  app/                          MaterialApp, rotas (go_router) e tema Kanagawa
  core/time/                    Clock injetável e utilitários de semana
  features/game/
    domain/                     regras puras, sem Flutter
      entities/                 Quest, GameState (imutável, serializável)
      catalog/                  agenda, cursos, ranks, destinos, loja, conquistas
      services/game_rules.dart  casos de uso: estado -> novo estado
      services/game_stats.dart  números derivados (XP, moedas, nível, destino)
      repositories/             contrato de persistência
    data/                       SharedPreferences + implementação do repositório
    presentation/
      controllers/              GameController (Notifier) e providers
      art/                      pixel art desenhada em código (CustomPainter)
      widgets/                  cena espacial, HUD, componentes pixel
      screens/                  Missões, Jornada, Semana, Cursos, Loja, Perfil
test/
  domain/                       regras do jogo
  widget/                       teste de fumaça do app
```

Princípios usados:

- **Domínio puro**: as regras não dependem de Flutter nem de armazenamento, então são testáveis isoladamente.
- **Estado derivado**: só o que você fez é salvo (missões marcadas, compras, aulas). XP, moedas, nível,
  rank e destino são sempre recalculados, então nunca ficam inconsistentes.
- **Injeção de dependências**: relógio e repositório entram por providers, e os testes trocam por versões falsas.
- **Progressão infinita**: níveis, ranks, trajes, destinos, melhorias e medalhas são gerados por fórmulas,
  sem lista final.

## Atualizar a agenda

A agenda está em `lib/features/game/domain/catalog/schedule.dart`. Para mudar um horário ou
adicionar uma atividade, edite a lista do dia e gere o APK de novo. O progresso salvo é por
identificador da missão (dia + posição), então inserir uma missão no meio de um dia pode
deslocar as marcações daquela semana.
