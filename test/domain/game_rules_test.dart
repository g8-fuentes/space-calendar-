import 'package:flutter_test/flutter_test.dart';
import 'package:rotina_quest/core/time/week_utils.dart';
import 'package:rotina_quest/features/game/domain/catalog/catalog.dart';
import 'package:rotina_quest/features/game/domain/catalog/destinations.dart';
import 'package:rotina_quest/features/game/domain/catalog/schedule.dart';
import 'package:rotina_quest/features/game/domain/entities/game_state.dart';
import 'package:rotina_quest/features/game/domain/services/game_rules.dart';
import 'package:rotina_quest/features/game/domain/services/game_stats.dart';

void main() {
  final now = DateTime(2026, 10, 21, 12); // quarta-feira
  final week = weekKeyOf(now);
  GameState fresh() => GameState.initial(ymd(now));

  group('semana', () {
    test('segunda-feira é a chave da semana', () {
      expect(week, '2026-10-19');
      expect(dayIndexOf(now), 2);
    });

    test('marcar e desmarcar missão', () {
      final q = weeklySchedule[2].quests.first;
      var s = GameRules.toggleQuest(fresh(), q.id, week, 1);
      expect(s.week(week).done.containsKey(q.id), isTrue);
      expect(computeStats(s, now).xp, q.xp);
      s = GameRules.toggleQuest(s, q.id, week, 2);
      expect(s.week(week).done, isEmpty);
    });

    test('marcar até agora só pega missões já encerradas', () {
      final s = GameRules.markPastToday(fresh(), now);
      final done = s.week(week).done.keys.toSet();
      for (final q in weeklySchedule[2].quests) {
        expect(done.contains(q.id), q.endMinutes <= 12 * 60, reason: q.title);
      }
    });

    test('idiomas viram duas missões no mesmo horário', () {
      final duo = weeklySchedule[0].quests.where((q) => q.title.startsWith('Duolingo')).toList();
      expect(duo.map((q) => q.tag), ['es', 'en']);
      expect(duo.first.start, duo.last.start);
    });
  });

  group('baú', () {
    GameState completeWeek(GameState s, String key) {
      for (final q in allQuests) {
        s = GameRules.toggleQuest(s, q.id, key, 1);
      }
      return s;
    }

    test('não abre na semana atual sem 100%', () {
      final s = GameRules.openChest(fresh(), week, week);
      expect(s.week(week).chest, isNull);
    });

    test('100% abre ouro, derrota o chefe e dá item', () {
      final s = GameRules.openChest(completeWeek(fresh(), week), week, week);
      final chest = s.week(week).chest!;
      expect(chest.tier, 'ouro');
      expect(chest.bossDefeated, isTrue);
      expect(chest.item, isNotNull);
      expect(s.owned, contains(chest.item));
    });

    test('abrir duas vezes não duplica', () {
      final once = GameRules.openChest(completeWeek(fresh(), week), week, week);
      final twice = GameRules.openChest(once, week, week);
      expect(identical(once, twice), isTrue);
    });
  });

  group('cursos', () {
    test('aulas somam XP e o curso concluído dá bônus', () {
      var s = GameRules.setCourseTotal(fresh(), 'self', 2);
      s = GameRules.addLesson(s, 'self', now);
      s = GameRules.addLesson(s, 'self', now);
      expect(s.course('self').completed, isTrue);
      expect(computeStats(s, now).xp, 2 * lessonXp + courseXp);
      expect(GameRules.addLesson(s, 'self', now).lessons.length, 2);
    });

    test('desfazer aula remove a última', () {
      var s = GameRules.addLesson(fresh(), 'rocket', now);
      s = GameRules.removeLesson(s, 'rocket');
      expect(s.course('rocket').done, 0);
      expect(s.lessons, isEmpty);
    });
  });

  group('loja', () {
    test('não compra sem moedas', () {
      final s = GameRules.buyCosmetic(fresh(), cosmeticCatalog.first, 0, 1);
      expect(s.owned, isEmpty);
    });

    test('comprar equipa e desconta moedas', () {
      final c = cosmeticCatalog.first;
      final s = GameRules.buyCosmetic(fresh(), c, 1000, 1);
      expect(s.equipped[c.slot.name], c.id);
      expect(computeStats(s, now).coins, -c.price);
    });

    test('melhoria fica mais cara a cada nível', () {
      final u = upgradeCatalog.first;
      expect(u.costFor(1), greaterThan(u.costFor(0)));
      final s = GameRules.buyUpgrade(fresh(), u, 1 << 30, 1);
      expect(s.upgradeLevel(u.id), 1);
    });
  });

  group('progressão infinita', () {
    test('níveis não têm teto', () {
      expect(levelInfoFor(0).level, 1);
      expect(levelInfoFor(120).level, 2);
      expect(levelInfoFor(10000000).level, greaterThan(500));
    });

    test('ranks continuam depois de Almirante Galáctico', () {
      expect(rankAt(rankIndexFor(1)).name, 'Cadete Mirim');
      expect(rankAt(rankIndexFor(26)).name, 'Almirante Galáctico');
      expect(rankAt(rankIndexFor(34)).name, 'Almirante Galáctico II');
      expect(rankAt(rankIndexFor(200)).name, startsWith('Almirante Galáctico X'));
    });

    test('destinos crescem sem fim e em ordem', () {
      expect(destinationAt(0).name, 'Terra');
      expect(destinationAt(10).name, 'Proxima Centauri');
      for (var i = 0; i < 300; i++) {
        expect(destinationAt(i + 1).xpRequired, greaterThan(destinationAt(i).xpRequired));
      }
      expect(destinationAt(57).name, destinationAt(57).name);
      expect(destinationIndexFor(950), 2);
    });

    test('medalha dobra a meta a cada nível', () {
      expect(medalTierFor(10, 9).tier, 0);
      expect(medalTierFor(10, 10).tier, 1);
      expect(medalTierFor(10, 40).goal, 80);
    });
  });

  group('persistência', () {
    test('ida e volta em JSON preserva o estado', () {
      var s = GameRules.toggleQuest(fresh(), '0-0', week, 5);
      s = GameRules.addLesson(s, 'origamid', now);
      s = GameRules.buyCosmetic(s, cosmeticCatalog[1], 1000, 7);
      final back = GameState.fromJson(s.toJson(), today: ymd(now));
      expect(back.toJson(), s.toJson());
    });

    test('itens desconhecidos de versões antigas são descartados', () {
      final json = fresh().toJson()
        ..['owned'] = ['hachimaki', 'visor']
        ..['equipped'] = {'head': 'hachimaki', 'face': 'visor'};
      final back = GameState.fromJson(json, today: ymd(now));
      expect(back.owned, {'visor'});
      expect(back.equipped, {'face': 'visor'});
    });
  });
}
