import 'package:flutter/material.dart';

import '../game_state.dart';
import '../l10n.dart';
import '../sfx.dart';
import 'common.dart';
import 'menu.dart';
import 'ready.dart';

/// Skor tablosu ve kazanan.
///  - Maç sürüyorsa: ara skorlar ve "SIRADAKİ TAKIM" düğmesi.
///  - Maç bittiyse (ya da Ayarlar'daki oyun geçmişinden açıldıysa): kazanan ve "YENİ OYUN".
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  final game = Game.instance;
  late final bool _ongoing = game.hasNextTeam;
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

  @override
  void initState() {
    super.initState();
    if (!_ongoing && game.results.isNotEmpty) {
      _pop.forward();
      Sfx.vibrate(200);
      game.running = false;
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _mainMenu() {
    game.running = false;
    go(context, const MenuScreen());
  }

  void _primary() {
    if (_ongoing) {
      game.currentTeam++;
    } else {
      game.startSeries();
    }
    go(context, const ReadyScreen());
  }

  String _winnerText() {
    final r = game.results;
    if (r.length == 1) return '${tr('score')}: ${r.values.first.correct}';
    final win = game.winners();
    if (win.length == 1) return '${tr('winner')}\n${tr('team')} ${win.first}';
    return '${tr('draw')}\n${tr('team')} ${win.join(' & ')}';
  }

  @override
  Widget build(BuildContext context) {
    final w = sw(context), h = sh(context);
    final done = !_ongoing && game.results.isNotEmpty;
    final winners = done ? game.winners() : const <int>[];
    final teams = game.results.keys.toList()..sort();

    Widget cell(String text, double size, Color color, {int weight = 400}) =>
        Expanded(child: Center(child: Text(text, style: ts(w * size, weight: weight, color: color))));

    Widget header(String key) => Expanded(
          child: Center(
            child: Container(
              padding: EdgeInsets.only(bottom: w * 0.01),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(width: w * 0.006, color: kInk))),
              child: Text(tr(key), style: ts(w * 0.04, weight: 500)),
            ),
          ),
        );

    return DuyPage(
      onBack: _mainMenu,
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, right: 0, child: Center(child: Padding(padding: EdgeInsets.only(top: w * 0.07), child: Logo(width: w * 0.27)))),
          Positioned(top: h * 0.2, left: 0, right: 0, child: Center(child: Text(tr('results'), style: ts(w * 0.07, weight: 500)))),
          Positioned(
            top: h * 0.3,
            left: w * 0.06,
            right: w * 0.06,
            child: Column(
              children: [
                Row(children: [header('team'), header('correct'), header('pass')]),
                SizedBox(height: w * 0.03),
                for (final t in teams)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: w * 0.012),
                    child: Row(
                      children: () {
                        final win = winners.contains(t) && game.results.length > 1;
                        final c = win ? kRed : kInk;
                        return [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (win) ...[StarMark(size: w * 0.04), SizedBox(width: w * 0.012)],
                                Text('${tr('team')} $t', style: ts(w * 0.042, color: c)),
                              ],
                            ),
                          ),
                          cell('${game.results[t]!.correct}', 0.055, c, weight: 500),
                          cell('${game.results[t]!.pass}', 0.055, c, weight: 500),
                        ];
                      }(),
                    ),
                  ),
              ],
            ),
          ),
          if (done)
            Positioned(
              top: h * 0.3 + w * 0.12 + teams.length * w * 0.085 + w * 0.05,
              left: 0,
              right: 0,
              child: ScaleTransition(
                scale: Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _pop, curve: Curves.easeOutBack)),
                child: Text(_winnerText(), textAlign: TextAlign.center, style: ts(w * 0.085, weight: 500, color: kRed, height: 1.15)),
              ),
            ),
          Positioned(
            bottom: h * 0.2,
            left: 0,
            right: 0,
            child: Center(
              child: DuyButton(width: w * 0.55, height: w * 0.16, fontSize: w * 0.05, text: tr(_ongoing ? 'nextTeam' : 'newGame'), onTap: _primary),
            ),
          ),
          Positioned(
            bottom: h * 0.08,
            left: 0,
            right: 0,
            child: Center(child: DuyButton(width: w * 0.55, height: w * 0.16, fontSize: w * 0.05, text: tr('mainMenu'), onTap: _mainMenu)),
          ),
        ],
      ),
    );
  }
}
