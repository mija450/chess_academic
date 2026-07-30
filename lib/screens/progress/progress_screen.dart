// ============================================================
// FILE: progress_screen.dart (REVAMPED)
// ============================================================
import 'package:flutter/material.dart';
import '../../services/progress_service.dart';
import '../../theme/app_theme.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance.progress;
    final unlocked = progress.unlockedAchievements.toSet();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('📈 Tu Progreso'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) {
              return Transform.scale(
                scale: 0.96 + (0.04 * value),
                child: Opacity(
                  opacity: value,
                  child: _StatsCard(progress: progress),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) {
              return Transform.translate(
                offset: Offset(20 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: _StatRow(
                    label: 'Ejercicios resueltos',
                    value: '${progress.solvedPuzzleIds.length}',
                    icon: Icons.emoji_events,
                    color: AppTheme.primary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            '🏆 Logros',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 10),
          ...ProgressService.allAchievements.map((a) {
            final isUnlocked = unlocked.contains(a.id);
            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + (ProgressService.allAchievements.indexOf(a) * 60)),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) {
                return Transform.translate(
                  offset: Offset(20 * (1 - value), 0),
                  child: Opacity(
                    opacity: value,
                    child: _AchievementTile(
                      achievement: a,
                      unlocked: isUnlocked,
                    ),
                  ),
                );
              },
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final progress;
  const _StatsCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDark ? [] : AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatBlock(label: 'Nivel', value: '${progress.level}', emoji: '⭐'),
              _StatBlock(label: 'XP total', value: '${progress.xp}', emoji: '⚡'),
              _StatBlock(label: 'Racha', value: '${progress.streakDays} días', emoji: '🔥'),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                '${progress.xpIntoCurrentLevel} / ${progress.xpForNextLevel} XP',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.textSecondaryDark : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${((progress.xpIntoCurrentLevel / progress.xpForNextLevel) * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (progress.xpIntoCurrentLevel / progress.xpForNextLevel).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black12,
              valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  const _StatBlock({required this.label, required this.value, required this.emoji});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? AppTheme.textDark : AppTheme.textLight,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.textSecondaryDark : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDark ? [] : AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: isDark ? AppTheme.textDark : AppTheme.textLight,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final achievement;
  final bool unlocked;

  const _AchievementTile({required this.achievement, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked
            ? AppTheme.success.withOpacity(0.06)
            : (isDark ? AppTheme.surfaceDark : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked
              ? AppTheme.success.withOpacity(0.2)
              : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
        ),
        boxShadow: unlocked && !isDark
            ? [
                BoxShadow(
                  color: AppTheme.success.withOpacity(0.06),
                  blurRadius: 12,
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppTheme.success.withOpacity(0.12)
                  : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Opacity(
                opacity: unlocked ? 1 : 0.3,
                child: Text(achievement.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: unlocked ? AppTheme.success : (isDark ? AppTheme.textSecondaryDark : Colors.black45),
                  ),
                ),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textSecondaryDark : Colors.black45,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
        ],
      ),
    );
  }
}