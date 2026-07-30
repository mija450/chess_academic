// GENERATED CODE - manual (equivalente a lo que produce build_runner)
part of 'user_progress.dart';

class UserProgressAdapter extends TypeAdapter<UserProgress> {
  @override
  final int typeId = 0;

  @override
  UserProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProgress(
      xp: (fields[0] as int?) ?? 0,
      level: (fields[1] as int?) ?? 1,
      solvedPuzzleIds: (fields[2] as List?)?.cast<String>() ?? [],
      unlockedAchievements: (fields[3] as List?)?.cast<String>() ?? [],
      lessonProgress: (fields[4] as Map?)?.cast<String, double>() ?? {},
      streakDays: (fields[5] as int?) ?? 0,
      lastActiveDate: (fields[6] as String?) ?? '',
      lastDailyChallengeDate: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProgress obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.xp)
      ..writeByte(1)
      ..write(obj.level)
      ..writeByte(2)
      ..write(obj.solvedPuzzleIds)
      ..writeByte(3)
      ..write(obj.unlockedAchievements)
      ..writeByte(4)
      ..write(obj.lessonProgress)
      ..writeByte(5)
      ..write(obj.streakDays)
      ..writeByte(6)
      ..write(obj.lastActiveDate)
      ..writeByte(7)
      ..write(obj.lastDailyChallengeDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
