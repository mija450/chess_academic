// ============================================================
// FILE: minigames_screen.dart (REVAMPED)
// ============================================================
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/progress_service.dart';
import '../../theme/app_theme.dart';

class _QuizQuestion {
  final String prompt;
  final List<String> options;
  final int correctIndex;
  const _QuizQuestion(this.prompt, this.options, this.correctIndex);
}

class MinigamesScreen extends StatefulWidget {
  const MinigamesScreen({super.key});

  @override
  State<MinigamesScreen> createState() => _MinigamesScreenState();
}

class _MinigamesScreenState extends State<MinigamesScreen>
    with SingleTickerProviderStateMixin {
  final List<_QuizQuestion> _bank = [
    const _QuizQuestion('♞ ¿Cuánto vale el caballo?', ['1', '3', '5', '9'], 1),
    const _QuizQuestion('♛ ¿Cuánto vale la dama?', ['3', '5', '9', '∞'], 2),
    const _QuizQuestion('♜ ¿Cuánto vale la torre?', ['3', '5', '9', '1'], 1),
    const _QuizQuestion('♝ ¿Cuánto vale el alfil?', ['1', '3', '5', '9'], 1),
    const _QuizQuestion('♟ ¿Cuánto vale el peón?', ['1', '2', '3', '0'], 0),
    const _QuizQuestion('¿Cuántas casillas tiene el tablero?', ['32', '48', '64', '100'], 2),
    const _QuizQuestion('¿Cuántas filas tiene el tablero?', ['6', '8', '10', '12'], 1),
    const _QuizQuestion('¿Qué pieza se mueve en forma de "L"?', ['Alfil', 'Torre', 'Caballo', 'Peón'], 2),
    const _QuizQuestion('¿Qué pieza solo se mueve en diagonal?', ['Torre', 'Alfil', 'Caballo', 'Rey'], 1),
    const _QuizQuestion('¿Qué pieza solo se mueve en horizontal y vertical?', ['Torre', 'Alfil', 'Dama', 'Peón'], 0),
    const _QuizQuestion('¿Cómo se llama cuando el rey está atacado y no puede escapar?', ['Ahogado', 'Jaque', 'Jaque mate', 'Enroque'], 2),
    const _QuizQuestion('¿Cómo se llama el movimiento especial del rey y la torre juntos?', ['Coronación', 'Enroque', 'En passant', 'Ahogado'], 1),
    const _QuizQuestion('¿Qué pieza puede saltar sobre otras piezas?', ['Torre', 'Alfil', 'Caballo', 'Dama'], 2),
    const _QuizQuestion('Cuando un peón llega a la última fila, ¿qué ocurre?', ['Desaparece', 'Se corona', 'Vuelve al inicio', 'Nada'], 1),
    const _QuizQuestion('¿Cuántas piezas tiene cada jugador al inicio?', ['12', '14', '16', '20'], 2),
  ];

  late List<_QuizQuestion> session;
  int index = 0;
  int score = 0;
  int? selectedOption;
  bool answered = false;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _startSession();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _startSession() {
    session = List.of(_bank)..shuffle(Random());
    session = session.take(8).toList();
    index = 0;
    score = 0;
    selectedOption = null;
    answered = false;
    _slideController.value = 0;
  }

  void _answer(int i) {
    if (answered) return;
    setState(() {
      selectedOption = i;
      answered = true;
      if (i == session[index].correctIndex) {
        score++;
      }
    });
  }

  void _next() {
    if (index < session.length - 1) {
      _slideController.forward(from: 0).then((_) {
        setState(() {
          index++;
          selectedOption = null;
          answered = false;
        });
        _slideController.value = 0;
      });
    } else {
      final xp = score * 5;
      ProgressService.instance.addXpAndCheck(xp);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('🎉 ¡Terminaste!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Acertaste $score de ${session.length} preguntas',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+$xp XP',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(_startSession);
              },
              child: const Text('Jugar de nuevo'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Salir'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = session[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = session.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('🎮 Minijuegos'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (index + 1) / total,
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black12,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${index + 1}/$total',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? AppTheme.textSecondaryDark : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.08),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      q.prompt,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.textDark : AppTheme.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Column(
                key: ValueKey(index),
                children: List.generate(q.options.length, (i) {
                  Color? color;
                  if (answered) {
                    if (i == q.correctIndex) {
                      color = AppTheme.success;
                    } else if (i == selectedOption) {
                      color = AppTheme.danger;
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => _answer(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: color != null
                              ? color.withOpacity(0.12)
                              : (isDark ? AppTheme.surfaceDark : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color ?? (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
                            width: color != null ? 2 : 1,
                          ),
                          boxShadow: color != null && color == AppTheme.success && !isDark
                              ? [
                                  BoxShadow(
                                    color: AppTheme.success.withOpacity(0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: color?.withOpacity(0.15) ??
                                    (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: color != null
                                    ? Icon(
                                        i == q.correctIndex
                                            ? Icons.check
                                            : i == selectedOption
                                                ? Icons.close
                                                : null,
                                        color: color,
                                        size: 16,
                                      )
                                    : Text(
                                        String.fromCharCode(65 + i),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              q.options[i],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: color ?? (isDark ? AppTheme.textDark : AppTheme.textLight),
                              ),
                            ),
                            const Spacer(),
                            if (color != null && i == q.correctIndex)
                              const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                            if (color != null && i == selectedOption && i != q.correctIndex)
                              const Icon(Icons.cancel, color: AppTheme.danger, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const Spacer(),
            if (answered)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    index < session.length - 1 ? 'Siguiente →' : 'Ver resultado 🏆',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}