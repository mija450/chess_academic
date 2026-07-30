import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../core/chess_engine.dart';
import '../theme/app_theme.dart';

const Map<String, String> kWhiteGlyphs = {
  'P': '♙', 'N': '♘', 'B': '♗', 'R': '♖', 'Q': '♕', 'K': '♔',
};
const Map<String, String> kBlackGlyphs = {
  'P': '♟', 'N': '♞', 'B': '♝', 'R': '♜', 'Q': '♛', 'K': '♚',
};

String glyphFor(String piece) {
  final color = piece[0];
  final type = piece[1];
  return color == 'w' ? kWhiteGlyphs[type]! : kBlackGlyphs[type]!;
}

class BoardArrow {
  final int from;
  final int to;
  final Color color;
  const BoardArrow(this.from, this.to, {this.color = const Color(0xCC1B7A3D)});
}

class ChessBoardWidget extends StatefulWidget {
  final ChessEngine engine;
  final bool interactive;
  final bool whiteAtBottom;
  final bool drawingEnabled;
  final void Function(int from, int to)? onMoveAttempt; // devuelve true/false vía onMove
  final bool Function(int from, int to)? tryMove; // debe intentar el movimiento y devolver si tuvo éxito
  final void Function(String? promotionColor, void Function(String type) choose)? onNeedPromotion;
  final Set<int> extraHighlights;
  final String? editorPieceToPlace; // 'wP'.. o 'DELETE', si no-null estamos en modo editor
  final VoidCallback? onEditorChange;

  const ChessBoardWidget({
    super.key,
    required this.engine,
    this.interactive = true,
    this.whiteAtBottom = true,
    this.drawingEnabled = false,
    this.onMoveAttempt,
    this.tryMove,
    this.onNeedPromotion,
    this.extraHighlights = const {},
    this.editorPieceToPlace,
    this.onEditorChange,
  });

  @override
  State<ChessBoardWidget> createState() => ChessBoardWidgetState();
}

class ChessBoardWidgetState extends State<ChessBoardWidget> {
  int? selected;
  List<ChessMove> legalTargets = [];
  final List<BoardArrow> arrows = [];
  final Set<int> circles = {};
  int? _dragStartSquare;

  void clearDrawings() {
    setState(() {
      arrows.clear();
      circles.clear();
    });
  }

  void refresh() => setState(() {
        selected = null;
        legalTargets = [];
      });

  int _displaySquareToBoard(int row, int col) {
    // row 0 = arriba de la pantalla
    final file = widget.whiteAtBottom ? col : 7 - col;
    final rank = widget.whiteAtBottom ? 7 - row : row;
    return ChessEngine.squareAt(file, rank);
  }

