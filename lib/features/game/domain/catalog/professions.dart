/// Profissões: cada uma tem um personagem, níveis com nomes próprios, frases
/// e uma jornada (mapa) diferente. O astronauta explora o espaço; as outras
/// profissões rodam Bauru, o Brasil e o mundo.
library;

/// Monumento ou prédio desenhado no horizonte de um lugar na Terra.
enum Landmark {
  none,
  christ,
  cityTower,
  needle,
  ironTower,
  clockTower,
  coliseum,
  pyramids,
  onionDome,
  pagoda,
  dome,
  opera,
  obelisk,
  gym,
  hospital,
  school,
  techTower,
  restaurant,
  stage,
  fireStation,
  stadium,
  trees,
  mountain,
}

/// Como o personagem é desenhado.
enum Outfit { astronaut, trainer, doctor, teacher, coder, chef, musician, firefighter }

/// Frase de inspiração de um nível.
typedef Quote = ({String text, String author});

/// Um lugar da jornada na Terra: nome, monumento e curiosidade.
typedef EarthStop = (String name, Landmark landmark, String fact);

class Profession {
  const Profession({
    required this.key,
    required this.name,
    required this.emoji,
    required this.outfit,
    required this.pitch,
    required this.levelNames,
    required this.items,
    required this.quotes,
    required this.suit,
    required this.trim,
    required this.low,
    this.stages = const [],
    this.event = '',
  });

  final String key;

  /// Nome mostrado na escolha da profissão.
  final String name;

  /// Emoji das notificações.
  final String emoji;
  final Outfit outfit;

  /// Uma linha sobre a jornada da profissão.
  final String pitch;

  /// Nomes dos 16 níveis com nome; o último se repete com número, sem fim.
  final List<String> levelNames;

  /// Descrição da roupa no nível 1, do acessório no nível 2 e do acessório
  /// completo no nível 5.
  final (String base, String pack, String full) items;
  final List<Quote> quotes;

  /// Cores da roupa: principal, detalhe e calça.
  final int suit, trim, low;

  /// Fases da jornada na Terra (vazio no astronauta, que vai para o espaço).
  final List<(String region, List<EarthStop> stops)> stages;

  /// Evento das paradas geradas depois das conhecidas ("Show em Lisboa").
  final String event;

  bool get space => outfit == Outfit.astronaut;

  /// Como a semana termina: quem parte para o próximo destino.
  String get travel => space ? 'a nave parte' : 'você parte';
}

const astronaut = Profession(
  key: 'astronauta',
  name: 'Astronauta',
  emoji: '🚀',
  outfit: Outfit.astronaut,
  pitch: 'Sai da Terra rumo aos planetas, às estrelas e às galáxias.',
  levelNames: [],
  items: ('', '', ''),
  quotes: [],
  suit: 0xFFE4DFC6,
  trim: 0xFFFFA066,
  low: 0xFF223249,
);

