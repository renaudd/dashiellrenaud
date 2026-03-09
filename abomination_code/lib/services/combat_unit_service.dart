import '../models/npc.dart';
import 'combat_unit_factory.dart';

class CombatUnitService {
  static List<NPC> getInitialDeck() {
    return [CombatUnitFactory.createFlaubert()];
  }

  static NPC createUnit(String type) {
    switch (type) {
      case 'giles':
        return CombatUnitFactory.createFlaubert();
      case 'militia':
        return CombatUnitFactory.createMilitia();
      case 'captain':
        return CombatUnitFactory.createBanditCaptain();
      case 'peasant':
        return CombatUnitFactory.createPeasant();
      case 'goon':
        return CombatUnitFactory.createGoon();
      case 'rats':
        return CombatUnitFactory.createRatsUnit();
      case 'bats':
        return CombatUnitFactory.createBatsUnit();
      case 'flying_rat':
        return CombatUnitFactory.createWingedRat();
      case 'sniper':
        return CombatUnitFactory.createSniper();
      case 'bully':
        return CombatUnitFactory.createBully();
      case 'stitched_horror':
        return CombatUnitFactory.createStitchedHorror();
      case 'galvanized_corpse':
        return CombatUnitFactory.createGalvanizedCorpse();
      case 'chemical_slinger':
        return CombatUnitFactory.createChemicalSlinger();
      case 'shadow_creeper':
        return CombatUnitFactory.createShadowCreeper();
      case 'gravedigger':
        return CombatUnitFactory.createGravedigger();
      case 'plague_monk':
        return CombatUnitFactory.createPlagueMonk();
      case 'inquisitor':
        return CombatUnitFactory.createInquisitor();
      case 'iron_maiden':
        return CombatUnitFactory.createIronMaiden();
      case 'flesh_hound':
        return CombatUnitFactory.createFleshHound();
      case 'alchemical_golem':
        return CombatUnitFactory.createAlchemicalGolem();
      default:
        return CombatUnitFactory.createGoon();
    }
  }

}
