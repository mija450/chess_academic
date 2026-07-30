import 'dart:async';
import 'package:flutter/material.dart';
import '../core/chess_engine.dart';
import '../core/data_models.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import 'chess_board_widget.dart';

class PuzzleSolverWidget extends StatefulWidget {
  final Puzzle puzzle;
  final VoidCallback? onSolved;

  const PuzzleSolverWidget({super.key, required this.puzzle, this.onSolved});

  @override
  State<PuzzleSolverWidget> createState() => _PuzzleSolverWidgetState();
}

class _PuzzleSolverWidgetState extends State<PuzzleSolverWidget> {
  late ChessEngine engine;
  int moveIndex = 0;
  String feedback = '';
  Color feedbackColor = Colors.transparent;
  bool solved = false;
  bool showHint = false;
  int attempts = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(covariant PuzzleSolverWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.puzzle.id != widget.puzzle.id) _reset();
  }

  void _reset() {
    engine = ChessEngine();
    engine.loadFen(widget.puzzle.fen);
    moveIndex = 0;
    feedback = '';
    solved = false;
    showHint = false;
    attempts = 0;
  }

  bool _tryMove(int from, int to) {
    final expected = widget.puzzle.solutionUci[moveIndex];
    final expectedFrom = ChessEngine.squareIndex(expected.substring(0, 2));
    final expectedTo = ChessEngine.squareIndex(expected.substring(2, 4));

    if (from == expectedFrom && to == expectedTo) {
      engine.makeMove(from, to);
      moveIndex++;
      if (moveIndex >= widget.puzzle.solutionUci.length) {
        setState(() {
          solved = true;
          feedback = '¡Excelente! +${widget.puzzle.xp} XP';
          feedbackColor = AppColors.success;
        });
        ProgressService.instance.markPuzzleSolved(widget.puzzle.id, widget.puzzle.xp);
        widget.onSolved?.call();
      } else {
        // Turno del oponente (si el puzzle tiene más de una jugada)
        setState(() {
          feedback = 'Bien. Respondiendo...';
          feedbackColor = AppColors.primary;
        });
        Future.delayed(const Duration(milliseconds: 550), () {
          if (!mounted) return;
          final oppMove = widget.puzzle.solutionUci[moveIndex];
          final oFrom = ChessEngine.squareIndex(oppMove.substring(0, 2));
          final oTo = ChessEngine.squareIndex(oppMove.substring(2, 4));
          engine.makeMove(oFrom, oTo);
          moveIndex++;
          setState(() {
            feedback = 'Tu turno de nuevo';
            feedbackColor = AppColors.primary;
          });
        });
      }
      return true;
    } else {
      setState(() {
        attempts++;
        feedback = 'Intenta nuevamente ❌';
        feedbackColor = AppColors.danger;
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Chip(
                label: Text(widget.puzzle.difficulty),
                backgroundColor: AppColors.primary.withOpacity(0.1),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(widget.puzzle.category),
                backgroundColor: AppColors.accent.withOpacity(0.15),
              ),
              const Spacer(),
              Text('+${widget.puzzle.xp} XP', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.puzzle.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          engine.turn == 'w' ? 'Juegan blancas' : 'Juegan negras',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ChessBoardWidget(
            key: ValueKey(widget.puzzle.id),
            engine: engine,
            interactive: !solved,
            tryMove: _tryMove,
          ),
        ),
        const SizedBox(height: 14),
        if (feedback.isNotEmpty)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: feedbackColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(feedback, style: TextStyle(color: feedbackColor, fontWeight: FontWeight.bold)),
          ),
        const SizedBox(height: 10),
        if (!solved)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => showHint = !showHint),
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('Pista'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => setState(_reset),
                icon: const Icon(Icons.refresh),
                label: const Text('Reiniciar'),
              ),
            ],
          ),
        if (showHint && !solved)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.puzzle.hint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54),
            ),
          ),
      ],
    );
  }
}
