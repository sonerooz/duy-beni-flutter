import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n.dart';

const kAmber = Color(0xFFFFC000);
const kInk = Colors.black;

/// Kazanan takım satırının rengi (koyu kırmızı).
const kRed = Color(0xFF8C0D0D);

/// Son saniyelerde sayacın rengi.
const kAlarm = Color(0xFFD90D0D);

const _bgColors = [Color(0xFFE2AD0F), Color(0xFFE2AD0F), Color(0xFFFFD209), Color(0xFFD5B62B), Color(0xFFFAD614)];
const _bgStops = [0.0, 0.2664609, 0.5483539, 0.968107, 1.0];

double sw(BuildContext c) => MediaQuery.sizeOf(c).width;
double sh(BuildContext c) => MediaQuery.sizeOf(c).height;

TextStyle ts(double size, {int weight = 400, Color color = kInk, double? height}) => TextStyle(
      fontFamily: 'OpenSans',
      fontSize: size,
      color: color,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: [ui.FontVariation('wght', weight.toDouble())],
      height: height,
      decoration: TextDecoration.none,
    );

/// Çapraz sarı gradyan zemin. Gradyan birim kareye çizilip ekrana gerilir (Godot'taki
/// GradientTexture2D gibi), böylece bantlar her ekran oranında aynı görünür.
class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shader = ui.Gradient.linear(
      Offset.zero,
      const Offset(1, 1),
      _bgColors,
      _bgStops,
      TileMode.clamp,
      Matrix4.diagonal3Values(size.width, size.height, 1).storage,
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => false;
}

/// Her ekranın iskeleti: gradyan zemin ve Android geri tuşu davranışı.
/// [onBack] null ise geri tuşu uygulamadan çıkar.
class DuyPage extends StatelessWidget {
  const DuyPage({super.key, required this.child, this.onBack});
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack?.call();
      },
      child: Scaffold(
        backgroundColor: kAmber,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _BackgroundPainter()),
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}

/// Ekranlar arası kısa geçiş (eski sürümdeki gibi sahne değiştirir, geri yığını tutmaz).
void go(BuildContext context, Widget page) {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => page,
      transitionDuration: const Duration(milliseconds: 160),
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    ),
  );
}

class Logo extends StatelessWidget {
  const Logo({super.key, required this.width});
  final double width;

  @override
  Widget build(BuildContext context) => Image.asset('assets/images/logo.png', width: width, filterQuality: FilterQuality.medium);
}

/// Amber yuvarlak düğme: basınca %15 büyür, gölgesi vardır.
class DuyButton extends StatefulWidget {
  const DuyButton({super.key, required this.width, required this.height, required this.onTap, this.text, this.fontSize, this.child});
  final double width, height;
  final VoidCallback? onTap;
  final String? text;
  final double? fontSize;
  final Widget? child;

  @override
  State<DuyButton> createState() => _DuyButtonState();
}

class _DuyButtonState extends State<DuyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          width: widget.width,
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kAmber,
            borderRadius: BorderRadius.circular(widget.height * 0.16),
            boxShadow: [
              BoxShadow(color: const Color(0xB8AC7F1E), blurRadius: widget.height * 0.2, offset: Offset(0, widget.height * 0.13)),
            ],
          ),
          child: widget.child ??
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.width * 0.06),
                  child: Text(widget.text ?? '', style: ts(widget.fontSize ?? widget.height * 0.34)),
                ),
              ),
        ),
      ),
    );
  }
}

/// Sol üstteki küçük "<" düğmesi.
class DuyBackButton extends StatelessWidget {
  const DuyBackButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = sw(context) * 0.117;
    return DuyButton(
      width: s,
      height: s,
      onTap: onTap,
      child: Text('<', style: ts(s * 0.5)),
    );
  }
}

/// Üstte ortalanmış küçük logo ve solda geri düğmesi olan sayfa başlığı.
class DuyHeader extends StatelessWidget {
  const DuyHeader({super.key, this.onBack, this.logoWidth = 0.3});
  final VoidCallback? onBack;
  final double logoWidth;

  @override
  Widget build(BuildContext context) {
    final w = sw(context);
    return SizedBox(
      width: w,
      height: w * logoWidth * 0.72 + w * 0.03,
      child: Stack(
        children: [
          Positioned(top: w * 0.03, left: 0, right: 0, child: Center(child: Logo(width: w * logoWidth))),
          if (onBack != null) Positioned(top: w * 0.04, left: w * 0.05, child: DuyBackButton(onTap: onBack!)),
        ],
      ),
    );
  }
}

/// Kazanan satırının yıldızı (yazı tipinde ★ olmadığı için çizilir).
class StarMark extends StatelessWidget {
  const StarMark({super.key, required this.size, this.color = kRed});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _StarPainter(color));
}

class _StarPainter extends CustomPainter {
  const _StarPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero), r = s.width / 2, p = Path();
    for (var i = 0; i < 10; i++) {
      final a = -3.14159265 / 2 + i * 3.14159265 / 5;
      final rr = i.isEven ? r : r * 0.42;
      final pt = Offset(c.dx + rr * _cos(a), c.dy + rr * _sin(a));
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(p..close(), Paint()..color = color);
  }

  static double _cos(double a) => math.cos(a);
  static double _sin(double a) => math.sin(a);

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}

/// Dilin anahtarını okuyup yazıyı çizen kısa yol.
Text trText(BuildContext context, String key, {double size = 0.07, int weight = 500, Color color = kInk, TextAlign align = TextAlign.center}) =>
    Text(tr(key), textAlign: align, style: ts(sw(context) * size, weight: weight, color: color));
