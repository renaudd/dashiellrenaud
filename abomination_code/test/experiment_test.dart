import 'package:flutter_test/flutter_test.dart';
import 'package:abomination/state/game_state.dart';
import 'package:abomination/models/experiment.dart';

void main() {
  test('Experiment progress decrements during GameState tick', () {
    final state = GameState();

    state.initializeNewGame(
      firstName: "Test",
      lastName: "Master",
      estateName: "Test Manor",
      deathCause: DeathCause.trainCrash,
      age: 30,
      gilesTrait: GilesTrait.silent,
      objective: LifeObjective.science,
    );

    // Ensure we have an NPC to experiment on
    final npcId = state.npcs.first.id;
    final experiment = Experiment.create(npcId, ExperimentType.transmutation);
    final initialMinutes = experiment.minutesRemaining;

    state.startExperiment(experiment);
    state.setSpeed(GameSpeed.normal);

    // Perform a tick
    state.tick();

    expect(
      state.activeExperiments.first.minutesRemaining,
      equals(initialMinutes - 1),
    );
    expect(state.activeExperiments.first.progress, greaterThan(0));
  });
}
