import 'package:flutter/material.dart';

import '../l10n.dart';
import 'common.dart';
import 'settings.dart';

class HowToScreen extends StatelessWidget {
  const HowToScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = sw(context);
    void back() => go(context, const SettingsScreen());
    return DuyPage(
      onBack: back,
      child: Column(
        children: [
          DuyHeader(onBack: back, logoWidth: 0.34),
          SizedBox(height: w * 0.06),
          trText(context, 'howTo', size: 0.07),
          SizedBox(height: w * 0.05),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.09),
            child: Text(tr('howToText'), textAlign: TextAlign.center, style: ts(w * 0.052, weight: 500, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
