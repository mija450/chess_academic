class Puzzle {
  final String id;
  final String title;
  final String fen;
  final List<String> solutionUci; // secuencia de jugadas en UCI, ej: e2e4
  final String difficulty;
  final int xp;
  final String hint;
  final String category;

  Puzzle({
    required this.id,
    required this.title,
    required this.fen,
    required this.solutionUci,
    required this.difficulty,
    required this.xp,
    required this.hint,
    required this.category,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) => Puzzle(
        id: json['id'].toString(),
        title: json['title'] as String,
        fen: json['fen'] as String,
        solutionUci: (json['solution'] as String).split(' '),
        difficulty: json['difficulty'] as String,
        xp: json['xp'] as int,
        hint: json['hint'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
      );
}

class LessonExercise {
  final String instruction;
  final String fen;
  final List<String> solutionUci;

  LessonExercise({required this.instruction, required this.fen, required this.solutionUci});

  factory LessonExercise.fromJson(Map<String, dynamic> json) => LessonExercise(
        instruction: json['instruction'] as String,
        fen: json['fen'] as String,
        solutionUci: (json['solution'] as String).split(' '),
      );
}

class Lesson {
  final String id;
  final String level;
  final String title;
  final List<String> content; // párrafos explicativos
  final String? pieceSymbol;
  final String? pieceValue;
  final List<LessonExercise> exercises;
  final String demoFen;

  Lesson({
    required this.id,
    required this.level,
    required this.title,
    required this.content,
    this.pieceSymbol,
    this.pieceValue,
    required this.exercises,
    this.demoFen = 'start',
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'].toString(),
        level: json['level'] as String,
        title: json['title'] as String,
        content: (json['content'] as List).map((e) => e.toString()).toList(),
        pieceSymbol: json['pieceSymbol'] as String?,
        pieceValue: json['pieceValue'] as String?,
        demoFen: json['demoFen'] as String? ?? 'start',
        exercises: ((json['exercises'] as List?) ?? [])
            .map((e) => LessonExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class FamousGame {
  final String id;
  final String white;
  final String black;
  final String event;
  final String year;
  final List<String> movesUci;
  final List<String> movesSan;
  final List<String> comments; // comentario por jugada (puede haber menos que movimientos)

  FamousGame({
    required this.id,
    required this.white,
    required this.black,
    required this.event,
    required this.year,
    required this.movesUci,
    required this.movesSan,
    required this.comments,
  });

  factory FamousGame.fromJson(Map<String, dynamic> json) => FamousGame(
        id: json['id'].toString(),
        white: json['white'] as String,
        black: json['black'] as String,
        event: json['event'] as String,
        year: json['year'].toString(),
        movesUci: (json['movesUci'] as List).map((e) => e.toString()).toList(),
        movesSan: (json['movesSan'] as List).map((e) => e.toString()).toList(),
        comments: ((json['comments'] as List?) ?? []).map((e) => e.toString()).toList(),
      );
}
