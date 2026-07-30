import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/progress_service.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Apariencia ----
          _SettingsGroup(title: 'GLOBAL', children: [
            _SettingsTile(
              icon: Icons.palette,
              title: 'Apariencia',
              subtitle: isDark ? 'Oscuro' : 'Claro',
              trailing: Switch(
                value: isDark,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeColor: AppTheme.primary,
              ),
            ),
            _SettingsTile(
              icon: Icons.language,
              title: 'Idioma',
              subtitle: 'Español',
              trailing: const Icon(Icons.chevron_right),
            ),
          ]),

          const SizedBox(height: 16),

          // ---- Tablero ----
          _SettingsGroup(title: 'TABLERO', children: [
            _SettingsTile(
              icon: Icons.square_foot,
              title: 'Color de casillas',
              subtitle: 'Clásico',
              trailing: const Icon(Icons.chevron_right),
            ),
            _SettingsTile(
              icon: Icons.swap_horiz,
              title: 'Rotar tablero',
              subtitle: 'Blancas abajo',
              trailing: const Icon(Icons.chevron_right),
            ),
          ]),

          const SizedBox(height: 16),

          // ---- Notificaciones ----
          _SettingsGroup(title: 'NOTIFICACIONES', children: [
            _SettingsTile(
              icon: Icons.notifications,
              title: 'Recordatorio de racha',
              subtitle: '20:00',
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
            _SettingsTile(
              icon: Icons.notifications_active,
              title: 'Nuevos cursos',
              subtitle: 'Activado',
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
          ]),

          const SizedBox(height: 16),

          // ---- Cuenta ----
          _SettingsGroup(title: 'CUENTA', children: [
            _SettingsTile(
              icon: Icons.person,
              title: 'Perfil',
              subtitle: 'Ver tu información',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.restart_alt,
              title: 'Reiniciar progreso',
              subtitle: 'Borrar todo el avance',
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reiniciar progreso'),
                    content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                        child: const Text('Reiniciar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final p = ProgressService.instance.progress;
                  p.xp = 0;
                  p.level = 1;
                  p.solvedPuzzleIds.clear();
                  p.unlockedAchievements.clear();
                  p.lessonProgress.clear();
                  p.streakDays = 0;
                  await p.save();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Progreso reiniciado'), backgroundColor: AppTheme.danger),
                    );
                  }
                }
              },
            ),
          ]),

          const SizedBox(height: 24),
          Center(
            child: Text(
              'Chess Academic v1.0.0',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.grey.shade700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 22),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
      dense: true,
    );
  }
}