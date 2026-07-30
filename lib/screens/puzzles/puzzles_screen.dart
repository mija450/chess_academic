import 'package:flutter/material.dart';
import '../../core/data_models.dart';
import '../../services/data_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/puzzle_solver.dart';

class PuzzlesScreen extends StatefulWidget {
  const PuzzlesScreen({super.key});

  @override
  State<PuzzlesScreen> createState() => _PuzzlesScreenState();
}

class _PuzzlesScreenState extends State<PuzzlesScreen> {
  List<Puzzle> puzzles = [];
  String filter = 'Todos';

  @override
  void initState() {
    super.initState();
    DataService.instance.loadPuzzles().then((p) => setState(() => puzzles = p));
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Todos', ...{for (final p in puzzles) p.category}];
    final filtered = filter == 'Todos' ? puzzles : puzzles.where((p) => p.category == filter).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('🧩 Problemas'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // filtros
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = categories[i];
                final selected = cat == filter;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() => filter = cat),
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                );
              },
            ),
          ),
          Expanded(
            child: puzzles.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      final done = ProgressService.instance.isPuzzleSolved(p.id);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: done ? AppTheme.success.withOpacity(0.15) : AppTheme.primary.withOpacity(0.1),
                            child: Text(done ? '✓' : '♟', style: TextStyle(color: done ? AppTheme.success : AppTheme.primary)),
                          ),
                          title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${p.category} · ${p.difficulty} · +${p.xp} XP'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              builder: (context) => DraggableScrollableSheet(
                                initialChildSize: 0.9,
                                minChildSize: 0.5,
                                maxChildSize: 0.95,
                                expand: false,
                                builder: (_, scrollController) => Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                  ),
                                  child: SingleChildScrollView(
                                    controller: scrollController,
                                    padding: const EdgeInsets.all(16),
                                    child: PuzzleSolverWidget(
                                      puzzle: p,
                                      onSolved: () => setState(() {}),
                                    ),
                                  ),
                                ),
                              ),
                            );
                            setState(() {});
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}