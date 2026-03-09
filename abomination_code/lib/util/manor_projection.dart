import 'package:flutter/material.dart';

class ManorProjection {
  // Constants for the coordinate space
  static const double blockWidth = 100.0;
  static const double blockHeight = 160.0;

  // Oblique projection offsets per layer of depth
  // layer 0 is the cross-section (front)
  // layer 1 is the surface/environs (pushed back and up)
  static const double depthOffsetX = 40.0;
  static const double depthOffsetY = -30.0;

  // Base offset to center the manor
  static const double centerX = 576.0;
  static const double groundLevelY = 520.0;

  /// Projects a logical coordinate (x grid, floor, layer) to an Offset.
  /// x: horizontal grid position (0 is center)
  /// floor: vertical floor (0 is ground, negative is basement)
  /// layer: depth layer (0 is the manor cross-section, 1 is the environment)
  static Offset project(double x, int floor, int layer, {double scale = 1.0}) {
    // 1. Calculate base 2D position on the cross-section plane
    double px = centerX + (x * blockWidth);
    double py = groundLevelY - (floor * blockHeight);

    // 2. Apply oblique depth offset
    px += layer * depthOffsetX;
    py += layer * depthOffsetY;

    return Offset(px * scale, py * scale);
  }

  /// Returns the Rect for a room's front face
  static Rect getRoomRect(
    double x,
    int floor,
    int layer, {
    double widthBlocks = 1.0,
    double scale = 1.0,
  }) {
    final topLeft = project(x, floor, layer, scale: scale);
    return Rect.fromLTWH(
      topLeft.dx - (blockWidth * widthBlocks / 2 * scale),
      topLeft.dy - (blockHeight * scale),
      blockWidth * widthBlocks * scale,
      blockHeight * scale,
    );
  }
}
