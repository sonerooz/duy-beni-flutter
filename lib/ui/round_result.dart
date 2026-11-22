import 'package:flutter/material.dart';

import '../game_state.dart';
import '../l10n.dart';
import 'common.dart';
import 'results.dart';

/// Bir takımın turu bitince doğru ve pas sayıları. Sonuç ekran açılırken kaydedilir.
class RoundResultScreen extends StatefulWidget {
  const RoundResultScreen({super.key});

  @override
  State<RoundResultScreen> createState() => _RoundResultScreenState();
}

class _RoundResultScreenState extends State<RoundResultScreen> {
  final game = Game.instance;

  @override
  void initState() {
    super.initState();
    game.recordRound();
  }

  void _next() => go(context, const ResultsScreen());

  @override
  Widget build(BuildContext context) {
    final w = sw(context), h = sh(context);
    Widget label(String t) => Text(t, style: ts(w * 0.078, weight: 500));
    Widget number(int n) => Text('$n', style: ts(w * 0.14, weight: 700));
    return DuyPage(
      // Skor zaten kaydedildi: geri tuşu DEVAM ET ile aynı.
      onBack: _next,
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, right: 0, child: Center(child: Padding(padding: EdgeInsets.only(top: w * 0.07), child: Logo(width: w * 0.27)))),
          Positioned(top: h * 0.2, left: 0, right: 0, child: Center(child: label('${tr('team')} ${game.currentTeam}'))),
          Positioned(top: h * 0.355, left: 0, right: 0, child: Center(child: label(tr('correct')))),
          Positioned(top: h * 0.42, left: 0, right: 0, child: Center(child: number(game.lastCorrect))),
          Positioned(top: h * 0.6, left: 0, right: 0, child: Center(child: label(tr('pass')))),
          Positioned(top: h * 0.665, left: 0, right: 0, child: Center(child: number(game.lastPass))),
          Positioned(
            top: h * 0.84,
            left: 0,
            right: 0,
            child: Center(child: DuyButton(width: w * 0.48, height: w * 0.16, fontSize: w * 0.056, text: tr('continue'), onTap: _next)),
          ),
        ],
      ),
    );
  }
}
