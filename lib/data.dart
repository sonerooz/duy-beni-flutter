import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bir kelime paketi: dil ve konu. Kelime -> anlam sözlüğü ile zorluk listeleri ayrı dosyalardadır.
class Pack {
  const Pack(this.id, this.name, this.lang);
  final String id, name;

  /// "TR", "EN" ya da "FR": arayüz bu dilde gösterilir.
  final String lang;

  String get dictAsset => 'assets/data/dict/$id.json';
  String get levelAsset => 'assets/data/level/$id.json';
}

const packs = [
  Pack('tr', 'Türkçe', 'TR'),
  Pack('en', 'English', 'EN'),
  Pack('fr', 'Français', 'FR'),
  Pack('zkusagi', 'Z Kuşağı', 'TR'),
  Pack('gamer', 'Gamer', 'TR'),
  Pack('finans', 'Finans', 'TR'),
  Pack('eskitr', 'EskiTR', 'TR'),
  Pack('plaza', 'Plaza', 'TR'),
  Pack('gym', 'GYM', 'TR'),
  Pack('hukuk', 'Hukuk', 'TR'),
  Pack('saglik', 'Sağlık', 'TR'),
  Pack('develop', 'Develop', 'TR'),
];

/// Zorluk düzeyleri; dosyalardaki anahtarlar ve ekrandaki sıra bu.
const levels = ['KOLAY', 'ORTA', 'ZOR'];

/// Büyük/küçük harf duyarsız arama için: Türkçede İ -> i ve I -> ı olur.
String fold(String s, String lang) {
  final t = s.trim();
  if (lang == 'TR') return t.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
  return t.toLowerCase();
}

/// Bir paketin kelime -> anlam sözlüğü ve arama dizini (küçük harfli kelime -> asıl kelime).
class Dict {
  Dict(this.words, this.index);
  final Map<String, String> words;
  final Map<String, String> index;
}

class _ParseJob {
  const _ParseJob(this.raw, this.lang);
  final String raw;
  final String lang;
}

// 5 MB'lık Türkçe sözlük arayüzü dondurmasın diye ayrı iş parçacığında çözülür.
Dict _parseDict(_ParseJob job) {
  final m = jsonDecode(job.raw) as Map<String, dynamic>;
  final words = <String, String>{for (final e in m.entries) e.key: e.value.toString()};
  final index = <String, String>{for (final k in words.keys) fold(k, job.lang): k};
  return Dict(words, index);
}

/// Paket verilerini yükler ve önbelleğe alır.
class PackData {
  static final Map<String, Dict> _dicts = {};
  static final Map<String, Future<Dict>> _loading = {};
  static final Map<String, Map<String, List<String>>> _levels = {};

  /// Testlerde dosyadan okumak için değiştirilebilir.
  static Future<String> Function(String asset) loader = rootBundle.loadString;

  static Future<Dict> dict(Pack p) {
    final done = _dicts[p.id];
    if (done != null) return Future.value(done);
    return _loading[p.id] ??= () async {
      final raw = await loader(p.dictAsset);
      final d = await compute(_parseDict, _ParseJob(raw, p.lang));
      _dicts[p.id] = d;
      return d;
    }();
  }

  /// Zorluk listeleri: {"KOLAY": [...], "ORTA": [...], "ZOR": [...]}
  static Future<Map<String, List<String>>> levelLists(Pack p) async {
    final cached = _levels[p.id];
    if (cached != null) return cached;
    final m = jsonDecode(await loader(p.levelAsset)) as Map<String, dynamic>;
    return _levels[p.id] = {for (final e in m.entries) e.key: [for (final w in e.value as List) w.toString()]};
  }

  /// Önce seçili pakette, sonra aynı dildeki diğer paketlerde arar. Bulamazsa null.
  static Future<(String word, String meaning)?> lookup(Pack active, String query) async {
    final key = fold(query, active.lang);
    if (key.isEmpty) return null;
    final order = [active, ...packs.where((p) => p.lang == active.lang && p.id != active.id)];
    for (final p in order) {
      final d = await dict(p);
      final orig = d.index[key];
      if (orig != null) return (orig, d.words[orig]!.trim());
    }
    return null;
  }
}

/// Tekrarsız kelime destesi. Uygulama açık kaldığı sürece çıkan kelime bir daha gelmez
/// (zorluk ya da paket değişse de). Seçili düzey biterse yakın düzeyden verilir;
/// paketteki tüm kelimeler biterse o paket için baştan başlanır.
class Deck {
  final Set<String> _used = {};
  final Map<String, List<String>> _decks = {};

  static String _key(Pack p, String level) => '${p.id}:$level';

  String? _pull(Pack p, Map<String, List<String>> lists, String level) {
    final key = _key(p, level);
    final deck = _decks.putIfAbsent(key, () {
      final d = [for (final w in lists[level] ?? const <String>[]) if (!_used.contains(w)) w];
      d.shuffle();
      return d;
    });
    while (deck.isNotEmpty) {
      final w = deck.removeLast();
      if (!_used.contains(w)) return w;
    }
    return null;
  }

  /// Sıradaki kelime; paket boşsa null.
  String? next(Pack p, Map<String, List<String>> lists, String level) {
    if (lists.isEmpty) return null;
    final order = [level];
    final i = levels.indexOf(level);
    for (final f in [1, -1, 2, -2]) {
      final j = i + f;
      if (i >= 0 && j >= 0 && j < levels.length) order.add(levels[j]);
    }
    for (final lv in order) {
      final w = _pull(p, lists, lv);
      if (w != null) {
        _used.add(w);
        return w;
      }
    }
    // Bu paketin bütün kelimeleri kullanıldı: bu paket için baştan başla.
    for (final lv in levels) {
      for (final w in lists[lv] ?? const <String>[]) {
        _used.remove(w);
      }
      _decks.remove(_key(p, lv));
    }
    final w = _pull(p, lists, level);
    if (w != null) _used.add(w);
    return w;
  }
}
