import 'dart:io';
import 'package:flutter/material.dart';

class ComparisonSlider extends StatefulWidget {
  final String beforeImagePath;
  final String afterImagePath;

  const ComparisonSlider({
    super.key,
    required this.beforeImagePath,
    required this.afterImagePath,
  });

  @override
  State<ComparisonSlider> createState() => _ComparisonSliderState();
}

class _ComparisonSliderState extends State<ComparisonSlider> {
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _sliderValue = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
            });
          },
          child: Stack(
            children: [
              // After image (Bottom)
              Positioned.fill(
                child: Image.file(
                  File(widget.afterImagePath),
                  fit: BoxFit.contain,
                ),
              ),
              
              // Before image (Top, Clipped)
              Positioned.fill(
                child: ClipRect(
                  clipper: _LeftClipper(_sliderValue),
                  child: Image.file(
                    File(widget.beforeImagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Slider Handle
              Positioned(
                left: constraints.maxWidth * _sliderValue - 1,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  color: Colors.white,
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.unfold_more_rounded,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

              // Labels
              Positioned(
                left: 10,
                bottom: 10,
                child: _buildLabel('BEFORE'),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: _buildLabel('AFTER'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  final double fraction;
  _LeftClipper(this.fraction);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * fraction, size.height);
  }

  @override
  bool shouldReclip(_LeftClipper oldClipper) => oldClipper.fraction != fraction;
}
