import 'package:flutter/material.dart';
import '../../core/data_models.dart';
import '../../services/data_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_theme.dart';
import 'lesson_detail_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  List<Lesson> lessons = [];

  @override
  void initState() {
    super.initState();
    DataService.instance.loadLessons().then((l) => setState(() => lessons = l));
  }

  @override
  Widget build(BuildContext context) {
    final byLevel = <String, List<Lesson>>{};
    for (final l in lessons) {
      byLevel.putIfAbsent(l.level, () => []).add(l);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('📚 Aprender'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: lessons.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: byLevel.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                    ...entry.value.map((lesson) {
                      final pct = ProgressService.instance.progress.lessonProgress[lesson.id] ?? 0.0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                lesson.pieceSymbol ?? '📖',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: pct > 0
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 4,
                                      backgroundColor: Colors.black12,
                                      valueColor: const AlwaysStoppedAnimation(AppTheme.success),
                                    ),
                                  ),
                                )
                              : null,
                          trailing: pct >= 1.0 ? const Icon(Icons.check_circle, color: AppTheme.success) : null,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: lesson)),
                            );
                            setState(() {});
                          },
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
    );
  }
}