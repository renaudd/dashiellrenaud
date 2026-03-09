import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/npc.dart';

class CharacterBlobRenderer extends StatelessWidget {
  final NPC npc;
  final double size;
  final bool isWalking;
  final bool isIdle;
  final double bubbleOffset;

  const CharacterBlobRenderer({
    super.key,
    required this.npc,
    this.size = 40,
    this.isWalking = false,
    this.isIdle = true,
    this.bubbleOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final appearance = npc.appearance;

    return SizedBox(
      width: size,
      height: size,
      child: Transform.rotate(
        angle: npc.status == NPCStatus.fainted ? math.pi / 2 : 0,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if ((npc.combatStats?.swarmSize ?? 0) > 0)
              _buildSwarm(npc, size)
            else if (npc.specimenType == 'Rat' ||
                npc.specimenType == 'Bat' ||
                npc.specimenType == 'FlyingRat')
              _buildAnimal(npc.specimenType, size)
            else ...[
              // Shadow
              Positioned(
                bottom: 2,
                child: Container(
                  width: size * 0.6,
                  height: size * 0.15,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(size * 0.3, size * 0.07),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 2,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

              // Body (Rounded Rect)
              _buildAnimatedContainer(
                child: Container(
                  width: size * 0.5,
                  height: size * 0.45,
                  decoration: BoxDecoration(
                    color: appearance.outfitColor,
                    borderRadius: BorderRadius.circular(size * 0.15),
                    border: Border.all(color: Colors.black12, width: 0.5),
                  ),
                ),
                offset: Offset(0, size * 0.1),
              ),

              // Head (Circle)
              _buildAnimatedContainer(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Skin
                    Container(
                      width: size * 0.4,
                      height: size * 0.4,
                      decoration: BoxDecoration(
                        color: appearance.bodyColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12, width: 0.5),
                      ),
                    ),

                    // Hair (Back)
                    if (appearance.hairStyle != HairStyle.none &&
                        appearance.hairStyle != HairStyle.bald)
                      _buildHair(appearance, size, isBack: true),

                    // Eyes
                    Positioned(
                      top: size * 0.18,
                      left: size * 0.1,
                      child: _buildEye(
                        npc.status == NPCStatus.broken
                            ? Colors.red
                            : appearance.eyeColor,
                        size,
                      ),
                    ),
                    Positioned(
                      top: size * 0.18,
                      right: size * 0.1,
                      child: _buildEye(
                        npc.status == NPCStatus.broken
                            ? Colors.red
                            : appearance.eyeColor,
                        size,
                      ),
                    ),

                    // Facial Hair
                    if (appearance.facialHairStyle != FacialHairStyle.none)
                      _buildFacialHair(appearance, size),

                    // Hair (Front)
                    if (appearance.hairStyle != HairStyle.none &&
                        appearance.hairStyle != HairStyle.bald)
                      _buildHair(appearance, size, isBack: false),
                  ],
                ),
                offset: Offset(0, -size * 0.15),
                delayFactor: 0.5,
              ),

              // Gear / Items
              if (npc.specimenType == 'Human')
                ...npc.equippedVisuals.map(
                  (item) => _buildItemBlob(item, size),
                ),
            ],

            // Speech Bubble
            if (npc.currentThought != null && npc.currentThought!.isNotEmpty)
              _buildSpeechBubble(npc.currentThought!, size),
          ],
        ),
      ),
    );
  }

  Widget _buildSwarm(NPC npc, double size) {
    final swarmMax = npc.combatStats?.swarmSize ?? 0;
    final healthRatio =
        (npc.combatStats?.health ?? 0) / (npc.combatStats?.maxHealth ?? 1);
    final currentlyAlive = (healthRatio * swarmMax).ceil();

    return Stack(
      alignment: Alignment.center,
      children: List.generate(currentlyAlive, (index) {
        // Offset each member of the swarm
        final double offsetX = (index % 2 == 0 ? -1.0 : 1.0) * (size * 0.2);
        final double offsetY = (index < 2 ? -1.0 : 1.0) * (size * 0.2);

        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: _buildAnimal(npc.specimenType, size * 0.5),
        );
      }),
    );
  }

  Widget _buildAnimal(String type, double size) {
    if (type == 'Bat') return _buildBat(size);
    if (type == 'Rat') return _buildRat(size);
    if (type == 'FlyingRat') return _buildFlyingRat(size);
    // Fallback blob
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildRat(double size) {
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tail
          Positioned(
            right: 0,
            bottom: size * 0.2,
            child: Container(
              width: size * 0.6,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.pink.shade100,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // Body
          Container(
            width: size * 0.7,
            height: size * 0.4,
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.circular(size * 0.2),
            ),
          ),
          // Ears
          Positioned(
            left: size * 0.1,
            top: size * 0.2,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: Colors.pink.shade100,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Eyes
          Positioned(
            left: size * 0.15,
            top: size * 0.35,
            child: Container(
              width: 2,
              height: 2,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBat(double size) {
    return __buildBatLike(size, Colors.brown.shade900, Colors.black87);
  }

  Widget _buildFlyingRat(double size) {
    return __buildBatLike(
      size * 1.3,
      Colors.blueGrey.shade900,
      Colors.black,
      isStrange: true,
    );
  }

  Widget __buildBatLike(
    double size,
    Color bodyColor,
    Color wingColor, {
    bool isStrange = false,
  }) {
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wings (Segmented for strange creatures)
          if (isStrange)
            for (int i = 0; i < 3; i++)
              Transform.rotate(
                angle: (i - 1) * 0.2,
                child: Container(
                  width: size * (1.1 - i * 0.1),
                  height: size * 0.35,
                  decoration: BoxDecoration(
                    color: wingColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(size * 0.15),
                  ),
                ),
              )
          else
            Container(
              width: size,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: wingColor,
                borderRadius: BorderRadius.circular(size * 0.1),
              ),
            ),
          // Body
          Container(
            width: isStrange ? size * 0.4 : size * 0.3,
            height: isStrange ? size * 0.6 : size * 0.5,
            decoration: BoxDecoration(
              color: bodyColor,
              borderRadius: BorderRadius.circular(size * 0.15),
            ),
          ),
          // Head / Ears
          Positioned(
            top: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEarPiece(bodyColor, isStrange),
                SizedBox(width: isStrange ? 8 : 4),
                _buildEarPiece(bodyColor, isStrange),
              ],
            ),
          ),
          // Eyes (Glowing)
          Positioned(
            top: size * (isStrange ? 0.15 : 0.2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isStrange ? 4 : 2,
                  height: isStrange ? 4 : 2,
                  decoration: BoxDecoration(
                    color: isStrange ? Colors.purpleAccent : Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: isStrange ? 8 : 4),
                Container(
                  width: isStrange ? 4 : 2,
                  height: isStrange ? 4 : 2,
                  decoration: BoxDecoration(
                    color: isStrange ? Colors.purpleAccent : Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          if (isStrange)
            // Extra strange glow/appendage
            Positioned(
              bottom: 0,
              child: Container(
                width: size * 0.15,
                height: size * 0.3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bodyColor, Colors.purple.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEarPiece(Color color, bool isStrange) {
    return Container(
      width: isStrange ? 6 : 4,
      height: isStrange ? 12 : 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isStrange ? 4 : 2),
        ),
      ),
    );
  }

  Widget _buildSpeechBubble(String thought, double size) {
    return Positioned(
      bottom: size * 0.9 + bubbleOffset, // Float above the head
      child: _BobbingAnimation(
        isWalking: isWalking,
        isIdle: isIdle,
        delayFactor: 0.2, // Match head bob roughly
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          constraints: BoxConstraints(maxWidth: size * 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                thought,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              Transform.translate(
                offset: const Offset(0, 2),
                child: CustomPaint(
                  size: const Size(6, 4),
                  painter: _BubbleTailPainter(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedContainer({
    required Widget child,
    required Offset offset,
    double delayFactor = 0,
  }) {
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      isBroken: npc.status == NPCStatus.broken,
      delayFactor: delayFactor,
      child: Transform.translate(offset: offset, child: child),
    );
  }

  Widget _buildEye(Color color, double size) {
    return Container(
      width: size * 0.06,
      height: size * 0.06,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildHair(
    NPCAppearance appearance,
    double size, {
    required bool isBack,
  }) {
    if (isBack &&
        appearance.hairStyle != HairStyle.long &&
        appearance.hairStyle != HairStyle.bob) {
      return const SizedBox.shrink();
    }

    double width = size * 0.42;
    double height = size * 0.15;
    double top = -size * 0.02;
    BorderRadius borderRadius = BorderRadius.vertical(
      top: Radius.circular(size * 0.2),
    );

    switch (appearance.hairStyle) {
      case HairStyle.short:
        height = size * 0.12;
        break;
      case HairStyle.long:
        if (isBack) {
          height = size * 0.45;
          top = size * 0.05;
          borderRadius = BorderRadius.all(Radius.circular(size * 0.1));
        }
        break;
      case HairStyle.bob:
        if (isBack) {
          height = size * 0.35;
          top = size * 0.05;
          width = size * 0.48;
          borderRadius = BorderRadius.vertical(
            top: Radius.circular(size * 0.1),
            bottom: Radius.circular(size * 0.15),
          );
        }
        break;
      case HairStyle.messy:
        height = size * 0.18;
        top = -size * 0.05;
        width = size * 0.45;
        break;
      default:
        break;
    }

    return Positioned(
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: appearance.hairColor,
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  Widget _buildFacialHair(NPCAppearance appearance, double size) {
    double width = size * 0.25;
    double height = size * 0.05;
    double bottom = size * 0.05;
    BorderRadius borderRadius = BorderRadius.circular(size * 0.02);

    switch (appearance.facialHairStyle) {
      case FacialHairStyle.beard:
        height = size * 0.18;
        width = size * 0.32;
        borderRadius = BorderRadius.vertical(
          bottom: Radius.circular(size * 0.15),
        );
        break;
      case FacialHairStyle.mustache:
        width = size * 0.28;
        height = size * 0.04;
        bottom = size * 0.08;
        break;
      case FacialHairStyle.goatee:
        width = size * 0.12;
        height = size * 0.1;
        break;
      default:
        break;
    }

    return Positioned(
      bottom: bottom,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: appearance.hairColor,
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  Widget _buildItemBlob(String item, double size) {
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.8, // Distinct orbit
      child: Transform.translate(
        offset: Offset(size * 0.35, size * 0.1),
        child: Container(
          width: size * 0.25,
          height: size * 0.25,
          decoration: BoxDecoration(
            color: Colors.blueGrey,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(1, 1),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.inventory_2, size: 6, color: Colors.white70),
          ),
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _BobbingAnimation extends StatefulWidget {
  final Widget child;
  final bool isWalking;
  final bool isIdle;
  final bool isBroken;
  final double delayFactor;

  const _BobbingAnimation({
    required this.child,
    required this.isWalking,
    required this.isIdle,
    this.isBroken = false,
    required this.delayFactor,
  });

  @override
  State<_BobbingAnimation> createState() => _BobbingAnimationState();
}

class _BobbingAnimationState extends State<_BobbingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double bobValue = math.sin(
          (_controller.value + widget.delayFactor) * math.pi * 2,
        );

        double verticalOffset = 0;
        double rotation = 0;

        if (widget.isWalking) {
          verticalOffset = bobValue * 2;
          rotation = bobValue * 0.05;
        } else if (widget.isIdle) {
          verticalOffset = bobValue * 0.5;
        }

        if (widget.isBroken) {
          // Add jitter
          verticalOffset += (math.Random().nextDouble() - 0.5) * 2;
          rotation += (math.Random().nextDouble() - 0.5) * 0.1;
        }

        return Transform.translate(
          offset: Offset(0, verticalOffset),
          child: Transform.rotate(angle: rotation, child: widget.child),
        );
      },
      child: widget.child,
    );
  }
}
