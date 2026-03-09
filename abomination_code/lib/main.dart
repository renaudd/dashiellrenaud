import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'state/game_state.dart';
import 'services/audio_service.dart';
import 'services/game_engine.dart';
import 'ui/screens/main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioService = AudioService();
  await audioService.initialize();

  final gameState = GameState();
  final gameEngine = GameEngine(gameState);

  // Play placeholder bleak music (user can replace URL)
  // audioService.playBGM('https://example.com/sorcerers_apprentice.mp3', isAsset: false);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: gameState),
        Provider.value(value: gameEngine),
      ],
      child: const AbominationApp(),
    ),
  );
}

class AbominationApp extends StatelessWidget {
  const AbominationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abomination',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1612), // Deep wood shadow
        textTheme:
            GoogleFonts.playfairDisplayTextTheme(
              ThemeData.dark().textTheme,
            ).copyWith(
              bodyMedium: GoogleFonts.oldStandardTt(
                color: const Color(0xFFC4B89B),
              ),
            ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B2F21), // Mahogany
          brightness: Brightness.dark,
          surface: const Color(0xFF241F1A),
          primary: const Color(0xFFC4B89B), // Brass/Parchment
        ),
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}
