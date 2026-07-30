// ============================================================
// FILE: daily_challenge_screen.dart (REVAMPED)
// ============================================================
import 'package:flutter/material.dart';
import '../../core/data_models.dart';
import '../../services/data_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/puzzle_solver.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen>
    with SingleTickerProviderStateMixin {
  Puzzle? puzzle;
  bool alreadyDoneToday = false;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);

    alreadyDoneToday = ProgressService.instance.dailyChallengeDoneToday;
    DataService.instance.dailyPuzzle().then((p) {
      setState(() => puzzle = p);
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('🎯 Reto diario'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: puzzle == null
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primary),
              ),
            )
          : FadeTransition(
              opacity: _fadeIn,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: alreadyDoneToday
                            ? AppTheme.success.withOpacity(0.12)
                            : AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: alreadyDoneToday
                              ? AppTheme.success.withOpacity(0.2)
                              : AppTheme.primary.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: alreadyDoneToday
                                  ? AppTheme.success.withOpacity(0.15)
                                  : AppTheme.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                alreadyDoneToday ? '✅' : '🗓️',
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 400),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: alreadyDoneToday
                                    ? AppTheme.success
                                    : (isDark ? AppTheme.textDark : AppTheme.textLight),
                                height: 1.4,
                              ),
                              child: Text(
                                alreadyDoneToday
                                    ? '¡Ya completaste el reto de hoy! 🎉\nVuelve mañana por uno nuevo.'
                                    : '🧠 Un ejercicio nuevo cada día.\n¡Resuélvelo y mantén tu racha!',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 600),
                      builder: (_, value, __) {
                        return Transform.scale(
                          scale: 0.95 + (0.05 * value),
                          child: Opacity(opacity: value, child: const SizedBox.shrink()),
                        );
                      },
                      child: PuzzleSolverWidget(
                        puzzle: puzzle!,
                        onSolved: () async {
                          final got = await ProgressService.instance
                              .completeDailyChallengeToday();
                          if (got) {
                            setState(() => alreadyDoneToday = true);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎉 ¡Reto completado! +10 XP'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}