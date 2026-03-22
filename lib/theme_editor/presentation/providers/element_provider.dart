import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/element_widget.dart';

class ElementState {
  const ElementState({
    this.elements = const [],
    this.activeType = ElementType.swipeUpUnlock,
    this.bgAlpha = 0.0,
    this.hasSelection = false,
  });

  final List<LockElement> elements;
  final ElementType activeType;
  final double bgAlpha;
  final bool hasSelection;

  ElementState copyWith({
    List<LockElement>? elements,
    ElementType? activeType,
    double? bgAlpha,
    bool? hasSelection,
  }) =>
      ElementState(
        elements: elements ?? this.elements,
        activeType: activeType ?? this.activeType,
        bgAlpha: bgAlpha ?? this.bgAlpha,
        hasSelection: hasSelection ?? this.hasSelection,
      );

  LockElement? get active => hasSelection
      ? elements.where((e) => e.type == activeType).firstOrNull
      : null;

  bool contains(ElementType t) => elements.any((e) => e.type == t);
}

class ElementNotifier extends Notifier<ElementState> {
  @override
  ElementState build() => const ElementState();

  void setAll(List<LockElement> els) => state = state.copyWith(
        elements: els,
        activeType: els.isNotEmpty ? els.last.type : ElementType.swipeUpUnlock,
      );

  void add(LockElement el) {
    if (state.contains(el.type)) return;
    state =
        state.copyWith(elements: [...state.elements, el], activeType: el.type);
  }

  void remove(ElementType t) {
    final updated = state.elements.where((e) => e.type != t).toList();
    state = state.copyWith(
      elements: updated,
      activeType:
          updated.isNotEmpty ? updated.last.type : ElementType.swipeUpUnlock,
    );
  }

  /// Clears guide lines on EVERY element in one state update.
  /// Called at the start of every drag so only one element ever shows guides.
  void clearAllGuideLines() {
    state = state.copyWith(
      elements: state.elements
          .map((e) => e.showGuideLines ? e.copyWith(showGuideLines: false) : e)
          .toList(),
    );
  }

  void setActive(ElementType t) =>
      state = state.copyWith(activeType: t, hasSelection: true);

  void deselect() => state = state.copyWith(hasSelection: false);
  void setBgAlpha(double v) => state = state.copyWith(bgAlpha: v);

  void update(ElementType t, LockElement Function(LockElement) fn) =>
      state = state.copyWith(
        elements: state.elements.map((e) => e.type == t ? fn(e) : e).toList(),
      );

  void moveElement(ElementType t, double dx, double dy) =>
      update(t, (e) => e.copyWith(dx: e.dx + dx, dy: e.dy + dy));

  void setPosition(ElementType t, double dx, double dy) =>
      update(t, (e) => e.copyWith(dx: dx, dy: dy));

  void setColor(ElementType t, Color c) =>
      update(t, (e) => e.copyWith(color: c));
  void setColorSecondary(ElementType t, Color c) =>
      update(t, (e) => e.copyWith(colorSecondary: c));
  void setGradStart(ElementType t, AlignmentGeometry a) =>
      update(t, (e) => e.copyWith(gradStartAlign: a));
  void setGradEnd(ElementType t, AlignmentGeometry a) =>
      update(t, (e) => e.copyWith(gradEndAlign: a));
  void setScale(ElementType t, double v) =>
      update(t, (e) => e.copyWith(scale: v));
  void setAngle(ElementType t, double v) =>
      update(t, (e) => e.copyWith(angle: v));
  void setFont(ElementType t, String f) =>
      update(t, (e) => e.copyWith(font: f));
  void setFontSize(ElementType t, double v) =>
      update(t, (e) => e.copyWith(fontSize: v));
  void setFontWeight(ElementType t, FontWeight w) =>
      update(t, (e) => e.copyWith(fontWeight: w));
  void setText(ElementType t, String txt) =>
      update(t, (e) => e.copyWith(text: txt));
  void setAlign(ElementType t, AlignmentGeometry a) =>
      update(t, (e) => e.copyWith(align: a));
  void setRadius(ElementType t, double v) =>
      update(t, (e) => e.copyWith(radius: v));
  void setBorderWidth(ElementType t, double v) =>
      update(t, (e) => e.copyWith(borderWidth: v));
  void setBorderColor(ElementType t, Color c) =>
      update(t, (e) => e.copyWith(borderColor: c));
  void setHeight(ElementType t, double v) =>
      update(t, (e) => e.copyWith(height: v));
  void setWidth(ElementType t, double v) =>
      update(t, (e) => e.copyWith(width: v));
  void setIsShort(ElementType t, bool v) =>
      update(t, (e) => e.copyWith(isShort: v));
  void setIsWrap(ElementType t, bool v) =>
      update(t, (e) => e.copyWith(isWrap: v));
  void setGuideLines(ElementType t, bool v) =>
      update(t, (e) => e.copyWith(showGuideLines: v));
  void resetPosition(ElementType t) =>
      update(t, (e) => e.copyWith(dx: 0, dy: 0));
}

final elementProvider =
    NotifierProvider<ElementNotifier, ElementState>(ElementNotifier.new);
