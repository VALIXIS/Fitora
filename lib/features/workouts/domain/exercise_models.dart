enum TargetMuscle {
  fullBody,
  upperBody,
  lowerBody,
  core,
  cardio,
  mobility,
  recovery,
}

extension TargetMuscleX on TargetMuscle {
  String get label {
    switch (this) {
      case TargetMuscle.fullBody:
        return 'Full body';
      case TargetMuscle.upperBody:
        return 'Upper body';
      case TargetMuscle.lowerBody:
        return 'Lower body';
      case TargetMuscle.core:
        return 'Core';
      case TargetMuscle.cardio:
        return 'Cardio';
      case TargetMuscle.mobility:
        return 'Mobility';
      case TargetMuscle.recovery:
        return 'Recovery';
    }
  }
}

enum Equipment {
  none,
  mat,
  chair,
  dumbbells,
  resistanceBand,
  kettlebell,
  barbell,
  machine,
  bench,
}

extension EquipmentX on Equipment {
  String get label {
    switch (this) {
      case Equipment.none:
        return 'No equipment';
      case Equipment.mat:
        return 'Mat';
      case Equipment.chair:
        return 'Chair';
      case Equipment.dumbbells:
        return 'Dumbbells';
      case Equipment.resistanceBand:
        return 'Resistance band';
      case Equipment.kettlebell:
        return 'Kettlebell';
      case Equipment.barbell:
        return 'Barbell';
      case Equipment.machine:
        return 'Machine';
      case Equipment.bench:
        return 'Bench';
    }
  }
}

class ExerciseDose {
  final int? sets;
  final int? reps;
  final Duration? duration;
  final Duration? rest;

  const ExerciseDose({
    this.sets,
    this.reps,
    this.duration,
    this.rest,
  });

  String get summary {
    final parts = <String>[];
    if (sets != null) {
      parts.add('$sets sets');
    }
    if (reps != null) {
      parts.add('$reps reps');
    }
    if (duration != null) {
      parts.add(_formatDuration(duration!));
    }
    if (rest != null) {
      parts.add('Rest ${_formatDuration(rest!)}');
    }
    return parts.isEmpty ? 'At your pace' : parts.join(' · ');
  }
}

class Exercise {
  final String id;
  final String title;
  final List<String> instructions;
  final ExerciseDose dose;
  final TargetMuscle targetMuscle;
  final List<Equipment> equipment;
  final String? beginnerTip;
  final String? gifPath;
  final List<String>? commonMistakes;
  final List<String>? modifications;

  const Exercise({
    required this.id,
    required this.title,
    required this.instructions,
    required this.dose,
    required this.targetMuscle,
    required this.equipment,
    this.beginnerTip,
    this.gifPath,
    this.commonMistakes,
    this.modifications,
  });
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  if (minutes == 0) {
    return '${seconds}s';
  }
  if (seconds == 0) {
    return '$minutes min';
  }
  return '${minutes}m ${seconds}s';
}
