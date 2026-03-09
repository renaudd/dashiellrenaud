import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../models/combat_log_entry.dart';
import '../models/npc.dart';
import '../models/combat_stats.dart';

enum CombatSide { player, enemy }

class FloatingMessage {
  final String text;
  final Color color;
  double lifetime; // in seconds
  double offsetY; // To stagger messages

  FloatingMessage({
    required this.text,
    required this.color,
    this.lifetime = 2.0,
    this.offsetY = 0.0,
  });
}

class Combatant {
  NPC npc;
  final CombatSide side;
  double x; // Horizontal position (0.0 to 200.0 feet)
  double y; // Vertical position (0.0 to 85.0 feet)
  double attackCooldown = 0.0;
  double freezeTimer = 0.0;
  String? targetId;
  bool isDead = false;
  final List<FloatingMessage> floatingMessages = [];

  Combatant({
    required this.npc,
    required this.side,
    this.x = 0.0,
    this.y = 42.5, // Center of 85ft field
  });

  // For continuous movement (Alphonse)
  double moveDirX = 0.0;
  double moveDirY = 0.0;
}

class Projectile {
  final String id;
  double x;
  double y;
  final double targetX;
  final double targetY;
  final CombatSide side;
  bool isExpired = false;

  Projectile({
    required this.id,
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
    required this.side,
  });

  void update(double dt) {
    final dx = targetX - x;
    final dy = targetY - y;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 0.2) {
      isExpired = true;
      return;
    }
    const speed = 20.0;
    x += (dx / len) * speed * dt;
    y += (dy / len) * speed * dt;
  }
}

class CombatManager extends ChangeNotifier {
  final List<Combatant> _combatants = [];
  final List<Projectile> _projectiles = [];
  final List<CombatLogEntry> _logs = [];
  double _actionPoints = 6.0; // Start with 6
  static const double maxAP = 10.0;
  static const double apPerSecond = 0.4; // Increased by 50% (was 0.15)
  static const double fieldWidth = 85.0;
  static const double fieldLength = 200.0;

  final List<NPC> _deck = [];
  final List<NPC> _hand = [];
  static const int maxHandSize = 5;

  // Simulation Mode Fields
  bool _isSimulation = false;
  double _aiActionPoints = 6.0;
  final List<NPC> _aiDeck = [];
  final List<NPC> _aiHand = [];

  double _fieldScroll = 0.0;
  bool _isScrolling = true;
  bool _isCombatActive = false;
  bool _isVictory = false;
  bool _isDefeat = false;

  final List<NPC> _killedEnemies = [];
  final Map<String, int> _accumulatedLoot = {'funds': 0, 'meat': 0};

  List<Combatant> get combatants => List.unmodifiable(_combatants);
  List<Projectile> get projectiles => List.unmodifiable(_projectiles);
  List<CombatLogEntry> get logs => List.unmodifiable(_logs);
  List<NPC> get hand => List.unmodifiable(_hand);
  double get actionPoints => _actionPoints;
  double get fieldScroll => _fieldScroll;
  bool get isCombatActive => _isCombatActive;
  bool get isVictory => _isVictory;
  bool get isDefeat => _isDefeat;
  List<NPC> get killedEnemies => List.unmodifiable(_killedEnemies);
  Map<String, int> get accumulatedLoot => Map.unmodifiable(_accumulatedLoot);
  bool get isSimulation => _isSimulation;
  double get aiActionPoints => _aiActionPoints;
  List<NPC> get aiHand => List.unmodifiable(_aiHand);

  void _addLog(String message, {CombatSide? side}) {
    _logs.insert(0, CombatLogEntry(message: message, side: side));
    if (_logs.length > 50) _logs.removeLast();
    notifyListeners();
  }

  void _addFloatingMessage(Combatant c, String text, Color color) {
    // Offset based on existing messages
    double offset = 0.0;
    if (c.floatingMessages.isNotEmpty) {
      offset = c.floatingMessages.map((m) => m.offsetY).reduce(max) + 20.0;
    }
    c.floatingMessages.add(
      FloatingMessage(text: text, color: color, offsetY: offset),
    );
    notifyListeners();
  }

