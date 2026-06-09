import '../constants/app_constants.dart';
import '../../domain/entities/element_widget.dart';

const double _kThreshold = 6.0;

class SnapResult {
  const SnapResult({
    required this.dx,
    required this.dy,
    this.guideX,
    this.guideY,
  });

  final double dx;
  final double dy;

  /// Canvas X-coordinate for the vertical snap guide line (null = no guide).
  final double? guideX;

  /// Canvas Y-coordinate for the horizontal snap guide line (null = no guide).
  final double? guideY;
}

/// Computes snapped position and guide lines for an element being dragged.
///
/// [dx]/[dy] are the candidate (pre-snap) offsets in canvas space.
/// [others] are all elements on the canvas except the one being dragged.
///
/// Coordinate convention (matches the existing Positioned/guide-line logic):
///   dx=0, dy=0 → content is centred on the canvas.
///   Canvas-space guide X = dx + screenWidth/2
///   Canvas-space guide Y = dy + screenHeight/2
SnapResult computeSnap({
  required double dx,
  required double dy,
  required List<LockElement> others,
}) {
  double snappedDx = dx;
  double snappedDy = dy;
  double? guideX;
  double? guideY;

  const cw = AppConstants.screenWidth;
  const ch = AppConstants.screenHeight;

  // ── X-axis snapping ──────────────────────────────────────────────────────

  // 1. Canvas centre (dx == 0 → content centred at cw/2)
  if (snappedDx.abs() < _kThreshold) {
    snappedDx = 0;
    guideX = cw / 2;
  }

  // 2. Align with another element's dx (same-axis alignment)
  for (final other in others) {
    if ((snappedDx - other.dx).abs() < _kThreshold) {
      snappedDx = other.dx;
      guideX = other.dx + cw / 2;
      break;
    }
  }

  // ── Y-axis snapping ──────────────────────────────────────────────────────

  // 1. Canvas centre (dy == 0 → content centred at ch/2)
  if (snappedDy.abs() < _kThreshold) {
    snappedDy = 0;
    guideY = ch / 2;
  }

  // 2. Align with another element's dy
  for (final other in others) {
    if ((snappedDy - other.dy).abs() < _kThreshold) {
      snappedDy = other.dy;
      guideY = other.dy + ch / 2;
      break;
    }
  }

  return SnapResult(dx: snappedDx, dy: snappedDy, guideX: guideX, guideY: guideY);
}
