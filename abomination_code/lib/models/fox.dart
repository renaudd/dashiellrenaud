import 'dart:math';
import 'package:flutter/material.dart';
import 'npc.dart';
import 'combat_stats.dart';
import 'schedule.dart';
import 'diet.dart';
import 'body_part.dart';

class FoxGenerator {
  static NPC createFox(String id) {
    final random = Random();
    final isMale = random.nextBool();
    final weightGrams = 3000 + random.nextInt(4000); // 3-7kg
    final ageWeeks = 50 + random.nextInt(200);

    return NPC(
      id: id,
      name: "Wild Fox",
      role: "Creature",
      age: (ageWeeks / 52).floor(),
      gender: isMale ? "Male" : "Female",
      nationality: "Estate",
      religion: "Nature",
      specimenType: "Fox",
      isPlayer: false,
      isResident: false,
      status: NPCStatus.idle,
      disposition: NPCDisposition.voluntary,
      currentRoomId: 'grounds',
      stats: {
        'strength': 15,
        'endurance': 25,
        'intelligence': 30,
        'willpower': 20,
        'agility': 40,
        'weightGrams': weightGrams,
      },
      appearance: NPCAppearance(
        hairStyle: HairStyle.none,
        facialHairStyle: FacialHairStyle.none,
        bodyColor: Colors.orange.shade800,
        hairColor: Colors.white,
        outfitColor: Colors.transparent,
      ),
      bodyParts: [
        BodyPart(type: BodyPartType.head, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.torso, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.rightLeg, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.leftLeg, health: 100, maxHealth: 100),
      ],
      combatStats: const CombatStats(
        health: 40,
        maxHealth: 40,
        attack: 8,
        defense: 5,
        speed: 1.5,
        movement: 1.2,
        distance: 0.5,
        accuracy: 0.8,
        cost: 0,
      ),
      inventory: [],
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
    );
  }
}
