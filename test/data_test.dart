// Veri ve mantık testleri: `flutter test test/data_test.dart`
import 'dart:io';

import 'package:duybeni/data.dart';
import 'package:duybeni/game_state.dart';
import 'package:duybeni/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    PackData.loader = (asset) async => File(asset).readAsStringSync();
  });

  group('paket verisi', () {
    for (final p in packs) {
      test('${p.name}: zorluk listeleri tutarlı', () async {
        final dict = await PackData.dict(p);
        final lists = await PackData.levelLists(p);
        final all = <String>[];
        for (final lv in levels) {
          final list = lists[lv] ?? const <String>[];
          expect(list, isNotEmpty, reason: "'$lv' listesi boş");
          for (final w in list) {
            all.add(w);
            expect(dict.words.containsKey(w), isTrue, reason: "'$w' sözlükte yok");
            expect(dict.words[w]!.trim(), isNotEmpty, reason: "'$w' anlamı boş");
          }
        }
        expect(all.toSet().length, all.length, reason: 'zorluk listelerinde tekrar eden kelime var');
      });
    }
  });

  group('arama', () {
    test('Türkçe i/ı büyük-küçük harf duyarsız', () {
      expect(fold('ISIRGAN', 'TR'), 'ısırgan');
      expect(fold('İZMİR', 'TR'), 'izmir');
      expect(fold('  Island ', 'EN'), 'island');
    });

    test('anlam bulunur, bulunamayan null döner', () async {
      final lists = await PackData.levelLists(packs[0]);
      final word = lists['ORTA']!.first;
      final upper = await PackData.lookup(packs[0], word.toUpperCase());
      expect(upper, isNotNull);
      expect(upper!.$2, isNotEmpty);
      expect(await PackData.lookup(packs[0], 'zzzqqqxxx'), isNull);
      expect(await PackData.lookup(packs[0], '   '), isNull);
    });

    test('aynı dildeki diğer paketlerde de aranır', () async {
      // Gamer paketinin kelimesi Türkçe ana sözlükte olmasa bile "gamer" paketinden aranırsa bulunur.
      final gamer = packs.firstWhere((p) => p.id == 'gamer');
      final lists = await PackData.levelLists(gamer);
      final word = lists['KOLAY']!.first;
      expect(await PackData.lookup(packs[0], word), isNotNull);
    });
  });

  group('kelime destesi', () {
    test('300 çekilişte tekrar yok', () async {
      final p = packs.firstWhere((p) => p.id == 'en');
      final lists = await PackData.levelLists(p);
      final deck = Deck();
      final seen = <String>{};
      for (var i = 0; i < 300; i++) {
        final w = deck.next(p, lists, 'ORTA');
        expect(w, isNotNull);
        expect(seen.add(w!), isTrue, reason: "'$w' tekrar etti");
      }
    });

    test('seçili düzey bitince yakın düzeyden verir, paket bitince baştan başlar', () {
      const p = Pack('x', 'X', 'TR');
      final lists = {
        'KOLAY': ['a', 'b'],
        'ORTA': <String>[],
        'ZOR': ['c'],
      };
      final deck = Deck();
      final got = [for (var i = 0; i < 3; i++) deck.next(p, lists, 'KOLAY')!];
      expect(got.toSet(), {'a', 'b', 'c'});
      // Hepsi kullanıldı: bir sonraki çekiliş baştan başlar ve yine kelime verir.
      expect(deck.next(p, lists, 'KOLAY'), isNotNull);
    });

    test('boş paket null döner, çökmez', () {
      expect(Deck().next(const Pack('x', 'X', 'TR'), {}, 'ORTA'), isNull);
    });
  });

  group('maç', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Game.instance.init();
      Game.instance.teams = 2;
      Game.instance.startSeries();
    });

    test('en çok doğru kazanır, eşitlikte az pas, tam eşitlik berabere', () {
      final g = Game.instance;
      g.results = {1: const TeamResult(5, 2), 2: const TeamResult(7, 9)};
      expect(g.winners(), [2]);
      g.results = {1: const TeamResult(5, 2), 2: const TeamResult(5, 1)};
      expect(g.winners(), [2]);
      g.results = {1: const TeamResult(5, 2), 2: const TeamResult(5, 2)};
      expect(g.winners(), [1, 2]);
    });

    test('sıradaki takım yalnız maç sürerken var', () {
      final g = Game.instance;
      expect(g.hasNextTeam, isTrue);
      g.currentTeam = 2;
      expect(g.hasNextTeam, isFalse);
      g.currentTeam = 1;
      g.running = false;
      expect(g.hasNextTeam, isFalse);
    });

    test('ayarlar ve geçmiş diske yazılıp geri okunur', () async {
      final g = Game.instance;
      g.setPack(2);
      g.cycleDuration();
      g.cycleLevel();
      g.cycleTeams();
      g.lastCorrect = 6;
      g.lastPass = 1;
      g.recordRound();

      // "Uygulama yeniden açıldı": durumu sıfırlayıp aynı depodan okut.
      final prefs = await SharedPreferences.getInstance();
      g.packIndex = 0;
      g.results = {};
      await g.init(prefs: prefs);
      expect(g.packIndex, 2);
      expect(g.duration, 90);
      expect(g.level, 'ZOR');
      expect(g.teams, 3);
      expect(g.results[1]!.correct, 6);
      expect(g.results[1]!.pass, 1);
    });

    test('bozuk kayıt çökertmez', () async {
      SharedPreferences.setMockInitialValues({'history': 'bozuk{', 'pack': 99, 'duration': 7, 'teams': 40});
      final g = Game.instance;
      await g.init();
      expect(g.results, isEmpty);
      expect(g.packIndex, packs.length - 1);
      expect(Game.durations, contains(g.duration));
      expect(g.teams, Game.maxTeams);
    });

    test('döngüler başa sarar', () {
      final g = Game.instance;
      g.duration = 120;
      g.cycleDuration();
      expect(g.duration, 30);
      g.teams = 4;
      g.cycleTeams();
      expect(g.teams, 1);
      g.level = 'ZOR';
      g.cycleLevel();
      expect(g.level, 'KOLAY');
    });
  });

  group('metinler', () {
    test('üç dilde de aynı anahtarlar var ve boş değer yok', () {
      final tr = strings['TR']!.keys.toSet();
      for (final lang in ['EN', 'FR']) {
        expect(strings[lang]!.keys.toSet(), tr, reason: '$lang anahtarları TR ile aynı olmalı');
        for (final e in strings[lang]!.entries) {
          expect(e.value.trim(), isNotEmpty, reason: '$lang/${e.key} boş');
        }
      }
    });

    test('düzeltilen çeviriler korunuyor', () {
      expect(strings['EN']!['correct'], 'CORRECT');
      expect(strings['EN']!['meaning'], 'DEFINITION');
      expect(strings['FR']!['correct'], 'JUSTE');
      for (final lang in strings.keys) {
        expect(strings[lang]!['howToText']!.toLowerCase(), isNot(contains('forbidden')));
        expect(strings[lang]!['howToText']!.toLowerCase(), isNot(contains('yasaklı')));
      }
    });

    test('dil, seçili paketin dilinden gelir', () {
      final g = Game.instance;
      g.packIndex = 1;
      expect(tr('correct'), 'CORRECT');
      g.packIndex = 2;
      expect(tr('correct'), 'JUSTE');
      g.packIndex = 0;
      expect(tr('correct'), 'DOĞRU');
    });
  });
}
