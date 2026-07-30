import 'package:hive_flutter/hive_flutter.dart';
import '../core/user_progress.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  const Achievement(this.id, this.title, this.description, this.emoji);
}

class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  static const String boxName = 'user_progress_box';
  late Box<UserProgress> _box;
  UserProgress get progress => _box.get('current') ?? UserProgress();

  static const List<Achievement> allAchievements = [
    Achievement('first_mate', 'Primer Mate', 'Resuelve tu primer ejercicio de mate', '♔'),
    Achievement('100_exercises', '100 Ejercicios', 'Resuelve 100 ejercicios', '💯'),
    Achievement('knight_master', 'Maestro del Caballo', 'Domina los ejercicios de caballo', '♞'),
    Achievement('endgame_specialist', 'Especialista en Finales', 'Completa la sección de finales', '🏁'),
    Achievement('streak_30', '30 Días Seguidos', 'Mantén una racha de 30 días', '🔥'),
    Achievement('level_5', 'Nivel 5', 'Alcanza el nivel 5', '⭐'),
    Achievement('level_10', 'Nivel 10', 'Alcanza el nivel 10', '🌟'),
  ];

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserProgressAdapter());
    }
    _box = await Hive.openBox<UserProgress>(boxName);
    if (_box.get('current') == null) {
      await _box.put('current', UserProgress());
    }
    _touchStreak();
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _touchStreak() {
    final p = progress;
    final today = _today();
    if (p.lastActiveDate == today) return;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yStr =
        '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    if (p.lastActiveDate == yStr) {
      p.streakDays++;
    } else if (p.lastActiveDate.isNotEmpty) {
      p.streakDays = 1;
    } else {
      p.streakDays = 1;
    }
    p.lastActiveDate = today;
    p.save();
  }

  Future<List<Achievement>> addXpAndCheck(int amount) async {
    final p = progress;
    final unlockedBefore = List<String>.from(p.unlockedAchievements);
    p.addXp(amount);

    final newlyUnlocked = <Achievement>[];
    void unlock(String id) {
      if (!p.unlockedAchievements.contains(id)) {
        p.unlockedAchievements.add(id);
      }
    }

    if (p.solvedPuzzleIds.isNotEmpty) unlock('first_mate');
    if (p.solvedPuzzleIds.length >= 100) unlock('100_exercises');
    if (p.streakDays >= 30) unlock('streak_30');
    if (p.level >= 5) unlock('level_5');
    if (p.level >= 10) unlock('level_10');

    await p.save();

    for (final a in allAchievements) {
      if (p.unlockedAchievements.contains(a.id) && !unlockedBefore.contains(a.id)) {
        newlyUnlocked.add(a);
      }
    }
    return newlyUnlocked;
  }

  Future<void> markPuzzleSolved(String puzzleId, int xp) async {
    final p = progress;
    if (!p.solvedPuzzleIds.contains(puzzleId)) {
      p.solvedPuzzleIds.add(puzzleId);
    }
    await p.save();
    await addXpAndCheck(xp);
  }

  Future<void> setLessonProgress(String lessonId, double pct) async {
    final p = progress;
    p.lessonProgress[lessonId] = pct;
    await p.save();
  }

  bool isPuzzleSolved(String id) => progress.solvedPuzzleIds.contains(id);

  Future<bool> completeDailyChallengeToday() async {
    final p = progress;
    final today = _today();
    if (p.lastDailyChallengeDate == today) return false;
    p.lastDailyChallengeDate = today;
    await p.save();
    return true;
  }

  bool get dailyChallengeDoneToday => progress.lastDailyChallengeDate == _today();
}
