import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../core/data_models.dart';

class DataService {
  DataService._();
  static final DataService instance = DataService._();

  List<Puzzle>? _puzzles;
  List<Lesson>? _lessons;
  List<FamousGame>? _games;

  Future<List<Puzzle>> loadPuzzles() async {
    if (_puzzles != null) return _puzzles!;
    final raw = await rootBundle.loadString('assets/data/puzzles.json');
    final list = jsonDecode(raw) as List;
    _puzzles = list.map((e) => Puzzle.fromJson(e as Map<String, dynamic>)).toList();
    return _puzzles!;
  }

  Future<List<Lesson>> loadLessons() async {
    if (_lessons != null) return _lessons!;
    final raw = await rootBundle.loadString('assets/data/lessons.json');
    final list = jsonDecode(raw) as List;
    _lessons = list.map((e) => Lesson.fromJson(e as Map<String, dynamic>)).toList();
    return _lessons!;
  }

  Future<List<FamousGame>> loadGames() async {
    if (_games != null) return _games!;
    final raw = await rootBundle.loadString('assets/data/games.json');
    final list = jsonDecode(raw) as List;
    _games = list.map((e) => FamousGame.fromJson(e as Map<String, dynamic>)).toList();
    return _games!;
  }

  /// Elige un puzzle "del día" de forma determinista según la fecha.
  Future<Puzzle> dailyPuzzle() async {
    final puzzles = await loadPuzzles();
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    return puzzles[dayOfYear % puzzles.length];
  }
}