  void prepareDeck(List<NPC> units) {
    _deck.clear();
    _deck.addAll(units);
    _deck.shuffle();
    _hand.clear();
    for (int i = 0; i < maxHandSize && _deck.isNotEmpty; i++) {
      _hand.add(_deck.removeAt(0));
    }
  }

  void drawCard() {
    if (_hand.length < maxHandSize && _deck.isNotEmpty) {
      final npc = _deck.removeAt(0);
      _hand.add(npc);
      if (_isSimulation) {
        // In simulation, keep the deck from running dry so the hand stays full
        _deck.add(
          npc.copyWith(
            id: '${npc.id}_refill_${DateTime.now().microsecondsSinceEpoch}',
          ),
        );
      }
      notifyListeners();
    }
  }

  void startCombat() {
    _isCombatActive = true;
    _isScrolling = true;
    _isDefeat = false;
    _isVictory = false;
    _killedEnemies.clear();
    _accumulatedLoot.updateAll((key, value) => 0);
    notifyListeners();
  }

  void setupSimulation(List<NPC> playerDeck, List<NPC> aiDeck) {
    _isSimulation = true;
    prepareDeck(playerDeck);

    _aiHand.clear();
    _aiDeck.clear();
    _aiDeck.addAll(aiDeck);
    _aiDeck.shuffle();
    for (int i = 0; i < maxHandSize && _aiDeck.isNotEmpty; i++) {
      _aiHand.add(_aiDeck.removeAt(0));
    }

    _aiActionPoints = 6.0;
  }

  void spawnUnit(NPC npc, CombatSide side, {double? x, double? y}) {
    final stats = npc.combatStats;
    if (stats == null) return;

    if (side == CombatSide.player && _actionPoints < stats.cost) return;

    if (side == CombatSide.player) {
      _actionPoints -= stats.cost;
      _hand.removeWhere((n) => n.id == npc.id);
      drawCard();
    }

    // Restrict placement to left half (0 to 100ft) and 0-85ft width
    double spawnX;
    if (side == CombatSide.player) {
      spawnX = (x ?? (_fieldScroll + 10.0)).clamp(
        _fieldScroll,
        _fieldScroll + 100.0,
      );
    } else {
      spawnX = x ?? (_fieldScroll + 190.0);
    }
    final spawnY = (y ?? (Random().nextDouble() * fieldWidth)).clamp(
      0.0,
      fieldWidth,
    );

    final combatant = Combatant(npc: npc, side: side, x: spawnX, y: spawnY);

    _combatants.add(combatant);

    // Trigger Horn abilities
    for (final ability in npc.abilities) {
      if (ability.type == AbilityType.horn) {
        _applyAbilityEffect(combatant, ability);
      }
    }

    notifyListeners();
  }

  void _aiDrawCard() {
    if (_aiHand.length < maxHandSize && _aiDeck.isNotEmpty) {
      final npc = _aiDeck.removeAt(0);
      _aiHand.add(npc);
      if (_isSimulation) {
        _aiDeck.add(
          npc.copyWith(
            id: '${npc.id}_refill_${DateTime.now().microsecondsSinceEpoch}',
          ),
        );
      }
      notifyListeners();
    }
  }

