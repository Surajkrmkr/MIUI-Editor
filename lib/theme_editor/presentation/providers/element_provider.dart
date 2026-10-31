import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/element_widget.dart';
import '../../domain/entities/builtin_widget_styles.dart';
import '../../domain/entities/widget_style.dart';

final animationReplayProvider = StateProvider<int>((ref) => 0);
final videoWallpaperRevisionProvider = StateProvider<int>((ref) => 0);

const clockFontTypes = {
  ElementType.hourClock,
  ElementType.minClock,
  ElementType.secClock,
};

// Clock text paints a color -> colorSecondary gradient, so a primary pick
// also sets the secondary to keep the glyphs one solid color.
const _gradientTextTypes = {
  ElementType.hourClock,
  ElementType.minClock,
  ElementType.secClock,
  ElementType.dotClock,
  ElementType.dotClock2,
  ElementType.amPmClock,
  ElementType.weekClock,
  ElementType.monthClock,
  ElementType.dateClock,
};

LockElement _withPrimary(LockElement e, Color c) =>
    _gradientTextTypes.contains(e.type)
    ? e.copyWith(color: c, colorSecondary: c)
    : e.copyWith(color: c);

class ElementState {
  const ElementState({
    this.elements = const [],
    this.activeType = ElementType.swipeUpUnlock,
    this.activeId = '',
    this.selectedIds = const {},
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
  final String activeId;
  final Set<String> selectedIds;
  bool isSelected(LockElement element) => selectedIds.isNotEmpty
      ? selectedIds.contains(element.name)
      : selectedTypes.contains(element.type);
  final double bgAlpha;
  final bool hasSelection;
  final int undoCount;
  final int redoCount;
  final Set<ElementType> selectedTypes;
  final bool isGroupMode;
  final bool linkHourMinFont;

  bool get canUndo => undoCount > 0;
  bool get canRedo => redoCount > 0;
  bool get hasVisibleUnlock => elements.any(
    (element) =>
        element.isVisible &&
        const {
          ElementType.swipeUpUnlock,
          ElementType.tapToUnlock,
          ElementType.slideToUnlock,
          ElementType.dragToUnlock,
        }.contains(element.type),
  );

  ElementState copyWith({
    List<LockElement>? elements,
    ElementType? activeType,
    String? activeId,
    Set<String>? selectedIds,
    double? bgAlpha,
    bool? hasSelection,
    int? undoCount,
    int? redoCount,
    Set<ElementType>? selectedTypes,
    bool? isGroupMode,
    bool? linkHourMinFont,
  }) => ElementState(
    elements: elements ?? this.elements,
    activeType: activeType ?? this.activeType,
    activeId: activeId ?? this.activeId,
    selectedIds: selectedIds ?? this.selectedIds,
    bgAlpha: bgAlpha ?? this.bgAlpha,
    hasSelection: hasSelection ?? this.hasSelection,
    undoCount: undoCount ?? this.undoCount,
    redoCount: redoCount ?? this.redoCount,
    selectedTypes: selectedTypes ?? this.selectedTypes,
    isGroupMode: isGroupMode ?? this.isGroupMode,
    linkHourMinFont: linkHourMinFont ?? this.linkHourMinFont,
  );

  LockElement? get active => hasSelection
      ? elements
            .where(
              (e) =>
                  e.type == activeType &&
                  (activeId.isEmpty || e.name == activeId),
            )
            .firstOrNull
      : null;

  bool contains(ElementType t) => elements.any((e) => e.type == t);

  /// Returns the layers of an inserted weather or battery preset.
  List<LockElement> infoSetMembers(LockElement element) {
    final owns = isWeatherSetElement(element)
        ? isWeatherSetElement
        : isBatterySetElement(element)
        ? isBatterySetElement
        : null;
    if (owns == null ||
        !elements.any(
          (item) => (item.type.isShape || item.type.isNormalText) && owns(item),
        )) {
      return const [];
    }
    return elements.where(owns).toList();
  }

  /// Layers exposed for editing, with each information set represented once.
  List<LockElement> get editableElements {
    final seen = <String>{};
    final result = <LockElement>[];
    for (final element in elements.reversed) {
      if (!seen.add(element.name)) continue;
      result.add(element);
      seen.addAll(infoSetMembers(element).map((member) => member.name));
    }
    return result.reversed.toList();
  }
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
  bool _matches(LockElement element, ElementType type, {String? id}) {
    if (element.type != type) return false;
    if (!type.isShape &&
        !state.elements.any(
          (item) => item.type == type && item.instanceId.isNotEmpty,
        )) {
      return true;
    }
    final target =
        id ??
        (state.activeType == type && state.activeId.isNotEmpty
            ? state.activeId
            : state.elements
                  .where((element) => element.type == type)
                  .firstOrNull
                  ?.name);
    return element.name == target;
  }

  void _change(
    ElementType t,
    LockElement Function(LockElement) fn, {
    String? id,
  }) {
    final names = _interactionMembers(
      t,
      id: id,
    ).map((element) => element.name).toSet();
    _record();
    state = state.copyWith(
      elements: state.elements
          .map((e) => names.contains(e.name) ? fn(e) : e)
          .toList(),
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  List<LockElement> _interactionMembers(ElementType type, {String? id}) {
    final element = state.elements
        .where((element) => _matches(element, type, id: id))
        .firstOrNull;
    if (element == null) return const [];
    final members = state.infoSetMembers(element);
    return members.isEmpty ? [element] : members;
  }

  // ── Structural mutations (push history) ───────────────────────────────────

  LockElement _uniqueShape(LockElement element, List<LockElement> existing) {
    if (!element.type.isShape ||
        !existing.any((other) => other.name == element.name)) {
      return element;
    }
    var suffix = 2;
    while (existing.any(
      (other) => other.name == '${element.type.name}_$suffix',
    )) {
      suffix++;
    }
    return element.copyWith(instanceId: '$suffix');
  }

  List<LockElement> _normalizeElements(List<LockElement> els) {
    final result = <LockElement>[];
    for (final element in els) {
      result.add(_uniqueShape(element, result));
    }
    return result;
  }

  void setAll(List<LockElement> els) {
    final elements = _normalizeElements(els);
    _record();
    state = state.copyWith(
      elements: elements,
      activeType: elements.isNotEmpty ? elements.last.type : state.activeType,
      activeId: elements.isNotEmpty ? elements.last.name : '',
      selectedIds: const {},
      selectedTypes: const {},
      isGroupMode: false,
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  void add(LockElement el) {
    if (state.contains(el.type) && !el.type.isShape) return;
    el = _uniqueShape(el, state.elements);
    _record();
    state = state.copyWith(
      elements: [...state.elements, el],
      activeType: el.type,
      activeId: el.name,
      hasSelection: true,
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  void addAll(List<LockElement> els) {
    final List<LockElement> updated = [...state.elements];
    for (final el in els) {
      if (el.type.isShape || !updated.any((e) => e.type == el.type)) {
        updated.add(_uniqueShape(el, updated));
      }
    }
    _record();
    state = state.copyWith(
      elements: updated,
      activeType: updated.isNotEmpty ? updated.last.type : state.activeType,
      activeId: updated.isNotEmpty ? updated.last.name : '',
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  void remove(ElementType t, {String? id}) {
    final names = _interactionMembers(
      t,
      id: id,
    ).map((element) => element.name).toSet();
    final updated = state.elements
        .where((e) => !names.contains(e.name))
        .toList();
    _record();
    state = state.copyWith(
      elements: updated,
      activeId: updated.isNotEmpty ? updated.last.name : '',
      activeType: updated.isNotEmpty
          ? updated.last.type
          : ElementType.swipeUpUnlock,
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  /// Removes every element [owns] claims, e.g. a whole clock or battery set.
  void removeElements(bool Function(LockElement element) owns) {
    final updated = state.elements.where((e) => !owns(e)).toList();
    if (updated.length == state.elements.length) return;
    _record();
    state = state.copyWith(
      elements: updated,
      activeId: updated.isNotEmpty ? updated.last.name : '',
      activeType: updated.isNotEmpty
          ? updated.last.type
          : ElementType.swipeUpUnlock,
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  /// Replaces any depth layer with [el], drawn right above the topmost clock
  /// element so the subject covers the clock but not the other widgets.
  void setDepthLayer(LockElement el) {
    final items = state.elements
        .where((e) => e.type != ElementType.depthLayer)
        .toList();
    final lastClock = items.lastIndexWhere((e) => e.type.isClock);
    items.insert(lastClock < 0 ? items.length : lastClock + 1, el);
    _record();
    state = state.copyWith(
      elements: items,
      activeType: el.type,
      activeId: el.name,
      hasSelection: true,
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  void reorder(int oldIndex, int newIndex) {
    final element = state.elements[oldIndex];
    final moving = _interactionMembers(element.type, id: element.name);
    final names = moving.map((member) => member.name).toSet();
    final insertionIndex = state.elements
        .take(newIndex)
        .where((member) => !names.contains(member.name))
        .length;
    final items = state.elements
        .where((member) => !names.contains(member.name))
        .toList();
    items.insertAll(insertionIndex, moving);
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

  void setActive(ElementType t, {String? id}) {
    final element = state.elements
        .where((element) => _matches(element, t, id: id))
        .firstOrNull;
    final members = element == null
        ? <LockElement>[]
        : state.infoSetMembers(element);
    state = state.copyWith(
      activeType: t,
      activeId: id ?? element?.name ?? '',
      selectedIds: members.map((member) => member.name).toSet(),
      hasSelection: true,
    );
  }

  void deselect() => state = state.copyWith(hasSelection: false);
  void setBgAlpha(double v) => state = state.copyWith(bgAlpha: v);
  void toggleLinkHourMinFont() =>
      state = state.copyWith(linkHourMinFont: !state.linkHourMinFont);

  // ── Group select ──────────────────────────────────────────────────────────

  /// Enters group selection mode with [t] as the first selected element.
  void enterGroupMode(ElementType t, {String? id}) {
    final members = _interactionMembers(t, id: id);
    state = state.copyWith(
      isGroupMode: true,
      selectedTypes: members.map((element) => element.type).toSet(),
      selectedIds: members.map((element) => element.name).toSet(),
      hasSelection: false,
    );
  }

  /// Adds [t] to the group if absent, removes it if present.
  /// Exits group mode automatically when the group becomes empty.
  void toggleGroupSelect(ElementType t, {String? id}) {
    final target =
        id ?? state.elements.firstWhere((element) => element.type == t).name;
    final updated = Set<String>.from(
      state.elements.where(state.isSelected).map((element) => element.name),
    );
    final names = _interactionMembers(
      t,
      id: id,
    ).map((element) => element.name).toSet();
    if (updated.contains(target)) {
      updated.removeAll(names);
    } else {
      updated.addAll(names);
    }
    if (updated.isEmpty) {
      state = state.copyWith(
        isGroupMode: false,
        selectedTypes: const {},
        selectedIds: const {},
      );
    } else {
      state = state.copyWith(
        selectedIds: updated,
        selectedTypes: state.elements
            .where((element) => updated.contains(element.name))
            .map((element) => element.type)
            .toSet(),
      );
    }
  }

  /// Exits group selection mode and clears the selection set.
  void exitGroupMode() => state = state.copyWith(
    isGroupMode: false,
    selectedTypes: const {},
    selectedIds: const {},
  );

  /// Moves every unlocked element in [selectedTypes] by ([dx], [dy]) and records history.
  void nudgeGroupElements(double dx, double dy) {
    _record();
    moveGroupElements(dx, dy);
    state = state.copyWith(undoCount: _history.length, redoCount: 0);
  }

  /// Sets the primary color on every element in [selectedTypes] and records history.
  void setGroupColor(Color c) {
    _record();
    var els = state.elements;
    for (final t in state.selectedTypes) {
      els = els
          .map(
            (e) => e.type == t && state.isSelected(e) ? _withPrimary(e, c) : e,
          )
          .toList();
    }
    state = state.copyWith(
      elements: els,
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  /// Sets the secondary color on every element in [selectedTypes] and records history.
  void setGroupColorSecondary(Color c) {
    _record();
    var els = state.elements;
    for (final t in state.selectedTypes) {
      els = els
          .map(
            (e) => e.type == t && state.isSelected(e)
                ? e.copyWith(colorSecondary: c)
                : e,
          )
          .toList();
    }
    state = state.copyWith(
      elements: els,
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  /// Moves every unlocked element in [selectedTypes] by ([dx], [dy]).
  /// No history per frame — call [snapshotForGroupDrag] on drag start.
  void moveGroupElements(double dx, double dy) {
    final blocked = <String>{};
    for (final element in state.elements.where((element) => element.isLocked)) {
      blocked.addAll(
        state.infoSetMembers(element).map((member) => member.name),
      );
    }
    var els = state.elements;
    for (final t in state.selectedTypes) {
      els = els
          .map(
            (e) =>
                e.type == t &&
                    state.isSelected(e) &&
                    !e.isLocked &&
                    !blocked.contains(e.name)
                ? e.copyWith(dx: e.dx + dx, dy: e.dy + dy)
                : e,
          )
          .toList();
    }
    state = state.copyWith(elements: els);
  }

  // update() is the no-history base for continuous/slider operations.
  void centerGroup({required bool horizontal}) {
    final positions = <String, double>{};
    final blocked = <String>{};
    for (final element in state.editableElements) {
      final members = state.infoSetMembers(element);
      if (members.isEmpty) continue;
      if (members.any((member) => member.isLocked)) {
        blocked.addAll(members.map((member) => member.name));
        continue;
      }
      final coordinates =
          members.map((member) => horizontal ? member.dx : member.dy).toList()
            ..sort();
      final center = (coordinates.first + coordinates.last) / 2;
      for (final member in members) {
        positions[member.name] = (horizontal ? member.dx : member.dy) - center;
      }
    }
    _record();
    state = state.copyWith(
      elements: state.elements
          .map(
            (element) =>
                state.isSelected(element) &&
                    !element.isLocked &&
                    !blocked.contains(element.name)
                ? element.copyWith(
                    dx: horizontal ? positions[element.name] ?? 0 : element.dx,
                    dy: horizontal ? element.dy : positions[element.name] ?? 0,
                  )
                : element,
          )
          .toList(),
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  void applyStyle(WidgetStyle style) {
    final element = state.active;
    if (element == null || element.isLocked || element.type != style.type) {
      return;
    }
    final replacement = style.applyTo(element);
    _record();
    state = state.copyWith(
      elements: state.elements
          .map((item) => item.name == element.name ? replacement : item)
          .toList(),
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  void applyClockSet(List<LockElement> clockElements) => applyElementSet(
    clockElements,
    (element) => clockSetElementTypes.contains(element.type),
  );

  /// Swaps the elements [owns] claims (the previous set) for [setElements].
  void applyElementSet(
    List<LockElement> setElements,
    bool Function(LockElement element) owns,
  ) {
    if (setElements.isEmpty) return;
    _record();
    final elements = [
      ...state.elements.where((element) => !owns(element)),
      ...setElements,
    ];
    state = state.copyWith(
      elements: elements,
      activeType: elements.last.type,
      activeId: elements.last.name,
      selectedIds: const {},
      selectedTypes: const {},
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  void _customizeInfoSet(
    LockElement element,
    LockElement Function(LockElement member) customize,
  ) {
    final members = state.infoSetMembers(element);
    if (members.isEmpty || members.any((member) => member.isLocked)) return;
    final names = members.map((member) => member.name).toSet();
    final updated = [
      for (final member in state.elements)
        if (names.contains(member.name)) customize(member) else member,
    ];
    if (Iterable.generate(
      updated.length,
      (index) => identical(updated[index], state.elements[index]),
    ).every((same) => same)) {
      return;
    }
    _record();
    state = state.copyWith(
      elements: updated,
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  /// Updates a set's palette slot, including every matching decorative layer.
  void setInfoSetColor(
    LockElement element,
    Color color, {
    required Set<String> foregroundIds,
    required Set<String> fillIds,
  }) => _customizeInfoSet(element, (member) {
    final foreground = foregroundIds.contains(member.name)
        ? color
        : member.color;
    final fill = fillIds.contains(member.name) ? color : member.colorSecondary;
    return foreground == member.color && fill == member.colorSecondary
        ? member
        : member.copyWith(color: foreground, colorSecondary: fill);
  });

  /// Applies wallpaper colors to a complete set while preserving opacity.
  void applyInfoSetColors(
    LockElement element, {
    required Color text,
    required Color accent,
    required Color background,
    required Color outline,
  }) => _customizeInfoSet(element, (member) {
    final foreground = member.type.isShape
        ? member.effectiveProgressSource != ArcProgressSource.none
              ? accent
              : outline
        : text;
    return member.copyWith(
      color: member.color.a == 0
          ? member.color
          : foreground.withValues(alpha: member.color.a),
      colorSecondary: member.type.isShape && member.colorSecondary.a > 0
          ? background.withValues(alpha: member.colorSecondary.a)
          : member.colorSecondary,
    );
  });

  /// Edits fixed labels together without replacing live battery values.
  void setInfoSetText(LockElement element, Set<String> labelIds, String text) =>
      _customizeInfoSet(
        element,
        (member) =>
            member.type.isNormalText &&
                labelIds.contains(member.name) &&
                member.text != text
            ? member.copyWith(text: text)
            : member,
      );

  /// Resizes a set around its shared center without changing individual styles.
  void scaleElementSet(
    bool Function(LockElement element) owns,
    double scale, {
    bool recordHistory = true,
  }) {
    final members = state.elements.where(owns).toList();
    if (members.isEmpty ||
        members.any((element) => element.isLocked) ||
        !scale.isFinite ||
        scale <= 0 ||
        members.first.scale <= 0) {
      return;
    }
    final factor = scale / members.first.scale;
    if (factor == 1) return;
    var left = members.first.dx;
    var right = left;
    var top = members.first.dy;
    var bottom = top;
    for (final element in members.skip(1)) {
      if (element.dx < left) left = element.dx;
      if (element.dx > right) right = element.dx;
      if (element.dy < top) top = element.dy;
      if (element.dy > bottom) bottom = element.dy;
    }
    final centerX = (left + right) / 2;
    final centerY = (top + bottom) / 2;
    if (recordHistory) _record();
    state = state.copyWith(
      elements: [
        for (final element in state.elements)
          if (owns(element))
            element.copyWith(
              dx: centerX + (element.dx - centerX) * factor,
              dy: centerY + (element.dy - centerY) * factor,
              scale: element.scale * factor,
            )
          else
            element,
      ],
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  void applyClockSetColors({
    required Color color,
    required Color colorSecondary,
    required Color accent,
    required Color borderColor,
  }) {
    _record();
    state = state.copyWith(
      elements: state.elements
          .map(
            (element) =>
                clockSetElementTypes.contains(element.type) && !element.isLocked
                ? element.copyWith(
                    color: color,
                    colorSecondary: _gradientTextTypes.contains(element.type)
                        ? color
                        : colorSecondary,
                    colorDigit1: color,
                    colorDigit2: accent,
                    unlockAccent: accent,
                    borderColor: borderColor,
                  )
                : element,
          )
          .toList(),
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  void update(ElementType t, LockElement Function(LockElement) fn) =>
      state = state.copyWith(
        elements: state.elements
            .map((e) => _matches(e, t) ? fn(e) : e)
            .toList(),
      );

  // High-frequency drag — no history per frame; use snapshotForDrag() on start.
  void moveElement(ElementType t, double dx, double dy) {
    final element = state.elements
        .where((element) => _matches(element, t))
        .firstOrNull;
    final members = element == null
        ? <LockElement>[]
        : state.infoSetMembers(element);
    if (members.isEmpty) {
      update(
        t,
        (element) => element.copyWith(dx: element.dx + dx, dy: element.dy + dy),
      );
      return;
    }
    if (members.any((member) => member.isLocked)) return;
    final names = members.map((member) => member.name).toSet();
    state = state.copyWith(
      elements: [
        for (final element in state.elements)
          if (names.contains(element.name))
            element.copyWith(dx: element.dx + dx, dy: element.dy + dy)
          else
            element,
      ],
    );
  }

  // Continuous / slider ops — no per-change history.
  void setPosition(ElementType t, double dx, double dy) {
    final element = state.elements
        .where((element) => _matches(element, t))
        .firstOrNull;
    if (element == null) return;
    moveElement(t, dx - element.dx, dy - element.dy);
  }

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
  void setBlurRadius(ElementType t, double v) =>
      update(t, (e) => e.copyWith(blurRadius: v));
  void setStrokeWidth(ElementType t, double v) =>
      update(t, (e) => e.copyWith(strokeWidth: v));
  void setGuideLines(ElementType t, bool v) =>
      update(t, (e) => e.copyWith(showGuideLines: v));

  // ── Discrete property mutations (push history) ────────────────────────────

  void setColor(ElementType t, Color c) =>
      _change(t, (e) => _withPrimary(e, c));
  void setColorSecondary(ElementType t, Color c) =>
      _change(t, (e) => e.copyWith(colorSecondary: c));
  void setColorDigit1(ElementType t, Color c) =>
      _change(t, (e) => e.copyWith(colorDigit1: c));
  void setColorDigit2(ElementType t, Color c) =>
      _change(t, (e) => e.copyWith(colorDigit2: c));
  void setStrokeColor(ElementType t, Color c) =>
      _change(t, (e) => e.copyWith(strokeColor: c));
  void setStrokeColorDigit1(ElementType t, Color c) =>
      _change(t, (e) => e.copyWith(strokeColorDigit1: c));
  void setStrokeColorDigit2(ElementType t, Color c) =>
      _change(t, (e) => e.copyWith(strokeColorDigit2: c));
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
  void toggleVisibility(ElementType t, {String? id}) {
    final visible = _interactionMembers(
      t,
      id: id,
    ).any((element) => element.isVisible);
    _change(t, (element) => element.copyWith(isVisible: !visible), id: id);
  }

  void setLocked(ElementType t, bool v) =>
      _change(t, (e) => e.copyWith(isLocked: v));
  void toggleLock(ElementType t, {String? id}) {
    final locked = _interactionMembers(
      t,
      id: id,
    ).any((element) => element.isLocked);
    _change(t, (element) => element.copyWith(isLocked: !locked), id: id);
  }

  void setUseSeparateColors(ElementType t, bool v) =>
      _change(t, (e) => e.copyWith(useSeparateColors: v));
  void updateSurfaceFx(ElementType t, LockElement Function(LockElement) f) =>
      _change(t, f);

  /// Tilts every clock text element alike, so they read as one surface.
  void setPerspectiveTilt(double v) {
    _record();
    state = state.copyWith(
      elements: [
        for (final e in state.elements)
          _gradientTextTypes.contains(e.type)
              ? e.copyWith(perspectiveTilt: v)
              : e,
      ],
      undoCount: _history.length,
      redoCount: 0,
    );
  }

  void resetPosition(ElementType t) =>
      _centerElement(t, horizontal: true, vertical: true);
  void centerHorizontal(ElementType t) => _centerElement(t, horizontal: true);
  void centerVertical(ElementType t) => _centerElement(t, vertical: true);

  void _centerElement(
    ElementType type, {
    bool horizontal = false,
    bool vertical = false,
  }) {
    final members = _interactionMembers(type);
    if (members.isEmpty) return;
    if (state.infoSetMembers(members.first).isEmpty) {
      _change(
        type,
        (element) => element.copyWith(
          dx: horizontal ? 0 : element.dx,
          dy: vertical ? 0 : element.dy,
        ),
      );
      return;
    }
    if (members.any((member) => member.isLocked)) return;
    final xs = members.map((member) => member.dx).toList()..sort();
    final ys = members.map((member) => member.dy).toList()..sort();
    snapshotForDrag();
    moveElement(
      type,
      horizontal ? -(xs.first + xs.last) / 2 : 0,
      vertical ? -(ys.first + ys.last) / 2 : 0,
    );
  }

  /// Sets font on multiple elements in a single history entry (e.g. hour+min link).
  void applyFont(String font) {
    final type = state.activeType;
    setFontBatch({
      type: font,
      if (state.linkHourMinFont && clockFontTypes.contains(type))
        for (final clock in clockFontTypes) clock: font,
    });
  }

  void setFontBatch(Map<ElementType, String> fonts) {
    final supportedFonts = fonts.entries.where(
      (entry) => entry.key.supportsCustomFont,
    );
    if (supportedFonts.isEmpty) return;
    _record();
    var els = state.elements;
    for (final entry in supportedFonts) {
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

final elementProvider = NotifierProvider<ElementNotifier, ElementState>(
  ElementNotifier.new,
);
