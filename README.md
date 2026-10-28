# Dev Odyssey

A rotina semanal do Guilherme Fuentes como a exploração espacial de um dev, em pixel art.
O app sincroniza direto com o Google Agenda (só leitura): os eventos com horário da semana
viram missões, e a agenda atualiza sozinha toda vez que o app abre. Cada semana o dev explora
um destino: começa na Terra (Bauru), passa pela Lua e pelos planetas e depois sai do Sistema
Solar rumo às estrelas vizinhas, nebulosas e galáxias, sem fim. Cumprir metade das missões da
semana explora o destino, e na segunda-feira a nave parte para o próximo. Cada missão também
dá pontos ao atributo da categoria dela, e os pontos levam o dev a novos níveis (de Estagiário
a Dev Cósmico, sem nível final), com roupa, cabelo e aura novos e uma frase de dev ou de
explorador do espaço.

## Google Agenda

O app pede a conta Google do celular e a permissão `calendar.readonly`. Para o Google
reconhecer o app, o projeto do Google Cloud precisa ter:

1. A **Google Calendar API** ativada.
2. A tela de consentimento OAuth (Externo, em Teste) com a sua conta nos usuários de teste.
3. Um cliente OAuth **Android** com o pacote `com.guilhermefuentes.rotina_quest` e o SHA-1
   da chave `android/app/rotina-quest.jks`:
   `47:EB:96:0A:EF:B5:A2:1F:D1:87:7E:83:8F:C8:E3:D1:13:06:5D:71`.

Sem Google, dá para importar um arquivo `.ics` em Ajustes.

## Gerar o APK

### Opção 1: GitHub (sem instalar nada)

1. A ação **Android APK** roda a cada envio para `main` (ou em *Actions → Android APK → Run workflow*).
2. Ao terminar, baixe o artefato **dev-odyssey** e instale o `dev-odyssey.apk` no celular
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
  core/                         relógio, Google Agenda, tempo de Bauru, notificações, música e sons
  features/game/
    domain/                     regras puras, sem Flutter
      entities/                 Mission, GameState (serializável)
      catalog/                  categorias, destinos de cada semana, níveis e frases
      services/                 eventos do Google e .ics, regras e números derivados
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

Os pontos e o nível são sempre recalculados a partir das missões marcadas; o destino vem
das semanas em que a meta foi cumprida. O ícone é gerado em pixel art e fica em `android/app/src/main/res`.
