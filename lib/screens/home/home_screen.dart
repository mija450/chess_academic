import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/data_models.dart';
import '../../services/data_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_theme.dart';
import '../lessons/lessons_screen.dart';
import '../puzzles/puzzles_screen.dart';
import '../editor/editor_screen.dart';
import '../famous_games/famous_games_screen.dart';
import '../famous_games/game_viewer_screen.dart';
import '../daily_challenge/daily_challenge_screen.dart';
import '../progress/progress_screen.dart';
import '../minigames/minigames_screen.dart';
import '../settings/settings_screen.dart';

// ============================================================
//  HOME SCREEN CON BOTTOM NAVIGATION (SIN FIREBASE)
// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _userName = 'Invitado';
  String _userPhoto = '';
  String _pieceStyle = 'classic';

  final List<Widget> _pages = [
    const HomeTab(),
    const PuzzlesScreen(),
    const LessonsScreen(),
    const DiscoverTab(),
    const MoreTab(),
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pieceStyle = prefs.getString('piece_style') ?? 'classic';
      _userName = prefs.getString('user_name') ?? 'Invitado';
    });
  }

  Future<void> _savePieceStyle(String style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('piece_style', style);
    setState(() => _pieceStyle = style);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar sesión? (modo invitado)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_name', 'Invitado');
              setState(() => _userName = 'Invitado');
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Problemas'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Aprender'),
          BottomNavigationBarItem(icon: Icon(Icons.visibility), label: 'Ver'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Más'),
        ],
      ),
    );
  }
}

// ---- HomeTab (pantalla de inicio) ----
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance.progress;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = 'Invitado';
    final userPhoto = '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Chess Academic'),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.style),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- HEADER DE BIENVENIDA ----
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Foto de perfil
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '♔',
                      style: TextStyle(fontSize: 32, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Bienvenido, $userName!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nivel ${progress.level} · ${progress.xp} XP',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(
                                  '${progress.streakDays} días',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showLogoutDialog(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.logout, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text('Salir', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---- PROGRESO (barra) ----
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (progress.xpIntoCurrentLevel / progress.xpForNextLevel).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.black12,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${((progress.xpIntoCurrentLevel / progress.xpForNextLevel) * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ---- BOTONES GRANDES ----
          _FeatureCard(
            imagePath: 'assets/img/curso.png',
            title: '📚 Curso',
            subtitle: 'Aprende desde cero',
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LessonsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _FeatureCard(
            imagePath: 'assets/img/puzzles.png',
            title: '🧩 Problemas',
            subtitle: 'Resuelve puzzles tácticos',
            gradient: const LinearGradient(
              colors: [Color(0xFFE65100), Color(0xFFFF9800)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PuzzlesScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _FeatureCard(
                  imagePath: 'assets/img/editor.png',
                  title: '✏️ Editor',
                  subtitle: 'Crea posiciones',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditorScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FeatureCard(
                  imagePath: 'assets/img/partidas.png',
                  title: '♟️ Partidas',
                  subtitle: 'Grandes maestros',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4E342E), Color(0xFF795548)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FamousGamesScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _FeatureCard(
                  imagePath: 'assets/img/reto.png',
                  title: '🎯 Reto diario',
                  subtitle: 'Un puzzle cada día',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF57F17), Color(0xFFFFC107)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  badge: ProgressService.instance.dailyChallengeDoneToday ? '✓' : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DailyChallengeScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FeatureCard(
                  imagePath: 'assets/img/minijuegos.png',
                  title: '🎮 Minijuegos',
                  subtitle: 'Aprende jugando',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MinigamesScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ---- LOGROS RECIENTES ----
          const Text('🏆 Logros recientes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: progress.unlockedAchievements.length > 3 ? 3 : progress.unlockedAchievements.length,
              itemBuilder: (context, i) {
                final id = progress.unlockedAchievements[i];
                final ach = ProgressService.allAchievements.firstWhere((a) => a.id == id);
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.success.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(ach.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ach.title,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar sesión? (modo invitado)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_name', 'Invitado');
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

// ---- Widget para tarjeta de función ----
class _FeatureCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;
  final String? badge;

  const _FeatureCard({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
            opacity: 0.15,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---- DiscoverTab (partidas famosas + reto diario) ----
class DiscoverTab extends StatelessWidget {
  const DiscoverTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Descubrir'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primary,
                child: Icon(Icons.today, color: Colors.white),
              ),
              title: const Text('Reto diario'),
              subtitle: const Text('Un puzzle nuevo cada día'),
              trailing: ProgressService.instance.dailyChallengeDoneToday
                  ? const Icon(Icons.check_circle, color: AppTheme.success)
                  : const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DailyChallengeScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text('♟️ Partidas famosas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          FutureBuilder<List<FamousGame>>(
            future: DataService.instance.loadGames(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final games = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: games.length > 5 ? 5 : games.length,
                itemBuilder: (context, i) {
                  final g = games[i];
                  return ListTile(
                    leading: Text(i % 2 == 0 ? '♔' : '♚', style: const TextStyle(fontSize: 20)),
                    title: Text('${g.white} vs ${g.black}'),
                    subtitle: Text('${g.event} · ${g.year}'),
                    trailing: const Icon(Icons.play_arrow, color: AppTheme.primary),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GameViewerScreen(game: g)),
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FamousGamesScreen()),
                );
              },
              child: const Text('Ver todas las partidas'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- MoreTab (configuración, progreso, minijuegos, editor) ----
class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Más'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MoreTile(
            icon: Icons.analytics,
            title: 'Progreso',
            subtitle: 'Estadísticas y logros',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen())),
          ),
          _MoreTile(
            icon: Icons.gamepad,
            title: 'Minijuegos',
            subtitle: 'Aprende jugando',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MinigamesScreen())),
          ),
          _MoreTile(
            icon: Icons.edit,
            title: 'Editor de tablero',
            subtitle: 'Crea y guarda posiciones',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditorScreen())),
          ),
          _MoreTile(
            icon: Icons.settings,
            title: 'Configuración',
            subtitle: 'Ajustes de la app',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.grey),
            title: Text('Chess Academic v1.0.0'),
            subtitle: Text('Aprende y domina el ajedrez'),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}