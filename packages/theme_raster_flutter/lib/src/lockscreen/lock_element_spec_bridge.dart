import 'package:theme_core/theme_core.dart';
import 'lock_element.dart';

/// Cache: elements are immutable and painters ask for the spec on every paint.
final _specs = Expando<LockElementSpec>('LockElementSpec');

/// Converts between the editor's Flutter-typed [LockElement] and the pure
/// [LockElementSpec]; the shared JSON is the contract, so no field list is
/// duplicated here.
extension LockElementSpecBridge on LockElement {
  LockElementSpec toSpec() =>
      _specs[this] ??= LockElementSpec.fromJson(toJson());
}

extension LockElementFromSpec on LockElementSpec {
  LockElement toLockElement() => LockElement.fromJson(toJson());
}