  void _handleTap(int sq) {
    if (widget.editorPieceToPlace != null) {
      setState(() {
        if (widget.editorPieceToPlace == 'DELETE') {
          widget.engine.board[sq] = null;
        } else {
          widget.engine.board[sq] = widget.editorPieceToPlace;
        }
      });
      widget.onEditorChange?.call();
      return;
    }
    if (!widget.interactive) return;

    if (widget.drawingEnabled) {
      setState(() {
        if (circles.contains(sq)) {
          circles.remove(sq);
        } else {
          circles.add(sq);
        }
      });
      return;
    }

    final piece = widget.engine.board[sq];
    if (selected == null) {
      if (piece != null && piece[0] == widget.engine.turn) {
        setState(() {
          selected = sq;
          legalTargets = widget.engine.legalMovesFrom(sq);
        });
      }
      return;
    }

    if (selected == sq) {
      setState(() {
        selected = null;
        legalTargets = [];
      });
      return;
    }

    final target = legalTargets.where((m) => m.to == sq).toList();
    if (target.isNotEmpty) {
      final needsPromotion = target.any((m) => m.promotion != null);
      final fromSq = selected!;
      setState(() {
        selected = null;
        legalTargets = [];
      });
      if (needsPromotion && widget.onNeedPromotion != null) {
        widget.onNeedPromotion!(widget.engine.turn, (type) {
          widget.engine.makeMove(fromSq, sq, promotion: type);
          setState(() {});
          widget.onMoveAttempt?.call(fromSq, sq);
        });
      } else {
        final ok = widget.tryMove?.call(fromSq, sq) ?? widget.engine.makeMove(fromSq, sq);
        setState(() {});
        if (ok) widget.onMoveAttempt?.call(fromSq, sq);
      }
    } else if (piece != null && piece[0] == widget.engine.turn) {
      setState(() {
        selected = sq;
        legalTargets = widget.engine.legalMovesFrom(sq);
      });
    } else {
      setState(() {
        selected = null;
        legalTargets = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.maxWidth;
      final cell = size / 8;
      return AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                  itemCount: 64,
                  itemBuilder: (context, index) {
                    final row = index ~/ 8;
                    final col = index % 8;
                    final sq = _displaySquareToBoard(row, col);
                    final isLight = (ChessEngine.fileOf(sq) + ChessEngine.rankOf(sq)) % 2 != 0;
                    final piece = widget.engine.board[sq];
                    final isSelected = selected == sq;
                    final isLegalTarget = legalTargets.any((m) => m.to == sq);
                    final isExtraHighlight = widget.extraHighlights.contains(sq);
                    final isCircled = circles.contains(sq);

                    Color bg = isLight ? AppColors.lightSquare : AppColors.darkSquare;
                    if (isSelected) bg = AppColors.selectedSquare;
                    if (isExtraHighlight) bg = Colors.orange.withOpacity(0.55);

                    return GestureDetector(
                      onTap: () => _handleTap(sq),
                      onLongPressStart: widget.interactive
                          ? (_) => _dragStartSquare = sq
                          : null,
                      onLongPressEnd: widget.interactive
                          ? (_) {
                              if (_dragStartSquare != null && _dragStartSquare != sq) {
                                setState(() {
                                  arrows.add(BoardArrow(_dragStartSquare!, sq));
                                });
                              }
                              _dragStartSquare = null;
                            }
                          : null,
                      child: Container(
                        color: bg,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (row == 7)
                              Positioned(
                                left: 2,
                                bottom: 1,
                                child: Text(
                                  String.fromCharCode('a'.codeUnitAt(0) + ChessEngine.fileOf(sq)),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isLight ? AppColors.darkSquare : AppColors.lightSquare,
                                  ),
                                ),
                              ),
                            if (col == 7)
                              Positioned(
                                right: 2,
                                top: 1,
                                child: Text(
                                  '${ChessEngine.rankOf(sq) + 1}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isLight ? AppColors.darkSquare : AppColors.lightSquare,
                                  ),
                                ),
                              ),
                            if (isLegalTarget && piece == null)
                              Container(
                                width: cell * 0.32,
                                height: cell * 0.32,
                                decoration: const BoxDecoration(
                                  color: AppColors.legalDot,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (isLegalTarget && piece != null)
                              Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.legalDot, width: 3),
                                ),
                              ),
                            if (isCircled)
                              Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.orange.shade700, width: 3),
                                ),
                              ),
                            if (piece != null)
                              Text(
                                glyphFor(piece),
                                style: TextStyle(
                                  fontSize: cell * 0.72,
                                  color: piece[0] == 'w' ? Colors.white : const Color(0xFF1a1a1a),
                                  shadows: piece[0] == 'w'
                                      ? [const Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(0.5, 0.5))]
                                      : [],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (arrows.isNotEmpty || circles.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ArrowPainter(
                      arrows: arrows,
                      cell: cell,
                      whiteAtBottom: widget.whiteAtBottom,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _ArrowPainter extends CustomPainter {
  final List<BoardArrow> arrows;
  final double cell;
  final bool whiteAtBottom;

  _ArrowPainter({required this.arrows, required this.cell, required this.whiteAtBottom});

  Offset _center(int sq) {
    final file = ChessEngine.fileOf(sq);
    final rank = ChessEngine.rankOf(sq);
    final col = whiteAtBottom ? file : 7 - file;
    final row = whiteAtBottom ? 7 - rank : rank;
    return Offset(col * cell + cell / 2, row * cell + cell / 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final a in arrows) {
      final p1 = _center(a.from);
      final p2 = _center(a.to);
      final paint = Paint()
        ..color = a.color
        ..strokeWidth = cell * 0.14
        ..strokeCap = StrokeCap.round;
      final direction = (p2 - p1);
      final length = direction.distance;
      if (length == 0) continue;
      final unit = direction / length;
      final shortenedEnd = p2 - unit * cell * 0.35;
      canvas.drawLine(p1, shortenedEnd, paint);

      final arrowSize = cell * 0.28;
      final angle = direction.direction;
      final path = Path();
      final tip = p2 - unit * cell * 0.08;
      final left = tip - Offset.fromDirection(angle - 0.45, arrowSize);
      final right = tip - Offset.fromDirection(angle + 0.45, arrowSize);
      path.moveTo(tip.dx, tip.dy);
      path.lineTo(left.dx, left.dy);
      path.lineTo(right.dx, right.dy);
      path.close();
      canvas.drawPath(path, Paint()..color = a.color);
    }
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) => true;
}
