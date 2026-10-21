import '../entities/quest.dart';

typedef _Raw = ({
  String s,
  String e,
  String t,
  QuestCategory c,
  String? tag,
  SubquestKind? sub,
});

_Raw _q(String s, String e, String t, QuestCategory c,
        [String? tag, SubquestKind? sub]) =>
    (s: s, e: e, t: t, c: c, tag: tag, sub: sub);

const _cu = QuestCategory.cuidado;
const _es = QuestCategory.estudo;
const _tr = QuestCategory.trabalho;
const _fo = QuestCategory.treino;
const _ar = QuestCategory.arte;
const _fe = QuestCategory.fe;

List<_Raw> _duo(String s, String e) => [
      _q(s, e, 'Duolingo · Espanhol', _es, 'es'),
      _q(s, e, 'Duolingo · Inglês', _es, 'en'),
    ];

List<_Raw> _aula(String s, String e) => [
      _q(s, e, 'Aula de idioma · Espanhol', _es, 'es'),
      _q(s, e, 'Aula de idioma · Inglês', _es, 'en'),
    ];

_Raw _trab(String s, String e) =>
    _q(s, e, 'Trabalho + programação', _tr, 'dev', SubquestKind.courses);

List<_Raw> _manha() => [
      _q('05:30', '06:00', 'Banho', _cu, 'banho5'),
      _q('06:00', '06:30', 'Café', _cu),
      _q('06:30', '07:00', 'Leitura', _es, 'leitura'),
      _q('07:00', '08:00', 'Coddy', _es, 'codigo'),
    ];

/// Agenda "Rotina" do Google Agenda, em 20/10/2026.
final List<DaySchedule> weeklySchedule = _build();

final List<Quest> allQuests = [
  for (final day in weeklySchedule) ...day.quests,
];

final int weekMaxXp = allQuests.fold(0, (sum, q) => sum + q.xp);

List<DaySchedule> _build() {
  final raw = <(String, String, List<_Raw>)>[
    ('Segunda', 'SEG', [
      ..._manha(),
      _trab('08:00', '12:00'),
      _q('12:00', '13:30', 'Academia', _fo),
      _q('13:30', '14:00', 'Almoço', _cu),
      _trab('14:00', '17:00'),
      _q('17:00', '18:00', 'Pilates', _fo),
      _q('18:00', '18:30', 'Banho e lanche', _cu),
      _q('18:30', '19:30', 'Treino de piano', _ar, 'piano'),
      _q('19:30', '20:00', 'Jantar', _cu),
      ..._aula('20:00', '20:50'),
      ..._duo('21:00', '22:00'),
      _q('22:30', '23:00', 'Dormir 22h30', _cu, 'sono'),
    ]),
    ('Terça', 'TER', [
      ..._manha(),
      _trab('08:00', '12:00'),
      _q('12:00', '13:30', 'Treino de piano', _ar, 'piano'),
      _q('13:30', '14:00', 'Almoço', _cu),
      _trab('14:00', '17:00'),
      _q('17:00', '17:30', 'Lanche pré-treino', _cu),
      _q('17:30', '18:30', 'Futevôlei', _fo),
      _q('18:30', '19:00', 'Banho', _cu),
      ..._aula('19:00', '20:50'),
      ..._duo('21:00', '22:00'),
      _q('22:30', '23:00', 'Dormir 22h30', _cu, 'sono'),
    ]),
    ('Quarta', 'QUA', [
      ..._manha(),
      _trab('08:00', '12:00'),
      _q('12:00', '13:30', 'Academia', _fo),
      _q('13:30', '14:00', 'Almoço', _cu),
      _trab('14:00', '17:00'),
      _q('17:00', '18:00', 'Pilates', _fo),
      _q('18:00', '19:30', 'Treino de piano', _ar, 'piano'),
      _q('19:30', '20:00', 'Jantar', _cu),
      ..._aula('20:00', '20:50'),
      ..._duo('21:00', '22:00'),
      _q('22:30', '23:00', 'Dormir 22h30', _cu, 'sono'),
    ]),
    ('Quinta', 'QUI', [
      ..._manha(),
      _trab('08:00', '12:00'),
      _q('12:00', '13:00', 'Treino de piano', _ar, 'piano'),
      ..._duo('13:00', '13:30'),
      _q('13:30', '14:00', 'Almoço', _cu),
      _trab('14:00', '17:00'),
      _q('17:30', '18:30', 'Futevôlei', _fo),
      _q('18:30', '19:00', 'Banho e jantar', _cu),
      ..._aula('19:00', '20:50'),
      _q('21:30', '23:00', 'Futebol', _fo),
      _q('23:00', '23:45', 'Banho e dormir', _cu, 'sono'),
    ]),
    ('Sexta', 'SEX', [
      _q('05:30', '06:00', 'Banho', _cu, 'banho5'),
      _q('07:00', '07:30', 'Café', _cu),
      _q('07:30', '08:00', 'Leitura', _es, 'leitura'),
      _trab('08:00', '12:00'),
      _q('12:00', '13:30', 'Academia', _fo),
      _q('13:30', '14:00', 'Almoço', _cu),
      _trab('14:00', '17:00'),
      _q('17:00', '18:00', 'Treino de piano', _ar, 'piano'),
      _q('18:00', '19:00', 'Fotografia', _ar, 'foto'),
      _q('19:00', '20:00', 'Banho e jantar', _cu),
      ..._duo('20:00', '21:00'),
    ]),
    ('Sábado', 'SÁB', [
      _q('07:00', '07:30', 'Café', _cu),
      _q('07:30', '08:30', 'Leitura', _es, 'leitura'),
      _q('09:00', '09:30', 'Barba', _cu),
      _q('10:00', '12:00', 'Infra / self-hosting', _es, 'dev',
          SubquestKind.selfHosted),
      _q('12:00', '13:00', 'Almoço', _cu),
      _q('13:30', '14:30', 'Aula de piano', _ar, 'piano'),
      _q('14:30', '15:00', 'Descanso e lanche', _cu),
      ..._duo('15:00', '16:00'),
      _q('16:00', '18:00', 'Futsal', _fo),
      _q('18:00', '19:00', 'Banho e jantar', _cu),
    ]),
    ('Domingo', 'DOM', [
      _q('07:00', '07:30', 'Café', _cu),
      _q('12:00', '13:00', 'Mercado', _cu),
      _q('13:30', '14:00', 'Almoço', _cu),
      _q('14:00', '15:00', 'Estudo de investimentos', _es, 'invest'),
      _q('15:00', '16:30', 'Análise da carteira', _es, 'invest'),
      ..._duo('16:30', '17:30'),
      _q('17:30', '19:00', 'Missa', _fe, 'missa'),
      _q('19:30', '20:15', 'Jantar', _cu),
      _q('22:30', '23:00', 'Dormir 22h30', _cu, 'sono'),
    ]),
  ];

  return [
    for (var di = 0; di < raw.length; di++)
      DaySchedule(raw[di].$1, raw[di].$2, [
        for (var qi = 0; qi < raw[di].$3.length; qi++)
          Quest(
            id: '$di-$qi',
            dayIndex: di,
            start: raw[di].$3[qi].s,
            end: raw[di].$3[qi].e,
            title: raw[di].$3[qi].t,
            category: raw[di].$3[qi].c,
            tag: raw[di].$3[qi].tag,
            subquests: raw[di].$3[qi].sub,
          ),
      ]),
  ];
}
