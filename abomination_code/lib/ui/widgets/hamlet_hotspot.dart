import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HamletHotspot extends StatefulWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final double top;
  final double left;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final bool hasTraveler;

  const HamletHotspot({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.top,
    required this.left,
    this.width = 120,
    this.height = 80,
    this.onTap,
    required this.hasTraveler,
  });

  @override
  State<HamletHotspot> createState() => _HamletHotspotState();
}

class _HamletHotspotState extends State<HamletHotspot> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isLocked = !widget.hasTraveler;

    return Positioned(
      top: widget.top,
      left: widget.left,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: _isHovered
                  ? (isLocked
                        ? Colors.red.withValues(alpha: 0.1)
                        : const Color(0xFFC4B89B).withValues(alpha: 0.1))
                  : Colors.transparent,
              border: Border.all(
                color: _isHovered
                    ? (isLocked
                          ? Colors.redAccent.withValues(alpha: 0.3)
                          : const Color(0xFFC4B89B).withValues(alpha: 0.4))
                    : Colors.transparent,
              ),
              boxShadow: [
                if (_isHovered && !isLocked)
                  BoxShadow(
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Icon / Lock Overlay
                Icon(
                  isLocked ? Icons.lock_outline : widget.icon,
                  color: isLocked
                      ? Colors.redAccent.withValues(alpha: 0.5)
                      : const Color(0xFFE5D5B0).withValues(alpha: 0.8),
                  size: 28,
                ),

                // Label Tooltip (visible on hover)
                if (_isHovered)
                  Positioned(
                    top: -45,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.9),
                        border: Border.all(
                          color: isLocked
                              ? Colors.redAccent
                              : const Color(0xFFC4B89B),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.label.toUpperCase(),
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFE5D5B0),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            isLocked
                                ? "REPRESENTATIVE REQUIRED"
                                : widget.subtitle.toUpperCase(),
                            style: GoogleFonts.oldStandardTt(
                              color: isLocked
                                  ? Colors.redAccent
                                  : const Color(0xFFC4B89B),
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
