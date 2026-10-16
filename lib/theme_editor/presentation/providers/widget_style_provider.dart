import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../core/constants/path_constants.dart';
import '../../data/repositories/widget_style_repository_impl.dart';
import '../../domain/entities/widget_style.dart';
import '../../domain/repositories/widget_style_repository.dart';
import '../../domain/usecases/manage_widget_styles_usecase.dart';

final widgetStyleRepositoryProvider = Provider<WidgetStyleRepository>(
  (ref) => WidgetStyleRepositoryImpl(
    path.join(PathConstants.basePath, 'WidgetStyles'),
  ),
);

final manageWidgetStylesProvider = Provider<ManageWidgetStylesUseCase>(
  (ref) => ManageWidgetStylesUseCase(ref.watch(widgetStyleRepositoryProvider)),
);

final widgetStyleSetsProvider = FutureProvider<List<WidgetStyleSet>>((
  ref,
) async {
  final (sets, failure) = await ref.watch(manageWidgetStylesProvider).load();
  if (failure != null) throw Exception(failure.message);
  return sets;
});
