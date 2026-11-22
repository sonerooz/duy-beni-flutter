import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_state.dart';
import 'sfx.dart';
import 'ui/common.dart';
import 'ui/menu.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Game.instance.init();
  Sfx.init();
  runApp(const DuyBeniApp());
}

class DuyBeniApp extends StatelessWidget {
  const DuyBeniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duy Beni',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'OpenSans', scaffoldBackgroundColor: kAmber),
      // Yerleşim ekran genişliğine göre ölçeklendiği için yazı büyütme hafif sınırlanır.
      builder: (context, child) {
        final scale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.15);
        return MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!);
      },
      home: const SplashScreen(),
    );
  }
}
