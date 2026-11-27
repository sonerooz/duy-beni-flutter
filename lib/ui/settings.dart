import 'package:flutter/material.dart';

import '../data.dart';
import '../game_state.dart';
import '../l10n.dart';
import 'common.dart';
import 'howto.dart';
import 'menu.dart';
import 'results.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final game = Game.instance;

  void _back() => go(context, const MenuScreen());

  Future<void> _pickPack() async {
    final i = await showDialog<int>(
      context: context,
      barrierColor: const Color(0x99000000),
      builder: (_) => _PackDialog(selected: game.packIndex),
    );
    if (i != null) setState(() => game.setPack(i));
  }

  @override
  Widget build(BuildContext context) {
    final w = sw(context), h = sh(context);
    Widget row(String label, String value, VoidCallback onTap) => Padding(
          padding: EdgeInsets.only(bottom: w * 0.082),
          child: DuyButton(
            width: w * 0.76,
            height: w * 0.128,
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: ts(w * 0.044, weight: 500))),
                  Text(value, style: ts(w * 0.044)),
                ],
              ),
            ),
          ),
        );
    Widget wide(String text, VoidCallback onTap) => Padding(
          padding: EdgeInsets.only(bottom: w * 0.082),
          child: DuyButton(width: w * 0.76, height: w * 0.128, fontSize: w * 0.042, text: text, onTap: onTap),
        );
    return DuyPage(
      onBack: _back,
      child: Column(
        children: [
          DuyHeader(onBack: _back, logoWidth: 0.34),
          SizedBox(height: h * 0.03),
          row(tr('language'), game.pack.name, _pickPack),
          row(tr('team'), '${game.teams}', () => setState(game.cycleTeams)),
          row(tr('duration'), '${game.duration} ${tr('sec')}', () => setState(game.cycleDuration)),
          row(tr('difficulty'), levelName(game.level), () => setState(game.cycleLevel)),
          wide(tr('history'), () {
            game.running = false;
            go(context, const ResultsScreen(history: true));
          }),
          wide(tr('howTo'), () => go(context, const HowToScreen())),
        ],
      ),
    );
  }
}

/// Kelime paketi seçimi.
class _PackDialog extends StatelessWidget {
  const _PackDialog({required this.selected});
  final int selected;

  @override
  Widget build(BuildContext context) {
    final w = sw(context), h = sh(context);
    return Dialog(
      backgroundColor: kAmber,
      insetPadding: EdgeInsets.symmetric(horizontal: w * 0.14, vertical: h * 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(w * 0.05)),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: w * 0.03),
        shrinkWrap: true,
        itemCount: packs.length,
        itemBuilder: (_, i) => InkWell(
          onTap: () => Navigator.of(context).pop(i),
          child: Container(
            height: w * 0.13,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: w * 0.07),
            color: i == selected ? const Color(0x33000000) : Colors.transparent,
            child: Text(packs[i].name, style: ts(w * 0.056, weight: i == selected ? 700 : 400)),
          ),
        ),
      ),
    );
  }
}
