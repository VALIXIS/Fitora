import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/app/router/app_routes.dart';
import 'package:fitora/features/onboarding/data/onboarding_local_data_source.dart';
import 'package:fitora/features/onboarding/domain/onboarding_models.dart';

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingViewState>((ref) {
  final dataSource = ref.read(onboardingLocalDataSourceProvider);
  return OnboardingController(dataSource);
});

class OnboardingViewState {
  final int pageIndex;
  final bool isCompleted;
  final bool isLoading;
  final List<OnboardingPageData> pages;

  const OnboardingViewState({
    required this.pageIndex,
    required this.isCompleted,
    required this.isLoading,
    required this.pages,
  });

  factory OnboardingViewState.initial() {
    return const OnboardingViewState(
      pageIndex: 0,
      isCompleted: false,
      isLoading: true,
      pages: OnboardingPages.items,
    );
  }

  OnboardingViewState copyWith({
    int? pageIndex,
    bool? isCompleted,
    bool? isLoading,
    List<OnboardingPageData>? pages,
  }) {
    return OnboardingViewState(
      pageIndex: pageIndex ?? this.pageIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      pages: pages ?? this.pages,
    );
  }

  bool get isLastPage => pageIndex >= pages.length - 1;
}

class OnboardingController extends StateNotifier<OnboardingViewState> {
  final OnboardingLocalDataSource _dataSource;
  late final Future<void> _loadFuture;

  OnboardingController(this._dataSource) : super(OnboardingViewState.initial()) {
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final completed = await _dataSource.isCompleted();
    state = state.copyWith(isCompleted: completed, isLoading: false);
  }

  Future<void> ensureLoaded() => _loadFuture;

  void setPage(int index) {
    if (index == state.pageIndex) {
      return;
    }
    state = state.copyWith(pageIndex: index);
  }

  void skipToLastPage() {
    setPage(state.pages.length - 1);
  }

  Future<void> completeOnboarding() async {
    await _dataSource.setCompleted(true);
    state = state.copyWith(isCompleted: true);
  }

  Future<String> resolveNextRoute() async {
    await ensureLoaded();
    return state.isCompleted ? AppRoutes.home : AppRoutes.onboarding;
  }
}
