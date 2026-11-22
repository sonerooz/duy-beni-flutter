// Tüm ekranların görüntüsünü dosyaya yazar ve temel akışı sınar (mağaza görselleri için de kullanılır).
//   flutter test test/screens_test.dart --dart-define=OUT=build/shots --dart-define=LANG=0
// LANG: kelime paketi sırası (0 Türkçe, 1 English, 2 Français).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:duybeni/data.dart';
import 'package:duybeni/game_state.dart';
import 'package:duybeni/l10n.dart';
import 'package:duybeni/sfx.dart';
import 'package:duybeni/ui/dictionary.dart';
import 'package:duybeni/ui/game_screen.dart';
import 'package:duybeni/ui/howto.dart';
import 'package:duybeni/ui/menu.dart';
import 'package:duybeni/ui/ready.dart';
import 'package:duybeni/ui/results.dart';
import 'package:duybeni/ui/round_result.dart';
import 'package:duybeni/ui/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const outDir = String.fromEnvironment('OUT', defaultValue: 'build/shots');
const packIndex = int.fromEnvironment('LANG', defaultValue: 0);
const width = int.fromEnvironment('W', defaultValue: 1080);
const height = int.fromEnvironment('H', defaultValue: 1920);

void main() {
  final key = GlobalKey();
  late WidgetTester t;

  Future<void> shot(String name) async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await t.runAsync(() async {
      final img = await boundary.toImage();
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$outDir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  /// Görsellerin çözülmesi için gerçek zaman tanır.
  Future<void> settle([int ms = 250]) async {
    await t.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
  }

  Future<void> show(Widget screen) async {
    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(key: UniqueKey(), debugShowCheckedModeBanner: false, theme: ThemeData(fontFamily: 'OpenSans'), home: screen),
    ));
    await settle();
  }

  testWidgets('ekranlar', (tester) async {
    t = tester;
    tester.view.physicalSize = Size(width.toDouble(), height.toDouble());
    tester.view.devicePixelRatio = 1;
    Directory(outDir).createSync(recursive: true);
    SharedPreferences.setMockInitialValues({});
    Sfx.enabled = false;
    PackData.loader = (asset) async => File(asset).readAsStringSync();
    await tester.runAsync(() async {
      final loader = FontLoader('OpenSans')..addFont(Future.value(ByteData.view(File('assets/fonts/OpenSans.ttf').readAsBytesSync().buffer)));
      await loader.load();
      await Game.instance.init();
      Game.instance.setPack(packIndex);
      Game.instance.teams = 2;
      await Game.instance.preload();
    });
    final g = Game.instance;

    // ---- açılış ve menü
    await show(const SplashScreen());
    await tester.pump(const Duration(seconds: 2));
    await shot('00_acilis');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text(tr('play')), findsOneWidget, reason: 'açılış 3 sn sonra ana menüye geçmeli');
    await settle();
    await shot('01_ana_menu');

    // ---- ayarlar
    await show(const SettingsScreen());
    await shot('02_ayarlar');
    await tester.tap(find.text('${g.duration} ${tr('sec')}'));
    await tester.pump();
    expect(g.duration, 90, reason: 'süre düğmesi 60 -> 90 yapmalı');
    g.duration = 60;

    // ---- hazır ekranı ve geri sayım
    g.startSeries();
    await show(const ReadyScreen());
    await shot('03_hazir');
    await tester.tap(find.text(tr('start')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await shot('04_geri_sayim');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget, reason: 'geri sayımdan sonra oyun başlamalı');

    // ---- oyun: normal, son 10 sn, son 5 sn, süre bitti
    await settle(50);
    await shot('05_oyun');
    await tester.tap(find.text(tr('correct')));
    await tester.pump();
    await tester.tap(find.text(tr('correct')));
    await tester.pump();
    await tester.tap(find.text(tr('pass')));
    await tester.pump();
    expect(g.lastCorrect, 2);
    expect(g.lastPass, 1);

    // Süreyi 11. saniyeye kadar ilerlet (60 -> 11).
    for (var i = 0; i < 49; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await shot('06_son_10_saniye');
    await tester.pump(const Duration(seconds: 1)); // 10 -> 9 ... son 5: 5. saniyede
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump(const Duration(milliseconds: 120));
    await shot('07_son_5_saniye');

    while (find.text(tr('timeUp')).evaluate().isEmpty) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump(const Duration(milliseconds: 600));
    await shot('08_sure_bitti');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(RoundResultScreen), findsOneWidget, reason: 'süre bitince tur sonucu açılmalı');
    expect(g.results[1]!.correct, 2, reason: 'tur sonucu kaydedilmeli');
    await settle(50);
    await shot('09_tur_sonucu');

    // ---- sonuçlar: maç sürüyor
    await tester.tap(find.text(tr('continue')));
    await tester.pumpAndSettle();
    expect(find.text(tr('nextTeam')), findsOneWidget, reason: 'ilk takımdan sonra SIRADAKİ TAKIM çıkmalı');
    await shot('10_sonuclar_devam');

    // ---- ikinci takım, sonra kazanan
    await tester.tap(find.text(tr('nextTeam')));
    await tester.pumpAndSettle();
    expect(g.currentTeam, 2);
    g.lastCorrect = 8;
    g.lastPass = 2;
    g.recordRound();
    await show(const ResultsScreen());
    await tester.pump(const Duration(milliseconds: 500));
    await shot('11_kazanan');
    expect(find.text(tr('newGame')), findsOneWidget);
    expect(g.running, isFalse, reason: 'maç bitince running kapanmalı');

    // ---- berabere
    g.results = {1: const TeamResult(5, 2), 2: const TeamResult(5, 2)};
    g.running = true;
    g.currentTeam = 2;
    await show(const ResultsScreen());
    await tester.pump(const Duration(milliseconds: 500));
    await shot('12_berabere');

    // ---- sözlük, nasıl oynanır, anlam penceresi
    await show(const DictionaryScreen());
    final lists = await tester.runAsync(() => PackData.levelLists(g.pack));
    final word = lists!['ORTA']!.first;
    await tester.runAsync(() => PackData.dict(g.pack));
    await tester.enterText(find.byType(TextField), word.toUpperCase());
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
    await shot('13_sozluk');
    await show(const HowToScreen());
    await shot('14_nasil');

    // ---- oyun içi anlam penceresi
    g.startSeries();
    await show(const GameScreen());
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byType(Image).last);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await shot('15_anlam_penceresi');
    // Bir saniye geçti: sayaç 59. Sözlük açıkken 5 saniye daha geçse de 59 kalmalı.
    expect(find.text('59'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('59'), findsOneWidget, reason: 'sözlük açıkken süre durmalı');

    await tester.pumpWidget(const SizedBox());
  });
}
