import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/save_load_dialogs.dart';

class GameOverScreen extends StatelessWidget {
  final String reason;

  const GameOverScreen({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'EXPERIMENT TERMINATED',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.redAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                height: 2,
                color: Colors.redAccent.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 32),
              Text(
                reason.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.oldStandardTt(
                  color: const Color(0xFFC4B89B),
                  fontSize: 16,
                  height: 1.6,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 64),
              _buildActionButton(context, 'RESTORE PREVIOUS DOCUMENTATION', () {
                showDialog(
                  context: context,
                  builder: (context) => LoadGameDialog(
                    onSlotSelected: (slot) {
                      // Selection handled by dialog
                    },
                  ),
                );
              }),
              const SizedBox(height: 16),
              _buildActionButton(context, 'START ANONYMOUS NEW LIFE', () {
                // Basically reload the app/reset state
                // Simple approach: restart main
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFC4B89B)),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text(
          label,
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFE5D5B0),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
