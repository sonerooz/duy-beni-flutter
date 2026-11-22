import 'package:flutter/material.dart';

import '../data.dart';
import '../game_state.dart';
import '../l10n.dart';
import 'common.dart';
import 'menu.dart';

/// Sözlük: yazarken anlam anında görünür; butona ya da Enter'a basınca bulunamazsa uyarı verilir.
class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final game = Game.instance;
  final _controller = TextEditingController();
  String _result = '';
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    game.preload().ignore();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _back() => go(context, const MenuScreen());

  Future<void> _search(bool full) async {
    final q = _controller.text.trim();
    final id = ++_seq;
    if (q.isEmpty) {
      setState(() => _result = full ? tr('enterWord') : '');
      return;
    }
    final found = await PackData.lookup(game.pack, q);
    if (!mounted || id != _seq) return; // daha yeni bir arama başladı
    setState(() {
      if (found != null) {
        _result = found.$2.replaceAll(' / ', '\n\n').replaceAll('/', '\n\n');
      } else {
        _result = full ? tr('notFound') : '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = sw(context), h = sh(context);
    return DuyPage(
      onBack: _back,
      child: Column(
        children: [
          DuyHeader(onBack: _back, logoWidth: 0.34),
          SizedBox(height: w * 0.04),
          trText(context, 'dictionary', size: 0.07),
          SizedBox(height: w * 0.05),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.09),
            child: TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.search,
              style: ts(w * 0.056, weight: 500),
              cursorColor: kInk,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0x66FFFFFF),
                hintText: tr('typeWord'),
                hintStyle: ts(w * 0.05, color: const Color(0x99000000)),
                contentPadding: EdgeInsets.symmetric(vertical: w * 0.035),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(w * 0.04), borderSide: BorderSide.none),
              ),
              onChanged: (_) => _search(false),
              onSubmitted: (_) => _search(true),
            ),
          ),
          SizedBox(height: w * 0.04),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: w * 0.09),
              child: Text(_result, textAlign: TextAlign.center, style: ts(w * 0.05, weight: 500, height: 1.3)),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: h * 0.06, top: w * 0.03),
            child: DuyButton(width: w * 0.51, height: w * 0.158, fontSize: w * 0.05, text: tr('meaning'), onTap: () => _search(true)),
          ),
        ],
      ),
    );
  }
}
