import 'package:fitora/features/home/domain/home_dashboard_models.dart';
import 'package:fitora/features/home/domain/home_dashboard_repository.dart';

class MockHomeDashboardRepository implements HomeDashboardRepository {
  @override
  Future<HomeDashboardData> fetchDashboard() async {
    return HomeDashboardData.sample();
  }
}
