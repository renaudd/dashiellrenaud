import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/location_tile.dart';
import '../widgets/time_speed_controls.dart';

class RegionalMapScreen extends StatelessWidget {
  const RegionalMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        title: Text(
          'CANTON DE VAUD',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            fontSize: 18,
            color: const Color(0xFFE5D5B0),
          ),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE5D5B0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF241F1A),
          image: DecorationImage(
            image: const AssetImage(
              'assets/images/Carl_Spitzweg_-_Der_Maler_im_Garten.jpg',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.9),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE5D5B0).withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ),

            Center(
              child: AspectRatio(
                aspectRatio: 0.8,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 220,
                        left: 140,
                        child: LocationTile(
                          name: 'ROLLE',
                          icon: Icons.castle,
                          description:
                              'The lakeside town where your manor sits.',
                          isCurrent: true,
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                      const Positioned(
                        top: 320,
                        left: 200,
                        child: LocationTile(
                          name: 'LAUSANNE',
                          icon: Icons.location_city,
                          description: 'A major city to the East.',
                        ),
                      ),
                      const Positioned(
                        bottom: 80,
                        right: 40,
                        child: LocationTile(
                          name: 'ÉVIAN-LES-BAINS',
                          icon: Icons.beach_access,
                          description: 'French spa town across the Lac Léman.',
                        ),
                      ),
                      const Positioned(
                        bottom: 40,
                        left: 100,
                        child: LocationTile(
                          name: 'GENEVA',
                          icon: Icons.location_city,
                          description: 'The grand city to the Southwest.',
                        ),
                      ),
                      const Positioned(
                        top: 40,
                        left: 40,
                        child: LocationTile(
                          name: 'LA DÔLE',
                          icon: Icons.terrain,
                          description: 'A prominent peak in the Jura.',
                        ),
                      ),
                      const Positioned(
                        top: 100,
                        left: 10,
                        child: LocationTile(
                          name: 'LE NOIRMONT',
                          icon: Icons.terrain,
                          description: 'A rugged mountain pass.',
                        ),
                      ),
                      const Positioned(
                        top: 20,
                        right: 80,
                        child: LocationTile(
                          name: 'MONT TENDRE',
                          icon: Icons.terrain,
                          description: 'The highest peak of the Swiss Jura.',
                        ),
                      ),
                      const Positioned(
                        top: 180,
                        right: 120,
                        child: LocationTile(
                          name: 'VUFFLENS CASTLE',
                          icon: Icons.castle,
                          description: 'A magnificent medieval fortress.',
                        ),
                      ),
                      const Positioned(
                        bottom: 120,
                        left: 160,
                        child: LocationTile(
                          name: 'YVOIRE',
                          icon: Icons.water,
                          description: 'Walled medieval village in France.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                  ),
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: Column(
                  children: [
                    const TimeSpeedControls(),
                    const Divider(color: Colors.white10),
                    Text(
                      'CANTON DE VAUD, NEUTRAL SWITZERLAND - 1860',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFC4B89B),
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
