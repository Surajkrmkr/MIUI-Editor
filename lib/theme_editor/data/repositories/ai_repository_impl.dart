import '../../core/errors/failures.dart';
import '../../data/datasources/remote/ai_remote_datasource.dart';
import '../../domain/entities/element_widget.dart';
import '../../domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  const AiRepositoryImpl(this._ds);
  final AiRemoteDataSource _ds;

  @override
  Future<(List<LockElement>?, Failure?)> generateLockscreen({
    required List<LockElement> currentElements,
    required String prompt,
  }) async {
    try {
      final result = await _ds.generateLockscreen(
        currentElements: currentElements,
        prompt: prompt,
      );
      return (result, null);
    } catch (e) {
      return (null, AiFailure(e.toString()));
    }
  }
}
