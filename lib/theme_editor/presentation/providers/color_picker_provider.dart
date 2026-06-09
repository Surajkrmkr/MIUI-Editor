import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/element_widget.dart';

enum ColorTarget { primary, secondary, digit1, digit2, border }

class ColorPickerState {
  const ColorPickerState({this.type, this.target});
  final ElementType? type;
  final ColorTarget? target;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ColorPickerState &&
      other.type == type &&
      other.target == target;
  }

  @override
  int get hashCode => type.hashCode ^ target.hashCode;
}

final colorPickerStateProvider = StateProvider<ColorPickerState>((ref) {
  return const ColorPickerState();
});
