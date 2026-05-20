import 'package:fitora/features/home/domain/home_dashboard_models.dart';

abstract class HomeDashboardRepository {
  Future<HomeDashboardData> fetchDashboard();
}
