import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final String description;
  final bool isCurrent;
  final VoidCallback? onTap;

  const LocationTile({
    super.key,
    required this.name,
    required this.icon,
    required this.description,
    this.isCurrent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showLocationInfo(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent
                  ? const Color(0xFFC4B89B).withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.3),
              border: Border.all(
                color: isCurrent
                    ? const Color(0xFFE5D5B0)
                    : const Color(0xFFC4B89B).withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: const Color(0xFFE5D5B0).withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isCurrent
                  ? const Color(0xFFE5D5B0)
                  : const Color(0xFFC4B89B),
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: GoogleFonts.playfairDisplay(
              color: isCurrent
                  ? const Color(0xFFE5D5B0)
                  : const Color(0xFFC4B89B).withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241F1A),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          name,
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFE5D5B0),
            fontSize: 24,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: GoogleFonts.oldStandardTt(
                color: const Color(0xFFC4B89B),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            if (!isCurrent)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFC4B89B)),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    'DISPATCH BUTLER',
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CLOSE',
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFC4B89B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
