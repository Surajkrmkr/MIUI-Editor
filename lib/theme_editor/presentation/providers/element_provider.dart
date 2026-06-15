import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/element_widget.dart';

class ElementState {
  const ElementState({
    this.elements = const [],
    this.activeType = ElementType.swipeUpUnlock,
    this.bgAlpha = 0.0,
    this.hasSelection = false,
    this.undoCount = 0,
    this.redoCount = 0,
    this.selectedTypes = const {},
    this.isGroupMode = false,
    this.linkHourMinFont = true,
  });

  final List<LockElement> elements;
  final ElementType activeType;
  final double bgAlpha;
  final bool hasSelection;
  final int undoCount;
  final int redoCount;
  final Set<ElementType> selectedTypes;
  final bool isGroupMode;
  final bool linkHourMinFont;

  bool get canUndo => undoCount > 0;
  bool get canRedo => redoCount > 0;

  ElementState copyWith({
    List<LockElement>? elements,
    ElementType? activeType,
    double? bgAlpha,
    bool? hasSelection,
    int? undoCount,
    int? redoCount,
    Set<ElementType>? selectedTypes,
    bool? isGroupMode,
    bool? linkHourMinFont,
  }) =>
      ElementState(
        elements: elements ?? this.elements,
        activeType: activeType ?? this.activeType,
        bgAlpha: bgAlpha ?? this.bgAlpha,
        hasSelection: hasSelection ?? this.hasSelection,
        undoCount: undoCount ?? this.undoCount,
        redoCount: redoCount ?? this.redoCount,
        selectedTypes: selectedTypes ?? this.selectedTypes,
        isGroupMode: isGroupMode ?? this.isGroupMode,
        linkHourMinFont: linkHourMinFont ?? this.linkHourMinFont,
      );

  LockElement? get active => hasSelection
      ? elements.where((e) => e.type == activeType).firstOrNull
      : null;

  bool contains(ElementType t) => elements.any((e) => e.type == t);
}

class ElementNotifier extends Notifier<ElementState> {
  final List<ElementState> _history = [];
  final List<ElementState> _future = [];
  static const _maxHistory = 50;

  @override
  ElementState build() => const ElementState();

  // ── History helpers ───────────────────────────────────────────────────────

  void _record() {
    _future.clear();
    _history.add(state.copyWith(undoCount: 0, redoCount: 0));
    if (_history.length > _maxHistory) _history.removeAt(0);
  }

  /// Records a snapshot at drag start so [moveElement] calls don't flood history.
  void snapshotForDrag() {
    _record();
    state = state.copyWith(undoCount: _history.length, redoCount: 0);
  }

  /// Records a snapshot at group drag start.
  void snapshotForGroupDrag() {
    _record();
    state = state.copyWith(undoCount: _history.length, redoCount: 0);
  }

  void undo() {
    if (_history.isEmpty) return;
    _future.add(state.copyWith(undoCount: 0, redoCount: 0));
    state = _history.removeLast().copyWith(
      undoCount: _history.length,
      redoCount: _future.length,
    );
  }

  void redo() {
    if (_future.isEmpty) return;
    _history.add(state.copyWith(undoCount: 0, redoCount: 0));
    state = _future.removeLast().copyWith(
      undoCount: _history.length,
      redoCount: _future.length,
    );
  }

