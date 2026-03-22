import '../../core/errors/failures.dart';
import '../../domain/entities/element_widget.dart';

abstract interface class AiRepository {
  Future<(List<LockElement>?, Failure?)> generateLockscreen({
    required List<LockElement> currentElements,
    required String prompt,
  });
}
