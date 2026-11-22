import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data.dart';
import '../game_state.dart';
import '../l10n.dart';
import '../sfx.dart';
import 'common.dart';
import 'menu.dart';
import 'round_result.dart';

/// Oyun ekranı: kelime, sayaç, DOĞRU / PAS ve sözlük.
///
/// Son 10 saniyede sayaç kırmızıya döner ve tıklar; son 5 saniyede ekran kırmızı yanıp söner,
/// kelime sallanır, giderek tizleşen çift bip çalar ve telefon titrer. Süre bitince
/// "SÜRE BİTTİ!" gelir ve sonuç ekranına geçilir.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  static const warnSeconds = 10; // son kaç saniyede tık sesi ve kırmızı sayaç
  static const buzzSeconds = 5; // son kaç saniyede titreşim, flaş ve sallanma

  final game = Game.instance;

  late int _remaining = game.duration;
  String _word = '';
  bool _over = false;
  bool _popup = false;
  String _popupText = '';
  Timer? _timer;
  bool _inBackground = false;

  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 350), value: 1);
  late final AnimationController _flash = AnimationController(vsync: this, duration: const Duration(milliseconds: 600), value: 1);
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 300), value: 1);
  late final AnimationController _end = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  double _pulseFrom = 1.25, _flashPeak = 0.2, _shakeForce = 6;
  Color _flashColor = const Color(0xFFE60000);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    game.lastCorrect = 0;
    game.lastPass = 0;
    _nextWord();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inBackground = state != AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pulse.dispose();
    _flash.dispose();
    _shake.dispose();
    _end.dispose();
    super.dispose();
  }

  Future<void> _nextWord() async {
    final w = await game.nextWord();
    if (!mounted) return;
    setState(() => _word = w ?? '?');
  }

  // ------------------------------------------------------------ süre

  void _tick() {
    if (_over || _popup || _inBackground || !mounted) return;
    setState(() => _remaining = math.max(0, _remaining - 1));
    if (_remaining > 0) _lastSeconds();
    if (_remaining <= 0) _timeUp();
  }

  void _lastSeconds() {
    if (_remaining > warnSeconds) return;
    final last5 = _remaining <= buzzSeconds;
    _pulseFrom = last5 ? 1.6 : 1.25;
    _pulse.forward(from: 0);
    if (!last5) {
      Sfx.play('tik');
      return;
    }
    Sfx.heartbeat(_remaining);
    Sfx.vibrate(80);
    final step = buzzSeconds - _remaining;
    _flashColor = const Color(0xFFE60000);
    _flashPeak = 0.18 + step * 0.05;
    _flash.forward(from: 0);
    _shakeForce = 6.0 + step * 3.0;
    _shake.forward(from: 0);
  }

  Future<void> _timeUp() async {
    if (_over) return;
    setState(() => _over = true);
    _timer?.cancel();
    Sfx.play('bitti');
    Sfx.vibrate(600);
    // Beyaz parlama kırmızıya döner.
    _flashColor = Colors.white;
    _flashPeak = 0.75;
    _flash.duration = const Duration(milliseconds: 850);
    _flash.forward(from: 0);
    _end.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) go(context, const RoundResultScreen());
  }

  // ------------------------------------------------------------ düğmeler

  void _correct() {
    if (_over || _remaining <= 0) return;
    game.lastCorrect++;
    _nextWord();
  }

  void _pass() {
    if (_over || _remaining <= 0) return;
    game.lastPass++;
    _nextWord();
  }

  Future<void> _openMeaning() async {
    if (_word.isEmpty || _word == '?' || _over) return;
    setState(() {
      _popup = true;
      _popupText = '…';
    });
    var meaning = '';
    final active = await PackData.dict(game.pack);
    meaning = (active.words[_word] ?? '').trim();
    if (meaning.isEmpty) {
      final found = await PackData.lookup(game.pack, _word);
      meaning = found?.$2 ?? '';
    }
    if (meaning.isEmpty) meaning = tr('noMeaning');
    if (!mounted) return;
    setState(() => _popupText = '${_word.trim()}:\n\n${meaning.replaceAll(' / ', '\n').replaceAll('/', '\n')}');
  }

  void _closeMeaning() => setState(() => _popup = false);

  void _back() {
    if (_popup) {
      _closeMeaning();
      return;
    }
    _timer?.cancel();
    game.running = false;
    go(context, const MenuScreen());
  }

  // ------------------------------------------------------------ çizim

  double _wordSize(double w) {
    final t = _word.trim();
    var design = 160.0;
    if (!t.contains(' ')) {
      if (t.length > 13) {
        design = 100;
      } else if (t.length > 11) {
        design = 120;
      } else if (t.length > 8) {
        design = 140;
      }
    }
    return design / 1290 * w;
  }

  @override
  Widget build(BuildContext context) {
    final w = sw(context), h = sh(context);
    final alarm = _remaining <= warnSeconds && _remaining > 0 || _over;
    final shown = _word.trim().replaceAll(' ', '\n');
    return DuyPage(
      onBack: _back,
      child: Stack(
        children: [
          // üst şerit: geri, sayaç, sözlük
          Positioned(top: w * 0.04, left: w * 0.05, child: DuyBackButton(onTap: _back)),
          Positioned(
            top: w * 0.01,
            left: w * 0.2,
            right: w * 0.2,
            child: Center(
              child: ScaleTransition(
                scale: Tween(begin: _pulseFrom, end: 1.0).animate(CurvedAnimation(parent: _pulse, curve: Curves.elasticOut)),
                child: Text('$_remaining', style: ts(w * 0.2, weight: 700, color: alarm ? kAlarm : kInk)),
              ),
            ),
          ),
          Positioned(
            top: w * 0.04,
            right: w * 0.05,
            child: DuyButton(
              width: w * 0.13,
              height: w * 0.13,
              onTap: _openMeaning,
              child: Padding(padding: EdgeInsets.all(w * 0.015), child: Image.asset('assets/images/sozluk_ikon.png', filterQuality: FilterQuality.medium)),
            ),
          ),
          // kelime
          Positioned(
            top: h * 0.22,
            left: w * 0.04,
            right: w * 0.04,
            height: h * 0.4,
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_shake, _end]),
                builder: (_, child) {
                  final t = _shake.value;
                  final decay = _shake.isAnimating ? (1 - t) : 0.0;
                  final dx = math.sin(t * 38) * _shakeForce * decay;
                  final dy = math.cos(t * 47) * _shakeForce * 0.5 * decay;
                  final grow = _shake.isAnimating ? 1.08 - 0.08 * t : 1.0;
                  return Opacity(
                    opacity: _over ? 1 - 0.85 * _end.value : 1,
                    child: Transform.translate(offset: Offset(dx, dy), child: Transform.scale(scale: grow, child: child)),
                  );
                },
                child: Text(shown, textAlign: TextAlign.center, style: ts(_wordSize(w), weight: 500, height: 1.1)),
              ),
            ),
          ),
          // DOĞRU / PAS
          Positioned(
            top: h * 0.755,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DuyButton(width: w * 0.32, height: w * 0.19, fontSize: w * 0.06, text: tr('pass'), onTap: _pass),
                SizedBox(width: w * 0.07),
                DuyButton(width: w * 0.32, height: w * 0.19, fontSize: w * 0.06, text: tr('correct'), onTap: _correct),
              ],
            ),
          ),
          // kırmızı flaş
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _flash,
                builder: (_, _) {
                  final t = Curves.easeOut.transform(_flash.value);
                  if (_over) {
                    // beyaz -> kırmızı: önce 0.25 sn beyazdan kırmızıya, sonra sönükleşir
                    final k = (_flash.value / 0.3).clamp(0.0, 1.0);
                    final c = Color.lerp(Colors.white, const Color(0xFFD90000), k)!;
                    final a = k < 1 ? 0.75 - 0.3 * k : 0.45 - 0.2 * ((_flash.value - 0.3) / 0.7);
                    return ColoredBox(color: c.withValues(alpha: a.clamp(0.0, 1.0)));
                  }
                  return ColoredBox(color: _flashColor.withValues(alpha: _flashPeak * (1 - t)));
                },
              ),
            ),
          ),
          // "SÜRE BİTTİ!"
          if (_over)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: ScaleTransition(
                    scale: Tween(begin: 0.2, end: 1.0).animate(CurvedAnimation(parent: _end, curve: Curves.easeOutBack)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tr('timeUp'),
                          style: ts(w * 0.132, weight: 800, color: Colors.white).copyWith(
                            shadows: [for (final o in const [Offset(3, 0), Offset(-3, 0), Offset(0, 3), Offset(0, -3)]) Shadow(color: const Color(0xFF800000), offset: o, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_popup) _meaningPanel(w, h),
        ],
      ),
    );
  }

  Widget _meaningPanel(double w, double h) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _closeMeaning,
        child: ColoredBox(
          color: const Color(0x99000000),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: w * 0.88,
                constraints: BoxConstraints(maxHeight: h * 0.7),
                padding: EdgeInsets.fromLTRB(w * 0.06, w * 0.05, w * 0.06, w * 0.06),
                decoration: BoxDecoration(color: kAmber, borderRadius: BorderRadius.circular(w * 0.06)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(alignment: Alignment.centerRight, child: DuyButton(width: w * 0.12, height: w * 0.12, text: tr('close'), fontSize: w * 0.055, onTap: _closeMeaning)),
                    SizedBox(height: w * 0.03),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(_popupText, textAlign: TextAlign.center, style: ts(w * 0.052, weight: 500, height: 1.25)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
