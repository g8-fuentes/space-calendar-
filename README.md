# Space Routine

A rotina semanal do Guilherme Fuentes como uma missão espacial em pixel art, com
o Guilherme como astronauta.
Importe a agenda num arquivo .ics ou .ical (no Google Agenda: Configurações > Importar e
exportar > Exportar): cada evento com horário vira uma missão semanal. Cada semana o astronauta explora
um destino: começa na Terra (Bauru), passa pela Lua e pelos planetas e depois sai do Sistema
Solar rumo às estrelas vizinhas, nebulosas e galáxias, sem fim. Cumprir metade das missões da
semana explora o destino, e na segunda-feira a nave parte para o próximo. Cada missão também
dá pontos ao atributo da categoria dela, e os pontos levam o astronauta a novos níveis (de
Cadete espacial a Astronauta cósmico, sem nível final), com traje, visor, mochila a jato e aura
novos e uma frase de quem olhou para as estrelas.

Na aba Tarefas dá para anotar o que fazer no dia (criar, editar, excluir e marcar como
concluída). Cada tarefa concluída dá pontos de Disciplina, e uma chama em pixel art cresce
com as tarefas dos últimos 7 dias e vai baixando quando elas param.

## Gerar o APK

### Opção 1: GitHub (sem instalar nada)

1. A ação **Android APK** roda a cada envio para `main` (ou em *Actions → Android APK → Run workflow*).
2. Ao terminar, baixe o artefato **space-routine** e instale o `space-routine.apk` no celular
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