  void update(double dt) {
    if (!_isCombatActive) return;

    // 1. AP Generation
    _actionPoints = min(maxAP, _actionPoints + apPerSecond * dt);

    // 1b. Projectile Ticks
    for (var p in _projectiles) {
      p.update(dt);
    }
    _projectiles.removeWhere((p) => p.isExpired);

    // 2. Battlefield Scrolling
    final alphonse = _combatants.firstWhere(
      (c) => c.npc.isPlayer,
      orElse: () => _combatants.first,
    );

    // Dynamic Scrolling: If Alphonse is past the midpoint (100ft) of the visible field, scroll.
    final scrollThreshold = _fieldScroll + 100.0;
    if (alphonse.x > scrollThreshold) {
      final delta = alphonse.x - scrollThreshold;
      _fieldScroll += delta;
    }

    // Also handle automatic scrolling if no enemies (to reach the goal/objective)
    final hasEnemies = _combatants.any(
      (c) => c.side == CombatSide.enemy && !c.isDead,
    );
    if (!hasEnemies) {
      _isScrolling = true;
    } else {
      _isScrolling = false;
    }

    if (_isScrolling) {
      _fieldScroll += alphonse.npc.combatStats!.movement * dt * 5.0;
      // Shift Alphonse forward with scroll if they aren't moving manually
      if (alphonse.moveDirX == 0) {
        alphonse.x += alphonse.npc.combatStats!.movement * dt * 5.0;
      }
    }

    // 3. Unit Ticks
    for (final c in _combatants) {
      if (c.isDead) continue;

      // Update freeze timer
      if (c.freezeTimer > 0) {
        c.freezeTimer -= dt;
      }

      // Update floating messages
      c.floatingMessages.removeWhere((m) {
        m.lifetime -= dt;
        return m.lifetime <= 0;
      });

      if (c.freezeTimer > 0) continue; // Skip movement/attack while frozen

      _processUnitTick(c, dt);
    }

    // 4. Cleanup dead units
    _combatants.removeWhere((c) {
      if (c.isDead) {
        // Trigger Knell abilities before removal
        for (final ability in c.npc.abilities) {
          if (ability.type == AbilityType.knell) {
            _applyAbilityEffect(c, ability);
          }
        }
        // Return player units to deck
        if (c.side == CombatSide.player && !c.npc.isPlayer) {
          _deck.add(c.npc);
        } else if (c.side == CombatSide.enemy) {
          _killedEnemies.add(c.npc);
          // Roll for loot
          final rand = Random();
          if (rand.nextDouble() < 0.4) {
            _accumulatedLoot['funds'] =
                (_accumulatedLoot['funds'] ?? 0) + 5 + rand.nextInt(15);
          }
          if (rand.nextDouble() < 0.6) {
            _accumulatedLoot['meat'] =
                (_accumulatedLoot['meat'] ?? 0) + 1 + rand.nextInt(3);
          }
        }
        return true;
      }
      return false;
    });

    // 5. Replenish Hands (Continuous Draw)
    if (_hand.length < maxHandSize && _deck.isNotEmpty) {
      drawCard();
    }
    if (_aiHand.length < maxHandSize && _aiDeck.isNotEmpty) {
      _aiDrawCard();
    }

    // 6. AI Mirror Logic (Sim mode only)
    if (_isSimulation && _isCombatActive) {
      _aiActionPoints = min(maxAP, _aiActionPoints + apPerSecond * dt);

      // AI Spawning Strategy: Spawn the most expensive thing we can afford from hand
      if (_aiHand.isNotEmpty) {
        _aiHand.sort(
          (a, b) =>
              (b.combatStats?.cost ?? 0).compareTo(a.combatStats?.cost ?? 0),
        );
        for (var i = 0; i < _aiHand.length; i++) {
          final unit = _aiHand[i];
          final cost = unit.combatStats?.cost ?? 0;
          if (_aiActionPoints >= cost) {
            _aiActionPoints -= cost;
            _aiHand.removeAt(i);
            spawnUnit(unit, CombatSide.enemy);
            break; // One per tick
          }
        }
      }
    }

    // 7. Win/Loss Conditions
    final playerUnits = _combatants.where((c) => c.side == CombatSide.player);
    final enemyUnits = _combatants.where((c) => c.side == CombatSide.enemy);

    if (playerUnits.isEmpty ||
        !playerUnits.any((c) => c.npc.isPlayer && !c.isDead)) {
      _isDefeat = true;
      _isCombatActive = false;
      _projectiles.clear();
    } else if (enemyUnits.isEmpty) {
      // Victory immediately if all enemies dead
      _isVictory = true;
      _isCombatActive = false;
      _projectiles.clear();
    }

    notifyListeners();
  }

