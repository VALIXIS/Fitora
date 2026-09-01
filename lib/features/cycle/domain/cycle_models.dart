
enum FlowLevel {
  light,
  medium,
  heavy
}

extension FlowLevelExtension on FlowLevel {
  String get displayName {
    switch (this) {
      case FlowLevel.light: return 'Light';
      case FlowLevel.medium: return 'Medium';
      case FlowLevel.heavy: return 'Heavy';
    }
  }
}

enum CycleSymptom {
  cramps,
  headache,
  moodChanges,
  lowEnergy,
  highEnergy,
  bloating,
  breastTenderness,
  backPain,
  acne,
  appetiteChanges
}

extension CycleSymptomExtension on CycleSymptom {
  String get displayName {
    switch (this) {
      case CycleSymptom.cramps: return 'Cramps';
      case CycleSymptom.headache: return 'Headache';
      case CycleSymptom.moodChanges: return 'Mood Changes';
      case CycleSymptom.lowEnergy: return 'Low Energy';
      case CycleSymptom.highEnergy: return 'High Energy';
      case CycleSymptom.bloating: return 'Bloating';
      case CycleSymptom.breastTenderness: return 'Breast Tenderness';
      case CycleSymptom.backPain: return 'Back Pain';
      case CycleSymptom.acne: return 'Acne';
      case CycleSymptom.appetiteChanges: return 'Appetite Changes';
    }
  }
}

DateTime parseLocalDate(String str) {
  final parts = str.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

String formatLocalDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class PeriodRange {
  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;

  const PeriodRange({
    required this.id,
    required this.startDate,
    this.endDate,
    this.notes,
  });

  bool get isOngoing => endDate == null;

  int get durationDays {
    if (endDate == null) {
      final now = DateTime.now();
      final localToday = DateTime(now.year, now.month, now.day);
      if (localToday.isBefore(startDate)) return 1;
      return localToday.difference(startDate).inDays + 1;
    }
    return endDate!.difference(startDate).inDays + 1;
  }

  PeriodRange copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
  }) {
    return PeriodRange(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startDate': formatLocalDate(startDate),
      'endDate': endDate != null ? formatLocalDate(endDate!) : null,
      'notes': notes,
    };
  }

  factory PeriodRange.fromJson(Map<String, dynamic> json) {
    return PeriodRange(
      id: json['id'] as String,
      startDate: parseLocalDate(json['startDate'] as String),
      endDate: json['endDate'] != null ? parseLocalDate(json['endDate'] as String) : null,
      notes: json['notes'] as String?,
    );
  }
}

class PeriodDayData {
  final DateTime date;
  final FlowLevel? flow;
  final List<CycleSymptom> symptoms;
  final String? notes;

  const PeriodDayData({
    required this.date,
    this.flow,
    this.symptoms = const [],
    this.notes,
  });

  bool get isEmpty => flow == null && symptoms.isEmpty && (notes == null || notes!.isEmpty);

  PeriodDayData copyWith({
    DateTime? date,
    FlowLevel? flow,
    List<CycleSymptom>? symptoms,
    String? notes,
  }) {
    return PeriodDayData(
      date: date ?? this.date,
      flow: flow,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': formatLocalDate(date),
      'flow': flow?.name,
      'symptoms': symptoms.map((s) => s.name).toList(),
      'notes': notes,
    };
  }

  factory PeriodDayData.fromJson(Map<String, dynamic> json) {
    return PeriodDayData(
      date: parseLocalDate(json['date'] as String),
      flow: json['flow'] != null ? FlowLevel.values.byName(json['flow'] as String) : null,
      symptoms: (json['symptoms'] as List<dynamic>?)
              ?.map((s) => CycleSymptom.values.byName(s as String))
              .toList() ??
          [],
      notes: json['notes'] as String?,
    );
  }
}

class CycleRecord {
  final DateTime startDate;
  final DateTime endDate;
  final int cycleLength;
  final int periodDuration;

  const CycleRecord({
    required this.startDate,
    required this.endDate,
    required this.cycleLength,
    required this.periodDuration,
  });
}

class CycleStats {
  final double averageCycleLength;
  final double averagePeriodDuration;
  final int shortestCycle;
  final int longestCycle;
  final double cycleVariability;
  final int completedIntervalsCount;

  const CycleStats({
    required this.averageCycleLength,
    required this.averagePeriodDuration,
    required this.shortestCycle,
    required this.longestCycle,
    required this.cycleVariability,
    required this.completedIntervalsCount,
  });

  factory CycleStats.empty() {
    return const CycleStats(
      averageCycleLength: 0.0,
      averagePeriodDuration: 0.0,
      shortestCycle: 0,
      longestCycle: 0,
      cycleVariability: 0.0,
      completedIntervalsCount: 0,
    );
  }
}
