# Dev Routine

A rotina semanal do Guilherme Fuentes como a jornada de um dev em pixel art, subindo de nível
dentro de um terminal na Matrix.

Importe a agenda num arquivo .ics ou .ical (no Google Agenda: Configurações > Importar e
exportar > Exportar): cada evento com horário vira uma missão semanal. Cada semana o dev entra num
destino novo: começa na pasta `~` da sua máquina, passa pela rede e pela nuvem e termina dentro da
Matrix, sem fim. Cumprir metade das missões da semana explora o destino, e na segunda-feira o dev
entra no próximo. Cada missão também dá pontos ao atributo da categoria dela (só atividade física
conta como Força), e os pontos levam o dev a novos níveis, de Visitante (guest) a O Escolhido, sem
nível final, com moletom, fones, notebook, óculos escuros e aura novos e uma frase de programador.

O app tem três abas:

- **Explorar**: a cena com a chuva de código, as missões, o mapa da jornada (pelo botão) e o resumo
  da semana no fim.
- **Personagem**: o nível atual, os atributos, a Disciplina (a chama e as tarefas do dia) e todos
  os níveis, os que faltam apagados.
- **Ajustes**: agenda, tema claro (Tokyo Night Day; o escuro é o Tokyo Night Moon), música eletrônica, sons, notificações e nome.

Cada tarefa do dia concluída dá pontos de Disciplina, e a chama cresce com as tarefas dos últimos
7 dias e vai baixando quando elas param. A música é eletrônica e instrumental (house, techno,
synthwave e breaks), gerada no próprio app.

## Gerar o APK

### Opção 1: GitHub (sem instalar nada)

1. A ação **Android APK** roda a cada envio para `main` (ou em *Actions → Android APK → Run workflow*).
2. Ao terminar, baixe o artefato **dev-routine** e instale o `dev-routine.apk` no celular
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
      catalog/                  categorias, destinos de cada semana, níveis e frases
      services/                 importação .ics/.ical, regras e números derivados
      repositories/             contrato de persistência
    data/                       SharedPreferences + implementação do repositório
    presentation/
      controllers/              GameController (Notifier) e providers
      art/                      pixel art desenhada em código (CustomPainter)
      widgets/                  cena, personagem, componentes pixel
      screens/                  Explorar, Tarefas, Personagem, Mapa, Semana, Ajustes
test/
  domain/                       regras do jogo
  widget/                       teste de fumaça do app
```

Os pontos e o nível são sempre recalculados a partir das missões marcadas; o destino vem
das semanas em que a meta foi cumprida. O ícone é gerado em pixel art e fica em `android/app/src/main/res`.