  void _processUnitTick(Combatant c, double dt) {
    if (c.isDead) return;
    final stats = c.npc.combatStats!;

    // A0. Attack Cooldown Ticking (Wind up while moving)
    c.attackCooldown -= dt;

    // 0. Collision Repulsion (Push units apart if they overlap)
    for (final other in _combatants) {
      if (other == c || other.isDead) continue;
      final otherStats = other.npc.combatStats!;
      final dx = other.x - c.x;
      final dy = other.y - c.y;
      final distSq = dx * dx + dy * dy;
      final minDist =
          stats.radius + otherStats.radius + 2.0; // Added 2.0ft minimum buffer
      if (distSq < minDist * minDist) {
        final dist = sqrt(distSq);
        final overlap = minDist - dist;
        // Decisive repulsion
        final pushFactor = (overlap / 2.0) + 0.1;
        final nx = dist > 0.001 ? dx / dist : (Random().nextDouble() * 2 - 1);
        final ny = dist > 0.001 ? dy / dist : (Random().nextDouble() * 2 - 1);
        c.x -= nx * pushFactor;
        c.y -= ny * pushFactor;
        other.x += nx * pushFactor;
        other.y += ny * pushFactor;
      }
    }

    // A. Special Charge
    if (c.npc.abilities.any((a) => a.type == AbilityType.special)) {
      final special = c.npc.abilities.firstWhere(
        (a) => a.type == AbilityType.special,
      );
      final chargeInc = dt / (special.chargeTime ?? 10.0);
      c.npc = c.npc.copyWith(
        specialCharge: min(1.0, c.npc.specialCharge + chargeInc),
      );
    }

    // B. Targeting
    List<Combatant> targets = _combatants
        .where((other) => other.side != c.side && !other.isDead)
        .toList();

    // Flyer rules: Only ranged/flyers can hit flyers
    if (stats.distance < 1.5 && !stats.isFlying) {
      // This is a ground melee unit (reach < 1.5ft)
      targets = targets.where((t) => !t.npc.combatStats!.isFlying).toList();
    }

    if (targets.isEmpty) {
      // Move forward/follow player input
      if (c.npc.id == 'alphonse' || c.npc.id == 'ai_mirror') {
        // Goalies stay at their posts (only move in Y if player controlled, but stationary otherwise)
        if (c.npc.isPlayer) {
          c.y += c.moveDirY * stats.movement * dt * 1.5;
        }
      } else if (c.npc.isPlayer) {
        c.x += c.moveDirX * stats.movement * dt * 1.5; // SLOWED (was 5.0)
        c.y += c.moveDirY * stats.movement * dt * 1.5;
      } else {
        final moveSpeed = stats.movement * dt * 1.5; // SLOWED (was 5.0)
        if (c.side == CombatSide.player) {
          c.x += moveSpeed;
        } else {
          c.x -= moveSpeed;
        }
      }
      // Boundary enforcement (Full field length/width)
      if (c.npc.id == 'alphonse') {
        c.x = 10.0;
      } else if (c.npc.id == 'ai_mirror') {
        c.x = fieldLength - 10.0;
      } else {
        c.x = c.x.clamp(_fieldScroll, _fieldScroll + fieldLength * 10);
      }
      c.y = c.y.clamp(0.0, fieldWidth);
      return;
    }

    // Targeting Logic:
    // 1. If we have a targetId and that target is alive and in range, keep it.
    // 2. Otherwise, find the nearest alive enemy and set it as targetId.
    Combatant? target;
    if (c.targetId != null) {
      target = _combatants.firstWhereOrNull(
        (t) => t.npc.id == c.targetId && !t.isDead && t.side != c.side,
      );

      if (target != null) {
        final dist = sqrt(pow(target.x - c.x, 2) + pow(target.y - c.y, 2));
        final rangeInFeet = stats.distance * 3.28;
        final myRadius = stats.radius;
        final targetRadius = target.npc.combatStats?.radius ?? 1.0;

        // If not in range yet, we might want to switch to a closer target if one appeared
        if (dist - myRadius - targetRadius > rangeInFeet) {
          target = null; // Forces re-targeting below
        }
      }
    }

    if (target == null) {
      // Find nearest target (using Euclidean distance in feet)
      targets.sort((a, b) {
        final distA = sqrt(pow(a.x - c.x, 2) + pow(a.y - c.y, 2));
        final distB = sqrt(pow(b.x - c.x, 2) + pow(b.y - c.y, 2));
        return distA.compareTo(distB);
      });
      target = targets.first;
      c.targetId = target.npc.id;
    }

    final distToTarget = sqrt(pow(target.x - c.x, 2) + pow(target.y - c.y, 2));

    // C. Movement/Attack Logic
    // Convert weapon range (meters) to feet for the 85x200 field. 1m ~ 3.28ft.
    final rangeInFeet = stats.distance * 3.28;
    final myRadius = stats.radius;
    final targetRadius = target.npc.combatStats?.radius ?? 1.0;

    // Edge-to-edge distance check (Reliably hits even if repulsive forces push units apart)
    if (distToTarget - myRadius - targetRadius > rangeInFeet) {
      if (c.npc.id == 'alphonse' || c.npc.id == 'ai_mirror') {
        // Goalies don't approach targets
        return;
      }
      // Approach target
      final dx = target.x - c.x;
      final dy = target.y - c.y;
      final len = sqrt(dx * dx + dy * dy);
      c.x +=
          (dx / len) * stats.movement * dt * 8.0; // Increased by 50% (was 4.0)
      c.y += (dy / len) * stats.movement * dt * 8.0;
    } else {
      // Within range, attack if ready
      if (c.attackCooldown <= 0) {
        _performAttack(c, target);
        c.attackCooldown = stats.speed * 1.2; // Faster combat (was 1.2)
      }

      // Auto-fire special ability if charged
      if (c.npc.specialCharge >= 1.0) {
        executeSpecial(c.npc.id);
      }
    }

    // Boundary enforcement (Full field - slightly tighter on Y)
    c.x = c.x.clamp(_fieldScroll, _fieldScroll + fieldLength * 10);
    c.y = c.y.clamp(2.0, fieldWidth - 2.0); // Keep units clearly on the grit
  }

