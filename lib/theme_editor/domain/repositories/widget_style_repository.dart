import '../../core/errors/failures.dart';
import '../entities/widget_style.dart';

abstract interface class WidgetStyleRepository {
  Future<(List<WidgetStyleSet>, Failure?)> load();
  Future<Failure?> save(WidgetStyleSet set);
  Future<Failure?> delete(String id);
  Future<(WidgetStyleSet?, Failure?)> importSet(String path);
  Future<Failure?> exportSet(WidgetStyleSet set, String path);
}
