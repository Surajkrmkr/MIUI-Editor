import '../../core/errors/failures.dart';
import '../entities/element_widget.dart';
import '../entities/widget_style.dart';
import '../repositories/widget_style_repository.dart';

class ManageWidgetStylesUseCase {
  const ManageWidgetStylesUseCase(this.repository);
  final WidgetStyleRepository repository;

  Future<(WidgetStyleSet?, Failure?)> saveCurrent({
    required LockElement element,
    required String name,
    WidgetStyleSet? set,
    String setName = 'Personal',
  }) async {
    try {
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final style = WidgetStyle.capture(
        id: 'style-$timestamp',
        name: name.trim(),
        element: element,
      );
      final targetName = set?.name ?? setName.trim();
      final target = WidgetStyleSet(
        id:
            set?.id ??
            (targetName == 'Personal' ? 'personal' : 'set-$timestamp'),
        name: targetName,
        styles: [...?set?.styles, style],
      );
      final failure = await repository.save(target);
      return failure == null ? (target, null) : (null, failure);
    } catch (error) {
      return (null, ValidationFailure(error.toString()));
    }
  }

  Future<(List<WidgetStyleSet>, Failure?)> load() => repository.load();
  Future<(WidgetStyleSet?, Failure?)> importSet(String path) =>
      repository.importSet(path);
  Future<Failure?> exportSet(WidgetStyleSet set, String path) =>
      repository.exportSet(set, path);
  Future<Failure?> delete(String id) => repository.delete(id);
}
