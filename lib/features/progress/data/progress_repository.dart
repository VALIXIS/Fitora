import 'package:fitora/features/progress/data/progress_local_data_source.dart';
import 'package:fitora/features/progress/domain/progress_models.dart';

abstract class ProgressRepository {
  Future<List<WorkoutHistoryEntry>> fetchHistory();
  Future<void> saveHistory(List<WorkoutHistoryEntry> history);
}

class LocalProgressRepository implements ProgressRepository {
  final ProgressLocalDataSource _localDataSource;

  LocalProgressRepository(this._localDataSource);

  @override
  Future<List<WorkoutHistoryEntry>> fetchHistory() {
    return _localDataSource.fetchHistory();
  }

  @override
  Future<void> saveHistory(List<WorkoutHistoryEntry> history) {
    return _localDataSource.saveHistory(history);
  }
}
