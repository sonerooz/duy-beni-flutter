import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';

/// Bir takımın tur sonucu.
class TeamResult {
  const TeamResult(this.correct, this.pass);
  final int correct, pass;
}

/// Ayarlar, maç durumu ve sonuç geçmişi. Eski Godot sürümündeki `Global` ile aynı kurallar.
class Game {
  Game._();
  static final Game instance = Game._();

  static const durations = [30, 60, 90, 120];
  static const maxTeams = 4;

  SharedPreferences? _prefs;

  // --- ayarlar (diske kaydedilir)
  int packIndex = 0;
  int duration = 60;
  String level = 'ORTA';
  int teams = 2;

  // --- maç
  int currentTeam = 1;
  bool running = false;
  Map<int, TeamResult> results = {};
  int lastCorrect = 0, lastPass = 0;
  final Deck deck = Deck();

  Pack get pack => packs[packIndex.clamp(0, packs.length - 1)];

  /// Arayüz dili: seçili paketin dili.
  String get lang => pack.lang;

  Future<void> init({SharedPreferences? prefs}) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
    final p = _prefs!;
    packIndex = (p.getInt('pack') ?? packIndex).clamp(0, packs.length - 1);
    final d = p.getInt('duration');
    if (d != null && durations.contains(d)) duration = d;
    final l = p.getString('level');
    if (l != null && levels.contains(l)) level = l;
    teams = (p.getInt('teams') ?? teams).clamp(1, maxTeams);
    _loadHistory();
  }

  void _saveSettings() {
    final p = _prefs;
    if (p == null) return;
    p.setInt('pack', packIndex);
    p.setInt('duration', duration);
    p.setString('level', level);
    p.setInt('teams', teams);
  }

  void setPack(int i) {
    packIndex = i.clamp(0, packs.length - 1);
    _saveSettings();
  }

  void cycleDuration() {
    duration = durations[(durations.indexOf(duration) + 1) % durations.length];
    _saveSettings();
  }

  void cycleLevel() {
    level = levels[(levels.indexOf(level) + 1) % levels.length];
    _saveSettings();
  }

  void cycleTeams() {
    teams = (teams % maxTeams) + 1;
    _saveSettings();
  }

  // --- maç akışı

  void startSeries() {
    results = {};
    currentTeam = 1;
    lastCorrect = 0;
    lastPass = 0;
    running = true;
    _saveHistory();
  }

  void recordRound() {
    results[currentTeam] = TeamResult(lastCorrect, lastPass);
    _saveHistory();
  }

  /// Sırada başka takım var mı.
  bool get hasNextTeam => running && currentTeam < teams;

  /// Kazananlar: en çok doğru; eşitlikte daha az pas yapan önde.
  /// Birden fazla takım dönerse berabere demektir.
  List<int> winners() {
    var best = <int>[];
    var bestC = -1, bestP = 0;
    for (final e in results.entries) {
      final c = e.value.correct, p = e.value.pass;
      if (c > bestC || (c == bestC && p < bestP)) {
        best = [e.key];
        bestC = c;
        bestP = p;
      } else if (c == bestC && p == bestP) {
        best.add(e.key);
      }
    }
    return best;
  }

  /// Seçili paketin zorluk listelerini ve sözlüğünü önceden yükler (hata sessizce yutulur).
  Future<void> preload() async {
    try {
      await PackData.levelLists(pack);
      await PackData.dict(pack);
    } catch (_) {}
  }

  Future<String?> nextWord() async {
    final lists = await PackData.levelLists(pack);
    return deck.next(pack, lists, level);
  }

  // --- geçmiş

  void _saveHistory() {
    final p = _prefs;
    if (p == null) return;
    p.setString(
      'history',
      jsonEncode({
        'v': 2,
        'teams': teams,
        'results': {for (final e in results.entries) '${e.key}': {'c': e.value.correct, 'p': e.value.pass}},
      }),
    );
  }

  void _loadHistory() {
    final raw = _prefs?.getString('history');
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if (m['v'] != 2) return;
      results = {
        for (final e in (m['results'] as Map<String, dynamic>).entries)
          int.parse(e.key): TeamResult((e.value['c'] as num).toInt(), (e.value['p'] as num).toInt()),
      };
    } catch (_) {
      results = {};
    }
  }
}
