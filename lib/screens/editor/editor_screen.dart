// ============================================================
// FILE: editor_screen.dart (REVAMPED)
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/chess_engine.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chess_board_widget.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with SingleTickerProviderStateMixin {
  late ChessEngine engine;
  String? selectedPiece = 'wP';
  bool drawingMode = false;
  final fenController = TextEditingController();
  final boardKey = GlobalKey<ChessBoardWidgetState>();
  late AnimationController _animController;

  static const pieceOrder = ['K', 'Q', 'R', 'B', 'N', 'P'];

  @override
  void initState() {
    super.initState();
    engine = ChessEngine();
    fenController.text = engine.toFen();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    fenController.dispose();
    super.dispose();
  }

  void _syncFenField() {
    fenController.text = engine.toFen();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('✏️ Editor de Tablero'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Modo dibujo',
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: drawingMode ? AppTheme.primary.withOpacity(0.15) : Colors.transparent,
              ),
              child: Icon(
                Icons.gesture,
                color: drawingMode ? AppTheme.primary : (isDark ? AppTheme.textDark : Colors.black54),
              ),
            ),
            onPressed: () {
              setState(() => drawingMode = !drawingMode);
              _animController.forward(from: 0);
            },
          ),
          IconButton(
            tooltip: 'Limpiar dibujos',
            icon: const Icon(Icons.layers_clear),
            onPressed: () => boardKey.currentState?.clearDrawings(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: drawingMode
                  ? Container(
                      key: const ValueKey('drawing'),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 18, color: AppTheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Modo dibujo: toca para círculo, arrastra para flecha.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppTheme.textDark : AppTheme.textLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            ChessBoardWidget(
              key: boardKey,
              engine: engine,
              drawingEnabled: drawingMode,
              editorPieceToPlace: drawingMode ? null : selectedPiece,
              onEditorChange: _syncFenField,
            ),
            const SizedBox(height: 16),
            _PiecePalette(
              selected: selectedPiece,
              onSelect: (p) => setState(() => selectedPiece = p),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _ActionButton(
                  icon: Icons.restart_alt,
                  label: 'Inicial',
                  onPressed: () => setState(() {
                    engine.loadFen(ChessEngine.startFen);
                    _syncFenField();
                  }),
                  color: AppTheme.primary,
                ),
                _ActionButton(
                  icon: Icons.clear_all,
                  label: 'Vacío',
                  onPressed: () => setState(() {
                    engine.board = List.filled(64, null);
                    _syncFenField();
                  }),
                  color: AppTheme.danger,
                ),
                _ActionButton(
                  icon: Icons.swap_horiz,
                  label: 'Turno: ${engine.turn == 'w' ? '♔' : '♚'}',
                  onPressed: () => setState(() {
                    engine.turn = engine.turn == 'w' ? 'b' : 'w';
                    _syncFenField();
                  }),
                  color: AppTheme.warning,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('FEN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: fenController,
              maxLines: 2,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: isDark ? AppTheme.textDark : AppTheme.textLight,
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: isDark ? AppTheme.surfaceDark : Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      try {
                        engine.loadFen(fenController.text.trim());
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Posición cargada'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('❌ FEN inválido'),
                            backgroundColor: AppTheme.danger,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Importar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: engine.toFen()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📋 FEN copiado'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copiar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _PiecePalette extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _PiecePalette({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pieces = [
      for (final t in _EditorScreenState.pieceOrder) 'w$t',
      for (final t in _EditorScreenState.pieceOrder) 'b$t',
      'DELETE',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: pieces.map((p) {
        final isSel = selected == p;
        return GestureDetector(
          onTap: () => onSelect(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isSel
                  ? AppTheme.primary.withOpacity(0.12)
                  : (isDark ? AppTheme.surfaceDark : Colors.white),
              border: Border.all(
                color: isSel ? AppTheme.primary : (isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
                width: isSel ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: isSel && !isDark ? AppTheme.softShadow : [],
            ),
            alignment: Alignment.center,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSel ? 1.1 : 1.0,
              child: p == 'DELETE'
                  ? Icon(Icons.delete_outline, size: 20, color: AppTheme.danger)
                  : Text(
                      glyphFor(p),
                      style: TextStyle(
                        fontSize: 26,
                        color: p[0] == 'w'
                            ? (isDark ? Colors.white : Colors.white)
                            : (isDark ? Colors.white70 : Colors.black87),
                        shadows: p[0] == 'w'
                            ? [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 2)]
                            : [],
                      ),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }
}