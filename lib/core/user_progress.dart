import 'package:hive/hive.dart';

part 'user_progress.g.dart';

@HiveType(typeId: 0)
class UserProgress extends HiveObject {
  @HiveField(0)
  int xp;

  @HiveField(1)
  int level;

  @HiveField(2)
  List<String> solvedPuzzleIds;

  @HiveField(3)
  List<String> unlockedAchievements;

  @HiveField(4)
  Map<String, double> lessonProgress; // id lección -> % completado

  @HiveField(5)
  int streakDays;

  @HiveField(6)
  String lastActiveDate; // yyyy-MM-dd

  @HiveField(7)
  String? lastDailyChallengeDate;

  UserProgress({
    this.xp = 0,
    this.level = 1,
    List<String>? solvedPuzzleIds,
    List<String>? unlockedAchievements,
    Map<String, double>? lessonProgress,
    this.streakDays = 0,
    this.lastActiveDate = '',
    this.lastDailyChallengeDate,
  })  : solvedPuzzleIds = solvedPuzzleIds ?? [],
        unlockedAchievements = unlockedAchievements ?? [],
        lessonProgress = lessonProgress ?? {};

  /// XP necesario para el siguiente nivel (curva simple creciente).
  int get xpForNextLevel => 100 + (level - 1) * 50;

  int get xpIntoCurrentLevel {
    int total = 0;
    for (int l = 1; l < level; l++) {
      total += 100 + (l - 1) * 50;
    }
    return xp - total;
  }

  void addXp(int amount) {
    xp += amount;
    while (xpIntoCurrentLevel >= xpForNextLevel) {
      level++;
    }
  }
}