const professions = <Profession>[
  astronaut,
  Profession(
    key: 'personal',
    name: 'Personal trainer',
    emoji: '🏋️',
    outfit: Outfit.trainer,
    pitch: 'Da academia do bairro às maratonas e Olimpíadas.',
    levelNames: [
      'Aluno da academia',
      'Estagiário de educação física',
      'Personal trainer',
      'Personal de confiança',
      'Preparador físico',
      'Treinador de atletas',
      'Treinador de campeões',
      'Técnico da seleção',
      'Treinador olímpico',
      'Lenda da musculação',
      'Mestre do condicionamento',
      'Titã da força',
      'Senhor da resistência',
      'Fera indomável',
      'Lenda do esporte',
      'Treinador cósmico',
    ],
    items: ('Regata, tênis e faixa na testa.', 'Apito no peito: agora é você quem dá o treino.', 'Kettlebell na mão.'),
    quotes: [
      (text: 'Mente sã, corpo são.', author: 'Juvenal'),
      (text: 'Mais rápido, mais alto, mais forte.', author: 'lema olímpico'),
      (
        text: 'Odiei cada minuto de treino, mas pensei: não desista. Sofra agora e viva o resto da vida como campeão.',
        author: 'Muhammad Ali'
      ),
      (text: 'Campeões continuam jogando até acertar.', author: 'Billie Jean King'),
      (text: 'Você erra 100% dos chutes que não dá.', author: 'Wayne Gretzky'),
      (text: 'Treino difícil, batalha fácil.', author: 'Alexander Suvorov'),
      (text: 'O importante não é vencer, mas competir.', author: 'Pierre de Coubertin'),
      (text: 'Não existe atalho para nenhum lugar que valha a pena ir.', author: 'Beverly Sills'),
    ],
    suit: 0xFF98BB6C,
    trim: 0xFFFFA066,
    low: 0xFF223249,
    event: 'Campeonato',
    stages: [
      (
        'Início da carreira',
        [
          (
            'Academia do bairro',
            Landmark.gym,
            'Em Bauru, onde tudo começa: o primeiro aluno e a primeira ficha de treino.'
          ),
          ('Parque Vitória Régia', Landmark.trees, 'Treino ao ar livre no parque mais famoso de Bauru.'),
        ]
      ),
      (
        'Competições no Brasil',
        [
          ('Estádio do Pacaembu', Landmark.stadium, 'Em São Paulo, inaugurado em 1940 e palco de grandes jogos.'),
          ('Calçadão de Copacabana', Landmark.christ, 'No Rio, o calçadão de ondas tem cerca de 4 km para correr.'),
          ('Serra da Mantiqueira', Landmark.mountain, 'Trilhas e subidas que treinam o fôlego de qualquer atleta.'),
        ]
      ),
      (
        'Circuito mundial',
        [
          ('Maratona de Buenos Aires', Landmark.obelisk, 'A largada passa perto do Obelisco, símbolo da cidade.'),
          ('Maratona de Nova York', Landmark.cityTower, 'A maior maratona do mundo, passando pelos cinco distritos.'),
          ('Tour de France', Landmark.ironTower, 'A prova de ciclismo mais famosa termina em Paris desde 1975.'),
          ('Coliseu', Landmark.coliseum, 'Em Roma, onde os gladiadores lutavam diante de até 50 mil pessoas.'),
          ('Olimpíadas de Tóquio', Landmark.pagoda, 'Tóquio recebeu os Jogos Olímpicos em 1964 e em 2021.'),
          ('Corrida das Pirâmides', Landmark.pyramids, 'Correr no deserto de Gizé, ao lado das pirâmides.'),
          ('Monte Everest', Landmark.mountain, 'Com 8.849 m, o ponto mais alto da Terra.'),
        ]
      ),
    ],
  ),
  Profession(
    key: 'medico',
    name: 'Médico(a)',
    emoji: '🩺',
    outfit: Outfit.doctor,
    pitch: 'Do posto de saúde aos grandes centros de medicina do mundo.',
    levelNames: [
      'Estudante de medicina',
      'Interno',
      'Residente',
      'Clínico geral',
      'Especialista',
      'Chefe de plantão',
      'Cirurgião',
      'Diretor do hospital',
      'Pesquisador',
      'Médico sem fronteiras',
      'Mestre da medicina',
      'Descobridor de curas',
      'Lenda da saúde',
      'Guardião da vida',
      'Prêmio Nobel de Medicina',
      'Médico cósmico',
    ],
    items: ('Jaleco branco e a primeira consulta.', 'Estetoscópio no pescoço.', 'Prancheta na mão.'),
    quotes: [
      (text: 'Primeiro, não causar dano.', author: 'princípio da medicina'),
      (text: 'Onde há amor pela medicina, há amor pela humanidade.', author: 'Hipócrates'),
      (text: 'A sorte favorece a mente preparada.', author: 'Louis Pasteur'),
      (
        text: 'O bom médico trata a doença; o grande médico trata o paciente que tem a doença.',
        author: 'William Osler'
      ),
      (text: 'Escute o paciente: ele está dizendo o diagnóstico.', author: 'William Osler'),
      (text: 'Nada na vida deve ser temido, apenas compreendido.', author: 'Marie Curie'),
      (text: 'Quem salva uma vida salva o mundo inteiro.', author: 'Talmude'),
      (text: 'Que o teu alimento seja o teu remédio.', author: 'atribuída a Hipócrates'),
    ],
    suit: 0xFFE4DFC6,
    trim: 0xFF6A9589,
    low: 0xFF6A9589,
    event: 'Congresso',
    stages: [
      (
        'Residência',
        [
          ('Posto de saúde', Landmark.hospital, 'Em Bauru: a primeira consulta, o primeiro paciente.'),
          (
            'Hospital das Clínicas',
            Landmark.hospital,
            'Em São Paulo, um dos maiores complexos hospitalares da América Latina.'
          ),
        ]
      ),
      (
        'Medicina no Brasil',
        [
          ('Instituto Butantan', Landmark.trees, 'Em São Paulo, produz vacinas e soros desde 1901.'),
          ('Fiocruz', Landmark.dome, 'No Rio, com o castelo mourisco onde trabalhou Oswaldo Cruz.'),
          ('Amazônia', Landmark.trees, 'Barcos-hospital levam médicos às comunidades ribeirinhas.'),
        ]
      ),
      (
        'Medicina pelo mundo',
        [
          ('Instituto Pasteur', Landmark.ironTower, 'Em Paris, fundado por Louis Pasteur em 1887.'),
          ('Londres', Landmark.clockTower, 'Onde Alexander Fleming descobriu a penicilina, em 1928.'),
          (
            'Roma',
            Landmark.coliseum,
            'Onde viveu Galeno, médico que estudou o corpo humano por séculos de influência.'
          ),
          ('Grécia', Landmark.dome, 'Terra de Hipócrates, chamado de pai da medicina.'),
          ('Egito', Landmark.pyramids, 'Os egípcios já tratavam feridas com mel há mais de 4 mil anos.'),
          ('Tóquio', Landmark.pagoda, 'O Japão tem uma das maiores expectativas de vida do mundo.'),
          ('Genebra', Landmark.cityTower, 'Sede da Organização Mundial da Saúde.'),
        ]
      ),
    ],
  ),
  Profession(
    key: 'professor',
    name: 'Professor(a)',
    emoji: '📚',
    outfit: Outfit.teacher,
    pitch: 'Da escola do bairro às universidades mais antigas do mundo.',
    levelNames: [
      'Estudante de licenciatura',
      'Professor estagiário',
      'Professor',
      'Professor querido',
      'Coordenador',
      'Mestre',
      'Doutor',
      'Professor titular',
      'Reitor',
      'Sábio da cidade',
      'Mestre dos mestres',
      'Guardião do saber',
      'Filósofo',
      'Lenda da educação',
      'Patrono do ensino',
      'Professor cósmico',
    ],
    items: ('Suéter e camisa com gola.', 'Óculos e um livro na mão.', 'Capelo de formatura na cabeça.'),
    quotes: [
      (text: 'A educação é a arma mais poderosa que você pode usar para mudar o mundo.', author: 'Nelson Mandela'),
      (
        text: 'Ensinar não é transferir conhecimento, mas criar as possibilidades para a sua produção.',
        author: 'Paulo Freire'
      ),
      (text: 'Uma criança, um professor, um livro e uma caneta podem mudar o mundo.', author: 'Malala Yousafzai'),
      (text: 'Só sei que nada sei.', author: 'Sócrates'),
      (text: 'Se vi mais longe, foi por estar sobre ombros de gigantes.', author: 'Isaac Newton'),
      (text: 'A raiz da educação é amarga, mas o fruto é doce.', author: 'atribuída a Aristóteles'),
      (
        text: 'Me diga e eu esqueço. Me ensine e eu lembro. Me envolva e eu aprendo.',
        author: 'atribuída a Benjamin Franklin'
      ),
      (text: 'Ninguém ignora tudo. Ninguém sabe tudo.', author: 'Paulo Freire'),
    ],
    suit: 0xFFC0A36E,
    trim: 0xFFDCD7BA,
    low: 0xFF54546D,
    event: 'Palestra',
    stages: [
      (
        'Sala de aula',
        [
          ('Escola do bairro', Landmark.school, 'Em Bauru: a primeira turma e o primeiro giz.'),
          ('Unesp Bauru', Landmark.school, 'O campus da Unesp em Bauru forma professores e engenheiros.'),
        ]
      ),
      (
        'Universidades do Brasil',
        [
          ('USP', Landmark.clockTower, 'Em São Paulo; a Torre do Relógio é o símbolo da Cidade Universitária.'),
          ('Biblioteca Nacional', Landmark.dome, 'No Rio, uma das maiores bibliotecas do mundo.'),
          ('Unicamp', Landmark.school, 'Em Campinas, fundada em 1966.'),
        ]
      ),
      (
        'Grandes escolas do mundo',
        [
          ('Coimbra', Landmark.clockTower, 'Universidade fundada em 1290, uma das mais antigas do mundo.'),
          ('Bolonha', Landmark.dome, 'A universidade mais antiga do Ocidente em funcionamento, de 1088.'),
          ('Oxford', Landmark.clockTower, 'Há registros de aulas em Oxford desde 1096.'),
          ('Sorbonne', Landmark.ironTower, 'Em Paris, fundada no século 13.'),
          ('Academia de Platão', Landmark.dome, 'Em Atenas, Platão fundou sua escola por volta de 387 a.C.'),
          ('Alexandria', Landmark.pyramids, 'A biblioteca de Alexandria reuniu o saber do mundo antigo.'),
          ('Harvard', Landmark.cityTower, 'A universidade mais antiga dos Estados Unidos, de 1636.'),
        ]
      ),
    ],
  ),
  Profession(
    key: 'programador',
    name: 'Programador(a)',
    emoji: '💻',
    outfit: Outfit.coder,
    pitch: 'Do home office aos grandes polos de tecnologia do mundo.',
    levelNames: [
      'Estagiário',
      'Dev júnior',
      'Dev pleno',
      'Dev sênior',
      'Tech lead',
      'Arquiteto de software',
      'Staff engineer',
      'CTO',
      'Fundador de startup',
      'Hacker lendário',
      'Mestre dos algoritmos',
      'Arquiteto das nuvens',
      'Senhor dos bits',
      'Domador de bugs',
      'Lenda do open source',
      'Programador cósmico',
    ],
    items: ('Moletom com capuz.', 'Fones de ouvido para o foco total.', 'Notebook aberto com código brilhando.'),
    quotes: [
      (text: 'Falar é fácil. Mostre-me o código.', author: 'Linus Torvalds'),
      (text: 'Primeiro resolva o problema. Depois escreva o código.', author: 'John Johnson'),
      (
        text:
            'Qualquer um escreve código que um computador entende. Bons programadores escrevem código que pessoas entendem.',
        author: 'Martin Fowler'
      ),
      (text: 'Simplicidade é pré-requisito para confiabilidade.', author: 'Edsger Dijkstra'),
      (text: 'A melhor forma de prever o futuro é inventá-lo.', author: 'Alan Kay'),
      (text: 'Otimização prematura é a raiz de todo mal.', author: 'Donald Knuth'),
      (
        text: 'Só podemos ver um pouco do futuro, mas o suficiente para perceber que há muito a fazer.',
        author: 'Alan Turing'
      ),
      (text: 'É mais fácil pedir desculpas do que pedir permissão.', author: 'Grace Hopper'),
    ],
    suit: 0xFF54546D,
    trim: 0xFF98BB6C,
    low: 0xFF223249,
    event: 'Hackathon',
    stages: [
      (
        'Primeiros códigos',
        [
          ('Home office', Landmark.techTower, 'Em Bauru: o primeiro "Olá, mundo!" na tela.'),
          ('Avenida Paulista', Landmark.cityTower, 'Em São Paulo, a maior concentração de startups do Brasil.'),
        ]
      ),
      (
        'Tecnologia no Brasil',
        [
          ('Porto Digital', Landmark.techTower, 'No Recife Antigo, um dos maiores parques tecnológicos do país.'),
          ('Florianópolis', Landmark.trees, 'A "Ilha do Silício", cheia de empresas de tecnologia.'),
          ('Campinas', Landmark.school, 'Polo de pesquisa e tecnologia no interior de São Paulo.'),
        ]
      ),
      (
        'Polos de tecnologia',
        [
          ('Vale do Silício', Landmark.techTower, 'HP, Apple e Google começaram em garagens por aqui.'),
          ('Seattle', Landmark.needle, 'Ao lado da Space Needle, perto de onde nasceram Microsoft e Amazon.'),
          ('Inglaterra', Landmark.clockTower, 'Em Bletchley Park, Alan Turing ajudou a quebrar o código Enigma.'),
          ('Helsinque', Landmark.onionDome, 'Onde Linus Torvalds começou a criar o Linux, em 1991.'),
          ('Bangalore', Landmark.dome, 'Conhecida como o Vale do Silício da Índia.'),
          ('Shenzhen', Landmark.cityTower, 'Passou de vila de pescadores a metrópole da tecnologia em 40 anos.'),
          ('Akihabara', Landmark.pagoda, 'O bairro da eletrônica e dos games em Tóquio.'),
        ]
      ),
    ],
  ),
  Profession(
    key: 'chef',
    name: 'Chef de cozinha',
    emoji: '🍳',
    outfit: Outfit.chef,
    pitch: 'Da cozinha de casa aos sabores do Brasil e do mundo.',
    levelNames: [
      'Ajudante de cozinha',
      'Cozinheiro',
      'Chef de partida',
      'Subchef',
      'Chef de cozinha',
      'Chef executivo',
      'Chef estrelado',
      'Chef duas estrelas',
      'Chef três estrelas',
      'Mestre dos sabores',
      'Lenda da gastronomia',
      'Senhor das especiarias',
      'Alquimista do sabor',
      'Guardião das receitas',
      'Chef do mundo',
      'Chef cósmico',
    ],
    items: ('Dólmã branca e bandana.', 'O chapéu alto de chef.', 'Frigideira na mão.'),
    quotes: [
      (text: 'Diga-me o que comes e te direi quem és.', author: 'Brillat-Savarin'),
      (
        text: 'A descoberta de um prato novo faz mais pela felicidade humana que a descoberta de uma estrela.',
        author: 'Brillat-Savarin'
      ),
      (text: 'Cozinhar é como amar: entre de cabeça ou não entre.', author: 'Harriet Van Horne'),
      (text: 'O único obstáculo de verdade na cozinha é o medo de errar.', author: 'Julia Child'),
      (text: 'A comida é tudo o que somos.', author: 'Anthony Bourdain'),
      (text: 'Uma receita não tem alma. É o cozinheiro quem traz a alma para a receita.', author: 'Thomas Keller'),
      (text: 'A fome é o melhor tempero.', author: 'ditado popular'),
      (text: 'Quem cozinha com amor alimenta a alma.', author: 'ditado popular'),
    ],
    suit: 0xFFE4DFC6,
    trim: 0xFFC34043,
    low: 0xFF363646,
    event: 'Festival gastronômico',
    stages: [
      (
        'Cozinha de casa',
        [
          (
            'Cozinha em Bauru',
            Landmark.restaurant,
            'Bauru dá nome ao sanduíche criado em 1934 por um estudante bauruense.'
          ),
          ('Mercadão de São Paulo', Landmark.restaurant, 'Famoso pelo sanduíche de mortadela gigante.'),
        ]
      ),
      (
        'Sabores do Brasil',
        [
          ('Ver-o-Peso', Landmark.restaurant, 'Em Belém, um dos mercados mais antigos do Brasil, com açaí e tucupi.'),
          ('Salvador', Landmark.dome, 'O ofício das baianas de acarajé é patrimônio do Brasil.'),
          ('Minas Gerais', Landmark.mountain, 'Terra do pão de queijo e do queijo canastra.'),
        ]
      ),
      (
        'Volta ao mundo',
        [
          ('Paris', Landmark.ironTower, 'A refeição gastronômica francesa é patrimônio da UNESCO desde 2010.'),
          ('Itália', Landmark.coliseum, 'Diz a história que a pizza margherita nasceu em Nápoles, em 1889.'),
          ('Lima', Landmark.mountain, 'A capital do Peru é famosa pelo ceviche.'),
          ('Cidade do México', Landmark.pyramids, 'O chocolate e o milho vêm das cozinhas do México antigo.'),
          ('Istambul', Landmark.dome, 'Entre a Europa e a Ásia, cheia de mercados de especiarias.'),
          ('Índia', Landmark.dome, 'Terra da pimenta-do-reino, do cardamomo e do curry.'),
          ('Tóquio', Landmark.pagoda, 'A cidade com mais restaurantes estrelados do mundo.'),
        ]
      ),
    ],
  ),
  Profession(
    key: 'musico',
    name: 'Músico(a)',
    emoji: '🎸',
    outfit: Outfit.musician,
    pitch: 'Da garagem aos grandes palcos do Brasil e do mundo.',
    levelNames: [
      'Aprendiz de música',
      'Músico de garagem',
      'Músico da noite',
      'Instrumentista',
      'Músico de estúdio',
      'Líder da banda',
      'Artista em turnê',
      'Atração do festival',
      'Estrela da música',
      'Disco de ouro',
      'Disco de platina',
      'Lenda do palco',
      'Mestre da harmonia',
      'Senhor do som',
      'Ícone da música',
      'Músico cósmico',
    ],
    items: ('Camiseta preta e calça jeans.', 'Violão a tiracolo.', 'Óculos escuros de estrela.'),
    quotes: [
      (text: 'Sem música, a vida seria um erro.', author: 'Friedrich Nietzsche'),
      (text: 'A música expressa o que não pode ser dito.', author: 'Victor Hugo'),
      (text: 'Onde as palavras falham, a música fala.', author: 'Hans Christian Andersen'),
      (text: 'Não tenha medo de errar. Os erros não existem.', author: 'Miles Davis'),
      (text: 'É impossível ser feliz sozinho.', author: 'Tom Jobim'),
      (text: 'Tudo o que você precisa é amor.', author: 'The Beatles'),
      (text: 'Tocar uma nota errada é bobagem; tocar sem paixão é imperdoável.', author: 'atribuída a Beethoven'),
      (text: 'Quem canta seus males espanta.', author: 'ditado popular'),
    ],
    suit: 0xFF363646,
    trim: 0xFFE46876,
    low: 0xFF2D4F67,
    event: 'Show',
    stages: [
      (
        'Primeiros acordes',
        [
          ('Garagem em Bauru', Landmark.stage, 'O primeiro ensaio, com amplificador emprestado.'),
          ('Teatro Municipal', Landmark.opera, 'Em São Paulo, inaugurado em 1911.'),
        ]
      ),
      (
        'Palcos do Brasil',
        [
          ('Rio de Janeiro', Landmark.christ, 'A bossa nova nasceu em Copacabana e Ipanema no fim dos anos 1950.'),
          ('Pelourinho', Landmark.stage, 'Em Salvador, ao som dos tambores do Olodum.'),
          ('Recife', Landmark.stage, 'Berço do frevo, patrimônio da humanidade pela UNESCO.'),
        ]
      ),
      (
        'Turnê mundial',
        [
          ('Nova Orleans', Landmark.stage, 'A cidade onde nasceu o jazz.'),
          ('Liverpool', Landmark.clockTower, 'A cidade dos Beatles.'),
          ('Viena', Landmark.dome, 'Mozart, Haydn e Beethoven trabalharam aqui.'),
          ('Buenos Aires', Landmark.obelisk, 'A terra do tango.'),
          ('Seul', Landmark.cityTower, 'A capital do K-pop.'),
          ('Ópera de Sydney', Landmark.opera, 'Um dos palcos mais famosos do mundo, aberto em 1973.'),
          ('Estádio de Wembley', Landmark.stadium, 'Em Londres, palco do Live Aid em 1985.'),
        ]
      ),
    ],
  ),
  Profession(
    key: 'bombeiro',
    name: 'Bombeiro(a)',
    emoji: '🚒',
    outfit: Outfit.firefighter,
    pitch: 'Do quartel de Bauru aos grandes resgates pelo mundo.',
    levelNames: [
      'Recruta',
      'Soldado bombeiro',
      'Bombeiro',
      'Cabo',
      'Sargento',
      'Tenente',
      'Capitão',
      'Major',
      'Comandante do quartel',
      'Herói do resgate',
      'Mestre do fogo',
      'Escudo da cidade',
      'Guardião das florestas',
      'Senhor das chamas',
      'Lenda do resgate',
      'Bombeiro cósmico',
    ],
    items: ('Farda de proteção e capacete vermelho.', 'Cilindro de ar nas costas.', 'Machado de resgate na mão.'),
    quotes: [
      (text: 'Vida alheia e riquezas salvar.', author: 'lema dos bombeiros'),
      (text: 'Coragem não é a ausência do medo, mas o triunfo sobre ele.', author: 'Nelson Mandela'),
      (
        text: 'A coragem é a primeira das qualidades humanas, porque garante todas as outras.',
        author: 'atribuída a Aristóteles'
      ),
      (text: 'O crédito pertence a quem está de fato na arena.', author: 'Theodore Roosevelt'),
      (text: 'Prevenir é melhor do que remediar.', author: 'ditado popular'),
      (text: 'Seja a mudança que você quer ver no mundo.', author: 'atribuída a Gandhi'),
      (text: 'Uma corrente é tão forte quanto o seu elo mais fraco.', author: 'ditado popular'),
      (text: 'Fracassar não é uma opção.', author: 'Gene Kranz'),
    ],
    suit: 0xFFC0A36E,
    trim: 0xFFE6C384,
    low: 0xFFC0A36E,
    event: 'Missão de resgate',
    stages: [
      (
        'Quartel',
        [
          ('Quartel de Bauru', Landmark.fireStation, 'O primeiro plantão e o primeiro alarme.'),
          ('São Paulo', Landmark.cityTower, 'O Corpo de Bombeiros de São Paulo foi criado em 1880.'),
        ]
      ),
      (
        'Brasil',
        [
          (
            'Rio de Janeiro',
            Landmark.christ,
            'Aqui Dom Pedro II criou o primeiro corpo de bombeiros do Brasil, em 1856.'
          ),
          ('Serra do Mar', Landmark.mountain, 'Resgate em montanha exige cordas e muito preparo.'),
          ('Pantanal', Landmark.trees, 'A maior planície alagada do mundo.'),
          ('Amazônia', Landmark.trees, 'A maior floresta tropical do planeta.'),
        ]
      ),
      (
        'Resgates pelo mundo',
        [
          (
            'Roma',
            Landmark.coliseum,
            'Os vigiles, criados pelo imperador Augusto, combatiam incêndios na Roma antiga.'
          ),
          ('Londres', Landmark.clockTower, 'O Grande Incêndio de 1666 mudou o jeito de construir cidades.'),
          ('Nova York', Landmark.cityTower, 'O FDNY é um dos maiores corpos de bombeiros do mundo.'),
          ('Paris', Landmark.ironTower, 'Os bombeiros de Paris são uma brigada militar.'),
          ('Tóquio', Landmark.pagoda, 'Cidade preparada para terremotos como poucas no mundo.'),
          ('Monte Everest', Landmark.mountain, 'Com 8.849 m, o ponto mais alto da Terra.'),
        ]
      ),
    ],
  ),
];

Profession professionOf(String key) => professions.firstWhere((p) => p.key == key, orElse: () => astronaut);
