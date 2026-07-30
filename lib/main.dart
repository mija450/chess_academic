import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/progress_service.dart';
import 'theme/app_theme.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProgressService.instance.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const ChessAcademicApp(),
    ),
  );
}

class ChessAcademicApp extends StatelessWidget {
  const ChessAcademicApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Chess Academic',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      home: const HomeScreen(),
    );
  }
}