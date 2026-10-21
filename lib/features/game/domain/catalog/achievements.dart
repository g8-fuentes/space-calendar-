import '../entities/game_state.dart';
import '../entities/quest.dart';
import '../services/game_stats.dart';
import 'catalog.dart';

typedef AchievementCheck = bool Function(GameStats t, GameState s, DateTime now);

class Achievement {
  const Achievement(this.name, this.description, this.glyph, this.color, this.check);
  final String name;
  final String description;
  final String glyph;
  final int color;
  final AchievementCheck check;
}

final achievements = <Achievement>[
  Achievement('Primeiro passo', 'Cumpra 1 missão', '1', 0xFF7FB4CA, (t, s, n) => t.questsDone >= 1),
  Achievement('Primeiro voo', 'Chegue à Lua', 'L', 0xFF938AA9, (t, s, n) => t.destinationIndex >= 1),
  Achievement('Marciano', 'Chegue a Marte', 'M', 0xFFE46876, (t, s, n) => t.destinationIndex >= 2),
  Achievement('Gigante gasoso', 'Chegue a Júpiter', 'J', 0xFFC0A36E, (t, s, n) => t.destinationIndex >= 4),
  Achievement('Senhor dos anéis', 'Chegue a Saturno', 'S', 0xFFE6C384, (t, s, n) => t.destinationIndex >= 5),
  Achievement('Fronteira', 'Chegue a Plutão', 'P', 0xFFC8C093, (t, s, n) => t.destinationIndex >= 8),
  Achievement('Interestelar', 'Chegue a Proxima Centauri', '*', 0xFFE46876, (t, s, n) => t.destinationIndex >= 10),
  Achievement('Madrugador', '10 banhos às 5h30', '5h', 0xFFD27E99, (t, s, n) => t.tag('banho5') >= 10),
  Achievement('Corpo de aço', '20 treinos de Força', 'F', 0xFFC34043,
      (t, s, n) => (t.byCategory[QuestCategory.treino] ?? 0) >= 20),
  Achievement('Hablo español', '7 dias seguidos de Espanhol', 'ES', 0xFFC34043,
      (t, s, n) => languageStreak(s, 'es', n) >= 7),
  Achievement('I speak English', '7 dias seguidos de Inglês', 'EN', 0xFF7FB4CA,
      (t, s, n) => languageStreak(s, 'en', n) >= 7),
  Achievement('Caçador de chefões', 'Conclua 1 curso', '</>', 0xFFE6C384, (t, s, n) => t.coursesDone >= 1),
  Achievement('Semana de Ouro', 'Feche uma semana com 100%', '100', 0xFFE6C384, (t, s, n) => t.goldWeeks >= 1),
  Achievement('Imparável', '4 semanas seguidas com 60%+', '4x', 0xFFC34043, (t, s, n) => weekStreak(s, n) >= 4),
  Achievement('Modo Supernova', 'Libere o último modo do traje', 'oo', 0xFFE6C384,
      (t, s, n) => t.modeUnlocked(suitModes.last)),
];

class Medal {
  const Medal(this.name, this.color, this.base, this.value);
  final String name;
  final int color;
  final int base;
  final int Function(GameStats t, GameState s) value;
}

final medals = <Medal>[
  Medal('Missões cumpridas', 0xFF98BB6C, 10, (t, s) => t.questsDone),
  Medal('Aulas de cursos', 0xFF7FB4CA, 5, (t, s) => s.lessons.length),
  Medal('XP total', 0xFF957FB8, 1000, (t, s) => t.xp),
  Medal('Destinos alcançados', 0xFFE6C384, 2, (t, s) => t.destinationIndex),
  Medal('Semanas com 60%+', 0xFFFFA066, 2, (t, s) => t.goodWeeks),
  Medal('Missões de idiomas', 0xFFE46876, 10, (t, s) => t.tag('es') + t.tag('en')),
];
