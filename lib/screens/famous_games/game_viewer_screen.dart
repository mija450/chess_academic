// ============================================================
// FILE: game_viewer_screen.dart (REVAMPED)
// ============================================================
import 'package:flutter/material.dart';
import '../../core/chess_engine.dart';
import '../../core/data_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chess_board_widget.dart';

class GameViewerScreen extends StatefulWidget {
  final FamousGame game;
  const GameViewerScreen({super.key, required this.game});

  @override
  State<GameViewerScreen> createState() => _GameViewerScreenState();
}

class _GameViewerScreenState extends State<GameViewerScreen>
    with SingleTickerProviderStateMixin {
  late ChessEngine engine;
  int currentPly = 0;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    engine = ChessEngine();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _goTo(int ply) {
    setState(() {
      engine = ChessEngine();
      for (int i = 0; i < ply; i++) {
        final uci = widget.game.movesUci[i];
        final from = ChessEngine.squareIndex(uci.substring(0, 2));
        final to = ChessEngine.squareIndex(uci.substring(2, 4));
        final promo = uci.length > 4 ? uci.substring(4, 5).toUpperCase() : null;
        engine.makeMove(from, to, promotion: promo);
      }
      currentPly = ply;
      _animController.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final total = g.movesUci.length;
    final comment = currentPly > 0 && currentPly - 1 < g.comments.length
        ? g.comments[currentPly - 1]
        : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('${g.white} vs ${g.black}'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${g.event} · ${g.year}',
                style: TextStyle(
                  color: isDark ? AppTheme.textSecondaryDark : Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _animController,
              child: ChessBoardWidget(engine: engine, interactive: false),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ControlButton(
                  icon: Icons.skip_previous,
                  onPressed: () => _goTo(0),
                  color: AppTheme.primary,
                ),
                _ControlButton(
                  icon: Icons.chevron_left,
                  onPressed: currentPly > 0 ? () => _goTo(currentPly - 1) : null,
                  color: AppTheme.primary,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceDark : AppTheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$currentPly / $total',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                _ControlButton(
                  icon: Icons.chevron_right,
                  onPressed: currentPly < total ? () => _goTo(currentPly + 1) : null,
                  color: AppTheme.primary,
                ),
                _ControlButton(
                  icon: Icons.skip_next,
                  onPressed: () => _goTo(total),
                  color: AppTheme.primary,
                ),
              ],
            ),
            if (comment != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.format_quote, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        comment,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          color: isDark ? AppTheme.textDark : AppTheme.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: List.generate(total, (i) {
                final isCurrent = i == currentPly - 1;
                final moveNum = (i ~/ 2) + 1;
                final isWhiteMove = i % 2 == 0;
                final label = isWhiteMove ? '$moveNum. ${g.movesSan[i]}' : g.movesSan[i];
                return GestureDetector(
                  onTap: () => _goTo(i + 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppTheme.primary
                          : (isDark ? AppTheme.surfaceDark : Colors.black.withOpacity(0.04)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent
                            ? AppTheme.primary
                            : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isCurrent ? Colors.white : (isDark ? AppTheme.textDark : Colors.black87),
                        fontSize: 13,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const _ControlButton({
    required this.icon,
    this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: onPressed != null ? color : Colors.grey.withOpacity(0.3)),
      onPressed: onPressed,
      splashRadius: 24,
      padding: const EdgeInsets.all(8),
    );
  }
}