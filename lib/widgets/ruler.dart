import 'package:flutter/material.dart';

import '../constants.dart';

class RulerWidget extends StatelessWidget {
  const RulerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MIUIConstants.screenHeight,
      width: 50, // Width of the ruler
      color: Colors.transparent, // Background color of the ruler
      child: CustomPaint(
        painter: RulerPainter(),
      ),
    );
  }
}

class RulerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = const Color.fromARGB(54, 255, 255, 255)
      ..strokeWidth = 1.0;

    double middleY = size.height / 2;
    double increment = 10; // Distance between ruler markings
    double currentHeight = 0;

    for (double yPos = middleY; yPos >= 0; yPos -= increment) {
      canvas.drawLine(
        Offset(0, yPos),
        Offset(currentHeight % 50 == 0 ? 30 : 15,
            yPos), // Long line every 50 units
        paint,
      );
      if (currentHeight % 50 == 0) {
        drawText(canvas, currentHeight.toInt().toString(), yPos);
      }
      currentHeight += increment;
    }

    currentHeight = 0;
    for (double yPos = middleY; yPos <= size.height; yPos += increment) {
      canvas.drawLine(
        Offset(0, yPos),
        Offset(currentHeight % 50 == 0 ? 30 : 15,
            yPos), // Long line every 50 units
        paint,
      );
      if (currentHeight % 50 == 0 && currentHeight != 0) {
        drawText(canvas, (-currentHeight).toInt().toString(), yPos);
      }
      currentHeight += increment;
    }
  }

  void drawText(Canvas canvas, String text, double yPos) {
    TextSpan span = TextSpan(
      style: const TextStyle(color: Colors.white, fontSize: 12),
      text: text,
    );
    TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(35, yPos - 6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