  void _performAttack(Combatant attacker, Combatant target) {
    final stats = attacker.npc.combatStats!;
    final targetStats = target.npc.combatStats!;

    // Spawn projectile if ranged
    if (stats.distance > 1.0) {
      _projectiles.add(
        Projectile(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          x: attacker.x,
          y: attacker.y,
          targetX: target.x,
          targetY: target.y,
          side: attacker.side,
        ),
      );
    }

    // Accuracy check
    if (Random().nextDouble() > stats.accuracy) {
      // Miss!
      _addLog(
        '${attacker.npc.name} missed ${target.npc.name}!',
        side: attacker.side,
      );
      _addFloatingMessage(attacker, 'MISS', Colors.white70);
      return;
    }

    // Damage calculation
    double damage = max(
      1.0,
      (stats.attack - targetStats.defense) * 1.5,
    ); // 1.5x DAMAGE BOOST

    // Swarm damage capping
    if (targetStats.swarmSize > 0) {
      final maxDamagePerHit = targetStats.maxHealth / targetStats.swarmSize;
      damage = min(damage, maxDamagePerHit);
    }

    _addLog(
      '${attacker.npc.name} hit ${target.npc.name} for ${damage.toStringAsFixed(1)} damage.',
      side: attacker.side,
    );

    _addFloatingMessage(target, '-${damage.toInt()}', Colors.red);
    _addFloatingMessage(
      attacker,
      'HIT',
      attacker.side == CombatSide.player
          ? Colors.cyanAccent
          : Colors.orangeAccent,
    );

    // Apply damage to target NPC
    final newHealth = max(0.0, targetStats.health - damage);
    target.npc = target.npc.copyWith(
      combatStats: targetStats.copyWith(health: newHealth),
    );

    if (newHealth <= 0) {
      target.isDead = true;
      _addLog('${target.npc.name} has been defeated!', side: target.side);
    }

    // Handle Trait effects (e.g., Sniper accuracy boost)
    for (final ability in attacker.npc.abilities) {
      if (ability.type == AbilityType.trait &&
          ability.effectData['on_hit'] == true) {
        _applyAbilityEffect(attacker, ability);
      }
    }
  }