  // _change: single-element mutation that pushes history.
  void _change(ElementType t, LockElement Function(LockElement) fn) {
    _record();
    state = state.copyWith(
      elements: state.elements.map((e) => e.type == t ? fn(e) : e).toList(),
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  // ── Structural mutations (push history) ───────────────────────────────────

  void setAll(List<LockElement> els) {
    _record();
    state = state.copyWith(
      elements: els,
      activeType: els.isNotEmpty ? els.last.type : ElementType.swipeUpUnlock,
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  void add(LockElement el) {
    if (state.contains(el.type)) return;
    _record();
    state = state.copyWith(
      elements: [...state.elements, el],
      activeType: el.type,
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  void addAll(List<LockElement> els) {
    final List<LockElement> updated = [...state.elements];
    for (final el in els) {
      if (!updated.any((e) => e.type == el.type)) updated.add(el);
    }
    _record();
    state = state.copyWith(
      elements: updated,
      activeType: updated.isNotEmpty ? updated.last.type : state.activeType,
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  void remove(ElementType t) {
    final updated = state.elements.where((e) => e.type != t).toList();
    _record();
    state = state.copyWith(
      elements: updated,
      activeType:
          updated.isNotEmpty ? updated.last.type : ElementType.swipeUpUnlock,
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final items = [...state.elements];
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    _record();
    state = state.copyWith(
      elements: items,
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  // ── Non-history mutations (selection, guide lines, continuous ops) ─────────

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
  void toggleLinkHourMinFont() =>
      state = state.copyWith(linkHourMinFont: !state.linkHourMinFont);

  // ── Group select ──────────────────────────────────────────────────────────

  /// Enters group selection mode with [t] as the first selected element.
  void enterGroupMode(ElementType t) {
    state = state.copyWith(
      isGroupMode: true,
      selectedTypes: {t},
      hasSelection: false,
    );
  }

  /// Adds [t] to the group if absent, removes it if present.
  /// Exits group mode automatically when the group becomes empty.
  void toggleGroupSelect(ElementType t) {
    final updated = Set<ElementType>.from(state.selectedTypes);
    if (updated.contains(t)) {
      updated.remove(t);
    } else {
      updated.add(t);
    }
    if (updated.isEmpty) {
      state = state.copyWith(isGroupMode: false, selectedTypes: const {});
    } else {
      state = state.copyWith(selectedTypes: updated);
    }
  }

  /// Exits group selection mode and clears the selection set.
  void exitGroupMode() =>
      state = state.copyWith(isGroupMode: false, selectedTypes: const {});

  /// Moves every unlocked element in [selectedTypes] by ([dx], [dy]) and records history.
  void nudgeGroupElements(double dx, double dy) {
    _record();
    var els = state.elements;
    for (final t in state.selectedTypes) {
      els = els
          .map((e) => e.type == t && !e.isLocked ? e.copyWith(dx: e.dx + dx, dy: e.dy + dy) : e)
          .toList();
    }
    state = state.copyWith(elements: els, undoCount: _history.length, redoCount: 0);
  }

  /// Sets the primary color on every element in [selectedTypes] and records history.
  void setGroupColor(Color c) {
    _record();
    var els = state.elements;
    for (final t in state.selectedTypes) {
      els = els.map((e) => e.type == t ? e.copyWith(color: c) : e).toList();
    }
    state = state.copyWith(elements: els, undoCount: _history.length, redoCount: 0);
  }

  /// Sets the secondary color on every element in [selectedTypes] and records history.
  void setGroupColorSecondary(Color c) {
    _record();
    var els = state.elements;
    for (final t in state.selectedTypes) {
      els = els.map((e) => e.type == t ? e.copyWith(colorSecondary: c) : e).toList();
    }
    state = state.copyWith(elements: els, undoCount: _history.length, redoCount: 0);
  }

  /// Moves every unlocked element in [selectedTypes] by ([dx], [dy]).
  /// No history per frame — call [snapshotForGroupDrag] on drag start.
  void moveGroupElements(double dx, double dy) {
    var els = state.elements;
    for (final t in state.selectedTypes) {
      els = els
          .map((e) =>
              e.type == t && !e.isLocked ? e.copyWith(dx: e.dx + dx, dy: e.dy + dy) : e)
          .toList();
    }
    state = state.copyWith(elements: els);
  }

  // update() is the no-history base for continuous/slider operations.
  void update(ElementType t, LockElement Function(LockElement) fn) =>
      state = state.copyWith(
        elements: state.elements.map((e) => e.type == t ? fn(e) : e).toList(),
      );

  // High-frequency drag — no history per frame; use snapshotForDrag() on start.
  void moveElement(ElementType t, double dx, double dy) =>
      update(t, (e) => e.copyWith(dx: e.dx + dx, dy: e.dy + dy));

  // Continuous / slider ops — no per-change history.
  void setPosition(ElementType t, double dx, double dy) =>
      update(t, (e) => e.copyWith(dx: dx, dy: dy));
  void setScale(ElementType t, double v) =>
      update(t, (e) => e.copyWith(scale: v));
  void setAngle(ElementType t, double v) =>
      update(t, (e) => e.copyWith(angle: v));
  void setFontSize(ElementType t, double v) =>
      update(t, (e) => e.copyWith(fontSize: v));
  void setRadius(ElementType t, double v) =>
      update(t, (e) => e.copyWith(radius: v));
  void setBorderWidth(ElementType t, double v) =>
      update(t, (e) => e.copyWith(borderWidth: v));
  void setHeight(ElementType t, double v) =>
      update(t, (e) => e.copyWith(height: v));
  void setWidth(ElementType t, double v) =>
      update(t, (e) => e.copyWith(width: v));
  void setGuideLines(ElementType t, bool v) =>
      update(t, (e) => e.copyWith(showGuideLines: v));

  // ── Discrete property mutations (push history) ────────────────────────────

  void setColor(ElementType t, Color c) =>
      _change(t, (e) => e.copyWith(color: c));
  void setColorSecondary(ElementType t, Color c) =>
      _change(t, (e) => e.copyWith(colorSecondary: c));
  void setColorDigit1(ElementType t, Color c) =>
      _change(t, (e) => e.copyWith(colorDigit1: c));
  void setColorDigit2(ElementType t, Color c) =>
      _change(t, (e) => e.copyWith(colorDigit2: c));
  void setBorderColor(ElementType t, Color c) =>
      _change(t, (e) => e.copyWith(borderColor: c));
  void setGradStart(ElementType t, AlignmentGeometry a) =>
      _change(t, (e) => e.copyWith(gradStartAlign: a));
  void setGradEnd(ElementType t, AlignmentGeometry a) =>
      _change(t, (e) => e.copyWith(gradEndAlign: a));
  void setFont(ElementType t, String f) =>
      _change(t, (e) => e.copyWith(font: f));
  void setFontWeight(ElementType t, FontWeight w) =>
      _change(t, (e) => e.copyWith(fontWeight: w));
  void setText(ElementType t, String txt) =>
      _change(t, (e) => e.copyWith(text: txt));
  void setAlign(ElementType t, AlignmentGeometry a) =>
      _change(t, (e) => e.copyWith(align: a));
  void setIsShort(ElementType t, bool v) =>
      _change(t, (e) => e.copyWith(isShort: v));
  void setIsWrap(ElementType t, bool v) =>
      _change(t, (e) => e.copyWith(isWrap: v));
  void setVisible(ElementType t, bool v) =>
      _change(t, (e) => e.copyWith(isVisible: v));
  void toggleVisibility(ElementType t) =>
      _change(t, (e) => e.copyWith(isVisible: !e.isVisible));
  void setLocked(ElementType t, bool v) =>
      _change(t, (e) => e.copyWith(isLocked: v));
  void toggleLock(ElementType t) =>
      _change(t, (e) => e.copyWith(isLocked: !e.isLocked));
  void setUseSeparateColors(ElementType t, bool v) =>
      _change(t, (e) => e.copyWith(useSeparateColors: v));
  void resetPosition(ElementType t) =>
      _change(t, (e) => e.copyWith(dx: 0, dy: 0));
  void centerHorizontal(ElementType t) =>
      _change(t, (e) => e.copyWith(dx: 0));
  void centerVertical(ElementType t) =>
      _change(t, (e) => e.copyWith(dy: 0));

  /// Sets font on multiple elements in a single history entry (e.g. hour+min link).
  void setFontBatch(Map<ElementType, String> fonts) {
    _record();
    var els = state.elements;
    for (final entry in fonts.entries) {
      els = els
          .map((e) => e.type == entry.key ? e.copyWith(font: entry.value) : e)
          .toList();
    }
    state = state.copyWith(
      elements: els,
      undoCount: _history.length,
      redoCount: 0,
    );
  }
}

final elementProvider =
    NotifierProvider<ElementNotifier, ElementState>(ElementNotifier.new);
