import 'dart:async';

import 'package:flutter/material.dart';

import '../game_state.dart';
import '../l10n.dart';
import '../sfx.dart';
import 'common.dart';
import 'game_screen.dart';
import 'menu.dart';

/// Takımlar arası "Hazır mısınız?" ekranı. BAŞLA'ya basınca 3-2-1 sayılır, sonra tur başlar.
class ReadyScreen extends StatefulWidget {
  const ReadyScreen({super.key});

  @override
  State<ReadyScreen> createState() => _ReadyScreenState();
}

class _ReadyScreenState extends State<ReadyScreen> with SingleTickerProviderStateMixin {
  final game = Game.instance;
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  String _count = '';
  bool _counting = false;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    // Kelime sözlüğünü arka planda hazırla: oyun içinde "anlamı" anında açılsın.
    game.preload().ignore();
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _back() {
    _left = true;
    game.running = false;
    go(context, const MenuScreen());
  }

  Future<void> _start() async {
    if (_counting) return;
    setState(() => _counting = true);
    for (final n in [3, 2, 1]) {
      if (_left || !mounted) return;
      setState(() => _count = '$n');
      _pop.forward(from: 0);
      Sfx.play('tik');
      Sfx.vibrate(40);
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (_left || !mounted) return;
    Sfx.play('son');
    go(context, const GameScreen());
  }

  @override
  Widget build(BuildContext context) {
    final w = sw(context), h = sh(context);
    var team = '${tr('team')} ${game.currentTeam}';
    if (game.teams > 1) team += '  (${game.currentTeam}/${game.teams})';
    return DuyPage(
      onBack: _back,
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, right: 0, child: Center(child: Padding(padding: EdgeInsets.only(top: w * 0.07), child: Logo(width: w * 0.27)))),
          Positioned(top: h * 0.2, left: 0, right: 0, child: Center(child: Text(team, style: ts(w * 0.078, weight: 500)))),
          Positioned(top: h * 0.355, left: 0, right: 0, child: Center(child: Text(tr('ready'), style: ts(w * 0.078, weight: 500)))),
          Positioned(
            top: h * 0.425,
            left: 0,
            right: 0,
            child: Center(
              child: ScaleTransition(
                scale: Tween(begin: 1.6, end: 1.0).animate(CurvedAnimation(parent: _pop, curve: Curves.easeOutBack)),
                child: Text(_count, style: ts(w * 0.2, weight: 700)),
              ),
            ),
          ),
          Positioned(
            top: h * 0.6,
            left: w * 0.05,
            right: w * 0.05,
            child: Column(
              children: [
                Text(
                  '${game.pack.name}  ·  ${levelName(game.level)}  ·  ${game.duration} ${tr('sec')}',
                  textAlign: TextAlign.center,
                  style: ts(w * 0.047, weight: 500),
                ),
                SizedBox(height: w * 0.04),
                Text(tr('explainer'), textAlign: TextAlign.center, style: ts(w * 0.042)),
              ],
            ),
          ),
          if (!_counting)
            Positioned(
              top: h * 0.84,
              left: 0,
              right: 0,
              child: Center(child: DuyButton(width: w * 0.48, height: w * 0.16, fontSize: w * 0.056, text: tr('start'), onTap: _start)),
            ),
        ],
      ),
    );
  }
}
