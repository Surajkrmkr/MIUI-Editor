import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/pixabay_remote_datasource.dart';
import '../../data/models/pixabay_model.dart';

class PickWallState {
  const PickWallState({
    this.hits = const [],
    this.isLoading = false,
    this.search = '',
    this.imageType = PixabayImageType.illustration,
    this.page = 1,
  });

  final List<PixabayHit> hits;
  final bool isLoading;
  final String search;
  final PixabayImageType imageType;
  final int page;

  PickWallState copyWith({
    List<PixabayHit>? hits, bool? isLoading,
    String? search, PixabayImageType? imageType, int? page,
  }) => PickWallState(
    hits: hits ?? this.hits,
    isLoading: isLoading ?? this.isLoading,
    search: search ?? this.search,
    imageType: imageType ?? this.imageType,
    page: page ?? this.page,
  );
}

class PickWallNotifier extends Notifier<PickWallState> {
  final _ds = PixabayRemoteDataSource();

  @override
  PickWallState build() => const PickWallState();

  Future<void> fetch({String? search, PixabayImageType? type, int? page}) async {
    final s = search ?? state.search;
    final t = type ?? state.imageType;
    final p = page ?? state.page;
    state = state.copyWith(isLoading: true, search: s, imageType: t, page: p);
    try {
      final result = await _ds.search(query: s, type: t, page: p);
      state = state.copyWith(hits: result.hits, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void nextPage() => fetch(page: state.page + 1);
  void prevPage() { if (state.page > 1) fetch(page: state.page - 1); }
  void setType(PixabayImageType t) => fetch(type: t, page: 1);
  void setSearch(String s) => fetch(search: s, page: 1);
}

final pickWallProvider =
    NotifierProvider<PickWallNotifier, PickWallState>(PickWallNotifier.new);
