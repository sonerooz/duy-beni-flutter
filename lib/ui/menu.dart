import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game_state.dart';
import '../l10n.dart';
import 'common.dart';
import 'dictionary.dart';
import 'ready.dart';
import 'settings.dart';

/// Açılış (yaklaşık 2 sn), Tamer'in 26 Kas 2026 tarifiyle:
///  - logo belirir ve durmadan ekrana doğru büyür (1 -> 2 kat),
///  - siyah zemin sağ üstten sol alta doğru ambere açılır, siyah sol alt köşede toplanır,
///  - büyüme biter bitmez, beklemeden ana menüye geçilir.
/// Gradyan, Godot sahnesindeki "radyal gecıs" ile aynı (dairesel, yarıçap 0.89), yalnızca
/// merkezi sol üst yerine sol alt köşede.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 2033));

  @override
  void initState() {
    super.initState();
    _anim.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) go(context, const MenuScreen());
    });
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = sw(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _anim,
        builder: (_, logo) {
          final t = _anim.value;
          final fade = (t / 0.5).clamp(0.0, 1.0);
          final scale = 1.0 + t;
          final glow = ((t - 0.35) / 0.65).clamp(0.0, 1.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _SplashGlowPainter(glow)),
              Center(child: Opacity(opacity: fade, child: Transform.scale(scale: scale, child: logo))),
            ],
          );
        },
        child: Image.asset('assets/images/splash.png', width: w * 700 / 1290, height: w * 780 / 1290, fit: BoxFit.fill, filterQuality: FilterQuality.medium),
      ),
    );
  }
}

/// Sol alt köşeden (siyah) sağ üste (amber) dairesel gradyan; birim kareye çizilip ekrana
/// gerilir. [k] 0 iken tamamen siyah, 1 iken tam renk.
class _SplashGlowPainter extends CustomPainter {
  const _SplashGlowPainter(this.k);
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    if (k <= 0) return;
    final edge = Color.lerp(Colors.black, const Color(0xFFFFC704), k)!;
    final shader = ui.Gradient.radial(
      const Offset(0, 1),
      0.8906,
      [Colors.black, edge],
      const [0.0, 1.0],
      TileMode.clamp,
      Matrix4.diagonal3Values(size.width, size.height, 1).storage,
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_SplashGlowPainter old) => old.k != k;
}

/// Ana menü. Geri tuşu uygulamadan çıkar.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = sw(context), h = sh(context);
    Widget btn(String key, VoidCallback onTap) => DuyButton(width: w * 0.51, height: w * 0.158, fontSize: w * 0.053, text: tr(key), onTap: onTap);
    return DuyPage(
      child: Stack(
        children: [
          Positioned(top: h * 0.045, left: 0, right: 0, child: Center(child: Logo(width: w * 0.56))),
          Positioned(
            top: h * 0.43,
            left: 0,
            right: 0,
            child: Column(
              children: [
                btn('play', () {
                  Game.instance.startSeries();
                  go(context, const ReadyScreen());
                }),
                SizedBox(height: w * 0.08),
                btn('settings', () => go(context, const SettingsScreen())),
                SizedBox(height: w * 0.08),
                btn('dictionary', () => go(context, const DictionaryScreen())),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
