import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class RulerWidget extends StatelessWidget {
  const RulerWidget({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppConstants.screenHeight, width: 50,
    child: CustomPaint(painter: _RulerPainter()),
  );
}

class _RulerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x36FFFFFF)..strokeWidth = 1;
    const inc = 10.0;
    final mid = size.height / 2;
    for (var offset = 0.0; offset <= mid; offset += inc) {
      final long = offset % 50 == 0;
      final len  = long ? 30.0 : 15.0;
      canvas.drawLine(Offset(0, mid - offset), Offset(len, mid - offset), paint);
      canvas.drawLine(Offset(0, mid + offset), Offset(len, mid + offset), paint);
      if (long && offset != 0) {
        _label(canvas,  offset.toInt().toString(), mid - offset);
        _label(canvas, (-offset).toInt().toString(), mid + offset);
      }
    }
  }

  void _label(Canvas canvas, String text, double y) {
    final tp = TextPainter(
      text: TextSpan(text: text,
          style: const TextStyle(color: Colors.white70, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(32, y - 6));
  }

  @override
  bool shouldRepaint(_) => false;
}
