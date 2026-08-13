import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitora/features/home/data/mock_home_dashboard_repository.dart';
import 'package:fitora/features/home/domain/home_dashboard_models.dart';
import 'package:fitora/features/home/domain/home_dashboard_repository.dart';

final homeDashboardRepositoryProvider = Provider<HomeDashboardRepository>((
  ref,
) {
  return MockHomeDashboardRepository();
});

final homeDashboardProvider = FutureProvider<HomeDashboardData>((ref) async {
  final repository = ref.read(homeDashboardRepositoryProvider);
  return repository.fetchDashboard();
});
