# Divine Routine

A rotina semanal do Guilherme Fuentes como uma jornada de fé em pixel art.
Importe a agenda (.ics ou .cal) e marque as missões concluídas. Cada missão dá pontos
ao atributo da categoria dela, e os pontos levam o personagem, um jovem adulto, a novos
níveis: a cada nível ele fica mais perto de Jesus e de Deus, com mais luz, auréola, raios
do céu e asas, e recebe uma passagem da Bíblia. Não há nível final. Ao mesmo tempo, ele
caminha pela Terra Santa (de Belém ao Cenáculo), sobe acima das nuvens e segue pelos céus,
sem fim, com Jesus cada vez mais perto na cena.

## Gerar o APK

### Opção 1: GitHub (sem instalar nada)

1. A ação **Android APK** roda a cada envio para `main` (ou em *Actions → Android APK → Run workflow*).
2. Ao terminar, baixe o artefato **divine-routine** e instale o `divine-routine.apk` no celular
   (permita "instalar apps de fontes desconhecidas").

### Opção 2: no seu computador

Requer Flutter, Android SDK e Java 17.

```bash
bash tool/prepare_android.sh   # recria a pasta android/ se ela tiver sido apagada
flutter pub get
flutter test
flutter build apk --release
# APK em build/app/outputs/flutter-apk/app-release.apk
```

O APK é assinado com a chave fixa `android/app/rotina-quest.jks`, então cada versão
instala por cima da anterior e mantém o progresso.

## Arquitetura

Clean Architecture por feature, com estado em Riverpod:

```
lib/
  main.dart                     composição: cria dependências e injeta no Riverpod
  app/                          MaterialApp, abas e tema Kanagawa
  core/                         relógio, tempo de Bauru, notificações, música e sons
  features/game/
    domain/                     regras puras, sem Flutter
      entities/                 Mission, GameState (serializável)
      catalog/                  categorias, lugares da jornada, níveis e passagens da Bíblia
      services/                 importação .ics, regras e números derivados
      repositories/             contrato de persistência
    data/                       SharedPreferences + implementação do repositório
    presentation/
      controllers/              GameController (Notifier) e providers
      art/                      pixel art desenhada em código (CustomPainter)
      widgets/                  cena, personagem, componentes pixel
      screens/                  Explorar, Personagem, Mapa, Semana, Ajustes
test/
  domain/                       regras do jogo
  widget/                       teste de fumaça do app
```

Os pontos, o nível e o lugar são sempre recalculados a partir das missões marcadas, então
nunca ficam inconsistentes. O ícone é gerado em pixel art e fica em `android/app/src/main/res`.
