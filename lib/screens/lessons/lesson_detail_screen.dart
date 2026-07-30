// ============================================================
// FILE: lesson_detail_screen.dart (REVAMPED)
// ============================================================
import 'package:flutter/material.dart';
import '../../core/chess_engine.dart';
import '../../core/data_models.dart';
import '../../services/progress_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chess_board_widget.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen>
    with SingleTickerProviderStateMixin {
  late ChessEngine engine;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    engine = ChessEngine();
    if (widget.lesson.demoFen != 'start') {
      engine.loadFen(widget.lesson.demoFen);
    }
    ProgressService.instance.setLessonProgress(widget.lesson.id, 1.0);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(lesson.title),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _animController,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (lesson.pieceSymbol != null)
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          lesson.pieceSymbol!,
                          style: const TextStyle(fontSize: 48, color: AppTheme.primaryDark),
                        ),
                      ),
                    ),
                    if (lesson.pieceValue != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Valor: ${lesson.pieceValue}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ...lesson.content.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  p,
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.6,
                    color: isDark ? AppTheme.textDark : AppTheme.textLight,
                  ),
                ),
              ),
            ),
            if (lesson.demoFen != 'start' || lesson.pieceSymbol != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📐 Tablero de ejemplo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    ChessBoardWidget(engine: engine, interactive: false),
                  ],
                ),
              ),
            ],
            if (lesson.exercises.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                '🧠 Ejercicio práctico',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              ...lesson.exercises.map((ex) => _ExerciseCard(exercise: ex)),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final LessonExercise exercise;
  const _ExerciseCard({required this.exercise});

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard>
    with SingleTickerProviderStateMixin {
  late ChessEngine engine;
  String feedback = '';
  Color feedbackColor = Colors.transparent;
  bool solved = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    engine = ChessEngine();
    engine.loadFen(widget.exercise.fen);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  bool _tryMove(int from, int to) {
    final isAny = widget.exercise.solutionUci.length == 1 &&
        widget.exercise.solutionUci.first == 'ANY';
    bool matches = isAny;
    if (!isAny) {
      final expected = widget.exercise.solutionUci.first;
      final ef = ChessEngine.squareIndex(expected.substring(0, 2));
      final et = ChessEngine.squareIndex(expected.substring(2, 4));
      matches = from == ef && to == et;
    }
    if (matches) {
      engine.makeMove(from, to);
      setState(() {
        solved = true;
        feedback = '🎉 ¡Muy bien! +5 XP';
        feedbackColor = AppTheme.success;
      });
      ProgressService.instance.addXpAndCheck(5);
      return true;
    }
    setState(() {
      feedback = '❌ Intenta nuevamente';
      feedbackColor = AppTheme.danger;
    });
    _shakeController.forward(from: 0);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: solved
              ? AppTheme.success.withOpacity(0.3)
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
        ),
        boxShadow: solved && !isDark
            ? [
                BoxShadow(
                  color: AppTheme.success.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: solved
                      ? const Icon(Icons.check, size: 18, color: AppTheme.success)
                      : const Icon(Icons.help_outline, size: 18, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.exercise.instruction,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? AppTheme.textDark : AppTheme.textLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final dx = 5 * _shakeController.value *
                    (1 - _shakeController.value) *
                    (_shakeController.value > 0.5 ? -1 : 1);
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: ChessBoardWidget(
                engine: engine,
                interactive: !solved,
                tryMove: _tryMove,
              ),
            ),
            if (feedback.isNotEmpty)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: feedbackColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: feedbackColor.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      feedbackColor == AppTheme.success ? Icons.check_circle : Icons.error_outline,
                      color: feedbackColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      feedback,
                      style: TextStyle(
                        color: feedbackColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}