  void _applyAbilityEffect(Combatant c, Ability ability) {
    switch (ability.id) {
      case 'accuracy_boost':
        final stats = c.npc.combatStats!;
        c.npc = c.npc.copyWith(
          combatStats: stats.copyWith(
            accuracy: min(1.0, stats.accuracy + 0.05),
          ),
        );
        _addLog('${c.npc.name} accuracy boosted!', side: c.side);
        break;

      case 'horn_heal':
        final healAmount = (ability.effectData['heal'] as num).toDouble();
        final range = (ability.effectData['range'] as num).toDouble();
        final friendlies = _combatants
            .where(
              (other) => other.side == c.side && other != c && !other.isDead,
            )
            .toList();
        if (friendlies.isNotEmpty) {
          friendlies.sort(
            (a, b) => (a.x - c.x).abs().compareTo((b.x - c.x).abs()),
          );
          final nearest = friendlies.first;
          if ((nearest.x - c.x).abs() <= range) {
            final stats = nearest.npc.combatStats!;
            nearest.npc = nearest.npc.copyWith(
              combatStats: stats.copyWith(
                health: min(stats.maxHealth, stats.health + healAmount),
              ),
            );
            _addLog(
              '${c.npc.name} healed ${nearest.npc.name} for ${healAmount.toStringAsFixed(1)}.',
              side: c.side,
            );
          }
        }
        break;

      case 'execute_low_health':
        final threshold = (ability.effectData['threshold'] as num).toDouble();
        final targets = _combatants
            .where((other) => other.side != c.side && !other.isDead)
            .toList();
        if (targets.isNotEmpty) {
          targets.sort((a, b) {
            final distA = sqrt(pow(a.x - c.x, 2) + pow(a.y - c.y, 2));
            final distB = sqrt(pow(b.x - c.x, 2) + pow(b.y - c.y, 2));
            return distA.compareTo(distB);
          });

          final target = targets.firstWhereOrNull((t) {
            final dist = sqrt(pow(t.x - c.x, 2) + pow(t.y - c.y, 2));
            final tStats = t.npc.combatStats!;
            return dist <= 10.0 &&
                (tStats.health / tStats.maxHealth) < threshold;
          });

          if (target != null) {
            final stats = target.npc.combatStats!;
            target.npc = target.npc.copyWith(
              combatStats: stats.copyWith(health: 0),
            );
            target.isDead = true;
            _addLog('${c.npc.name} executed ${target.npc.name}!', side: c.side);
          }
        }
        break;

      case 'push_back':
        final pushDist = (ability.effectData['push'] as num).toDouble();
        final damage = (ability.effectData['damage'] as num).toDouble();
        final targets = _combatants
            .where((other) => other.side != c.side && !other.isDead)
            .toList();
        for (final target in targets) {
          if ((target.x - c.x).abs() <= c.npc.combatStats!.distance) {
            final dir = target.x > c.x ? 1.0 : -1.0;
            target.x += dir * pushDist;
            final stats = target.npc.combatStats!;
            target.npc = target.npc.copyWith(
              combatStats: stats.copyWith(
                health: max(0, stats.health - damage),
              ),
            );
            if (target.npc.combatStats!.health <= 0) {
              target.isDead = true;
              _addLog(
                '${target.npc.name} was crushed by the push!',
                side: target.side,
              );
            } else {
              _addLog(
                '${c.npc.name} pushed back ${target.npc.name}.',
                side: c.side,
              );
            }
          }
        }
        break;

      case 'freeze_line':
        final duration = (ability.effectData['freeze_duration'] as num)
            .toDouble();
        final targets = _combatants
            .where((other) => other.side != c.side && !other.isDead)
            .toList();
        // Automatically target furthest enemy as per spec
        if (targets.isNotEmpty) {
          targets.sort(
            (a, b) => (b.x - c.x).abs().compareTo((a.x - c.x).abs()),
          );
          final furthest = targets.first;
          // Simple line logic: freeze everyone between c and furthest
          final minX = min(c.x, furthest.x);
          final maxX = max(c.x, furthest.x);
          for (final target in targets) {
            if (target.x >= minX && target.x <= maxX) {
              // Add freeze status implementation or placeholder
              // For now, let's just pause them by setting a flag or status
              _applyFreeze(target, duration);
              _addLog(
                '${target.npc.name} was frozen for ${duration.toStringAsFixed(1)}s!',
                side: target.side,
              );
            }
          }
        }
        break;

      case 'ap_steal':
        final amount = (ability.effectData['steal_ap'] as num).toDouble();
        // In this simplified model, AP is global for the player.
        // If we want to simulate enemy AP, we could decrease it there,
        // but for now we just give it to the player.
        _actionPoints = min(maxAP, _actionPoints + amount);
        _addLog(
          '${c.npc.name} stole ${amount.toStringAsFixed(1)} Action Points!',
          side: c.side,
        );
        break;
    }
  }

