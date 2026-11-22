import 'dart:async';

import 'package:flutter/material.dart';

import '../game_state.dart';
import '../l10n.dart';
import 'common.dart';
import 'dictionary.dart';
import 'ready.dart';
import 'settings.dart';

/// Açılış: siyah zeminde logo yavaşça belirir, 3 saniye sonra ana menüye geçilir.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this, duration: const Duration(seconds: 2))..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) go(context, const MenuScreen());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = sw(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Image.asset('assets/images/splash.png', width: w * 0.62, filterQuality: FilterQuality.medium),
        ),
      ),
    );
  }
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
