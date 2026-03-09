import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../../services/save_service.dart';
import 'introduction_screen.dart';
import 'manor_screen.dart';
import 'combat_simulator_screen.dart';
import '../widgets/save_load_dialogs.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Spitzweg Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/Carl_Spitzweg_-_Der_Maler_im_Garten.jpg',
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.3),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // Gradient for text readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.4, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Title
                Text(
                  'ABOMINATION',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 12,
                    color: const Color(0xFFE5D5B0), // Aged Parchment
                    shadows: [
                      const Shadow(
                        blurRadius: 10,
                        color: Colors.black,
                        offset: Offset(4, 4),
                      ),
                    ],
                  ),
                ),

                Text(
                  'non satis scire',
                  style: GoogleFonts.oldStandardTt(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 2,
                    color: const Color(0xFFC4B89B),
                  ),
                ),

                const Spacer(flex: 3),

                // Menu Buttons
                _buildMenuButton(context, 'BEGIN EXPERIMENT', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IntroductionScreen(),
                    ),
                  );
                }),

                const SizedBox(height: 16),

                FutureBuilder<bool>(
                  future: Future.wait([
                    SaveService.hasSaveGame(slot: 1),
                    SaveService.hasSaveGame(slot: 2),
                    SaveService.hasSaveGame(slot: 3),
                  ]).then((results) => results.any((hasSave) => hasSave)),
                  builder: (context, snapshot) {
                    final hasAnySave = snapshot.data ?? false;
                    return _buildMenuButton(
                      context,
                      'CONTINUE',
                      hasAnySave
                          ? () {
                              showDialog(
                                context: context,
                                builder: (context) => LoadGameDialog(
                                  onSlotSelected: (slot) async {
                                    final data = await SaveService.loadGame(
                                      slot: slot,
                                    );
                                    if (data != null && context.mounted) {
                                      context.read<GameState>().loadFromJson(
                                        data,
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ManorScreen(),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            }
                          : null,
                    );
                  },
                ),

                _buildMenuButton(context, 'OPTIONS', null),

                const SizedBox(height: 16),

                _buildMenuButton(context, 'COMBAT SIMULATOR', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CombatSimulatorScreen(),
                    ),
                  );
                }),

                const Spacer(flex: 1),

                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Copyright 2026 Dashiell Renaud',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String label,
    VoidCallback? onPressed,
  ) {
    return SizedBox(
      width: 280,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: onPressed != null
                ? const Color(0xFFE5D5B0).withValues(alpha: 0.5)
                : Colors.white10,
            width: 1.5,
          ),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          backgroundColor: Colors.black.withValues(alpha: 0.4),
        ),
        child: Text(
          label,
          style: GoogleFonts.playfairDisplay(
            color: onPressed != null ? const Color(0xFFE5D5B0) : Colors.white12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