  void _applyFreeze(Combatant target, double duration) {
    // This requires a freeze state on the combatant or NPC status effect.
    // For now, let's just make them "dead" for a duration by setting a cooldown
    target.attackCooldown = max(target.attackCooldown, duration);
    target.freezeTimer = duration;
  }

  bool canExecuteSpecial(String combatantId) {
    final c = _combatants.firstWhere(
      (c) => c.npc.id == combatantId,
      orElse: () => _combatants.first,
    );
    if (c.npc.specialCharge < 1.0) return false;

    final special = c.npc.abilities.firstWhere(
      (a) => a.type == AbilityType.special,
      orElse: () => const Ability(
        id: 'none',
        name: 'None',
        type: AbilityType.trait,
        description: 'No ability',
      ),
    );
    if (special.id == 'none') return false;

    switch (special.id) {
      case 'execute_low_health':
        final threshold = (special.effectData['threshold'] as num).toDouble();
        final range = (c.npc.combatStats?.distance ?? 1.0) * 3.28;
        return _combatants.any(
          (other) =>
              other.side != c.side &&
              !other.isDead &&
              (other.x - c.x).abs() <= range &&
              (other.npc.combatStats!.health /
                      other.npc.combatStats!.maxHealth) <
                  threshold,
        );
      case 'master_command':
      case 'captain_rally':
      case 'monk_chant':
        final range = (special.effectData['range'] as num).toDouble();
        return _combatants.any(
          (other) =>
              other.side == c.side &&
              other != c &&
              !other.isDead &&
              (other.x - c.x).abs() <= range,
        );
      case 'push_back':
      case 'captain_strike':
      case 'slinger_cloud':
      case 'digger_bury':
      case 'hound_leap':
      case 'golem_slam':
      case 'corpse_arc':
        final range = (c.npc.combatStats?.distance ?? 1.0) * 3.28;
        return _combatants.any(
          (other) =>
              other.side != c.side &&
              !other.isDead &&
              (other.x - c.x).abs() <= range,
        );
      case 'freeze_line':
      case 'ap_steal':
        // These are always valid if there are ANY enemies
        return _combatants.any(
          (other) => other.side != c.side && !other.isDead,
        );
      default:
        return true;
    }
  }

  void executeSpecial(String combatantId) {
    if (!canExecuteSpecial(combatantId)) return;
    
    final c = _combatants.firstWhere(
      (c) => c.npc.id == combatantId,
      orElse: () => _combatants.first,
    );

    final special = c.npc.abilities.firstWhere(
      (a) => a.type == AbilityType.special,
    );
    _applyAbilityEffect(c, special);

    c.npc = c.npc.copyWith(specialCharge: 0.0);
    notifyListeners();
  }

  void setPlayerTarget(String enemyId) {
    // Force Alphonse or units to target a specific enemy
    final alphonse = _combatants.firstWhere((c) => c.npc.isPlayer);
    alphonse.targetId = enemyId;
  }

  void movePlayer(double targetX, double targetY) {
    // Restrict to player half (0 to 100ft) and 0-85ft width
    final alphonse = _combatants.firstWhere((c) => c.npc.isPlayer);
    alphonse.x = targetX.clamp(_fieldScroll, _fieldScroll + 100.0);
    alphonse.y = targetY.clamp(0.0, fieldWidth);
    notifyListeners();
  }
}
