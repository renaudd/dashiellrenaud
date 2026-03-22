import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../../services/kitchen_service.dart';
import '../../services/science_service.dart';
import '../../services/task_service.dart';
import '../../models/game_item.dart';
import '../widgets/game_item_renderer.dart';

class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        title: Text(
          'THE STUDY',
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
      body: Consumer<GameState>(
        builder: (context, state, child) {
          final researchItems = state.inventory
              .where(
                (item) =>
                    item.category == ItemCategory.knowledge ||
                    item.category == ItemCategory.specimen ||
                    item.type == 'unreviewed_document' ||
                    item.name == 'Old Notes' ||
                    item.name == 'Live Rat',
              )
              .toList();

          return Container(
            decoration: BoxDecoration(
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
            child: Row(
              children: [
                // Left Panel: Stats & Tiers
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: const Color(
                              0xFFC4B89B,
                            ).withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('COLLECTED KNOWLEDGE'),
                          const SizedBox(height: 24),
                          _buildKnowledgeItem(context, state, 'Anatomy'),
                          _buildKnowledgeItem(context, state, 'Zoology'),
                          _buildKnowledgeItem(context, state, 'Medicine'),
                          _buildKnowledgeItem(context, state, 'Chemistry'),
                          _buildKnowledgeItem(context, state, 'Psychology'),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(
                                  0xFFC4B89B,
                                ).withValues(alpha: 0.3),
                              ),
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL VOLUMES',
                                  style: GoogleFonts.playfairDisplay(
                                    color: const Color(0xFFC4B89B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.inventory
                                      .where(
                                        (i) =>
                                            i.name.contains('Note') ||
                                            i.name.contains('Book'),
                                      )
                                      .length
                                      .toString(),
                                  style: GoogleFonts.oldStandardTt(
                                    color: const Color(0xFFE5D5B0),
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Right Panel: Available Specimens/Notes
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildExperimentalRecipes(context, state),
                          const SizedBox(height: 32),
                          _buildSectionTitle('SCIENCE ACTIVITIES'),
                          const SizedBox(height: 16),
                          _buildScienceActivities(context, state),
                          const SizedBox(height: 32),
                          _buildSectionTitle('AVAILABLE MATERIALS'),
                          const SizedBox(height: 24),
                          if (researchItems.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 32.0,
                              ),
                              child: Center(
                                child: Text(
                                  'No research materials available.\nClean rooms or hunt to find items.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.oldStandardTt(
                                    color: Colors.white24,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 2.5,
                                  ),
                              itemCount: researchItems.length,
                              itemBuilder: (context, index) {
                                final item = researchItems[index];
                                return _buildResearchTile(context, state, item);
                              },
                            ),
                          const SizedBox(height: 32),
                          _buildSectionTitle('RESEARCH QUEUE'),
                          const SizedBox(height: 16),
                          _buildResearchQueue(context, state),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        color: const Color(0xFFE5D5B0),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildKnowledgeItem(
    BuildContext context,
    GameState state,
    String discipline,
  ) {
    final level = state.getKnowledgeLevel(discipline);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                discipline.toUpperCase(),
                style: GoogleFonts.oldStandardTt(
                  color: const Color(0xFFC4B89B),
                  fontSize: 14,
                ),
              ),
              Text(
                level.toStringAsFixed(1),
                style: GoogleFonts.oldStandardTt(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (level / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC4B89B)),
            minHeight: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildResearchTile(
    BuildContext context,
    GameState state,
    GameItem item,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.3),
        ),
        color: Colors.black.withValues(alpha: 0.3),
      ),
      child: InkWell(
        onTap: () {
          state.addResearchToQueue(item.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name.toUpperCase()} ENQUEUED FOR RESEARCH'),
              backgroundColor: const Color(0xFFC4B89B),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              GameItemRenderer(item: item, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category == ItemCategory.specimen
                          ? item.name.toUpperCase()
                          : _getPrettyItemName(item),
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFE5D5B0),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item.category == ItemCategory.knowledge
                          ? 'EXPAND KNOWLEDGE'
                          : item.category == ItemCategory.specimen
                          ? 'PREPARE FOR STUDY'
                          : 'ANALYZE',
                      style: GoogleFonts.oldStandardTt(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExperimentalRecipes(BuildContext context, GameState state) {
    final experimentalRecipes = KitchenService.getAvailableRecipes()
        .where((r) => r.isExperimental)
        .toList();

    return Column(
      children: experimentalRecipes.map((recipe) {
        bool canCraft = true;
        recipe.ingredients.forEach((res, amount) {
          if ((state.resources[res] ?? 0) < amount) canCraft = false;
        });

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
            ),
            color: Colors.black.withValues(alpha: 0.3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFFC4B89B),
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            recipe.name.toUpperCase(),
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFE5D5B0),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: recipe.ingredients.entries.map((e) {
                          final has = (state.resources[e.key] ?? 0) >= e.value;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '${_getPrettyTypeName(e.key)}: ${e.value}',
                              style: GoogleFonts.oldStandardTt(
                                color: has
                                    ? const Color(0xFFC4B89B)
                                    : Colors.red,
                                fontSize: 9,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: canCraft
                      ? () {
                          state.addExperimentalRecipeToQueue(recipe.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${recipe.name.toUpperCase()} ENQUEUED FOR STUDY',
                              ),
                              backgroundColor: const Color(0xFFC4B89B),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: canCraft
                          ? const Color(0xFFC4B89B)
                          : Colors.white10,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    'STUDY & PREPARE',
                    style: GoogleFonts.playfairDisplay(
                      color: canCraft
                          ? const Color(0xFFE5D5B0)
                          : Colors.white12,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScienceActivities(BuildContext context, GameState state) {
    final activities = ScienceService.getAvailableActivities();

    return Column(
      children: activities.map<Widget>((activity) {
        bool canStart = true;
        activity.ingredients.forEach((ing, count) {
          num available =
              state.inventory
                  .where((i) {
                    if (ing == 'meat') {
                      return i.type.contains('meat') ||
                          i.category == ItemCategory.specimen;
                    }
                    if (ing == 'specimen' || ing == 'rat_specimen') {
                      return i.type == 'rat' ||
                          i.type == 'bat' ||
                          i.type == 'chicken' ||
                          i.category == ItemCategory.specimen;
                    }
                    if (ing == 'unreviewed_document') {
                      return i.type == 'unreviewed_document' || i.category == ItemCategory.knowledge;
                    }
                    return i.type == ing;
                  })
                  .fold(0, (sum, i) => sum + i.quantity) +
              ((ing == 'specimen' || ing == 'rat_specimen')
                  ? (state.resources['rat'] ?? 0) +
                        (state.resources['bat'] ?? 0) +
                        (state.resources['chicken'] ?? 0)
                  : (state.resources[ing] ?? 0));
          if (available < count) canStart = false;
        });

        final metadata = TaskService.getMetadata(activity.type);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
            ),
            color: Colors.black.withValues(alpha: 0.3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity.name.toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      "${activity.baseDurationMinutes ~/ 60}H ${activity.baseDurationMinutes % 60}M",
                      style: GoogleFonts.oldStandardTt(
                        color: const Color(0xFFC4B89B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  activity.outcomeDescription,
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.7),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REQUIRED MATERIALS',
                            style: GoogleFonts.oswald(
                              fontSize: 9,
                              color: const Color(
                                0xFFE5D5B0,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: activity.ingredients.entries.map<Widget>((
                              e,
                            ) {
                              final ing = e.key;
                              final count = e.value;
                              num available =
                                  state.inventory
                                      .where((i) {
                                        if (ing == 'meat') {
                                          return i.type.contains('meat') ||
                                              i.category ==
                                                  ItemCategory.specimen;
                                        }
                                        if (ing == 'specimen' ||
                                            ing == 'rat_specimen') {
                                          return i.type == 'rat' ||
                                              i.type == 'bat' ||
                                              i.type == 'chicken' ||
                                              i.category ==
                                                  ItemCategory.specimen;
                                        }
                                        return i.type == ing;
                                      })
                                      .fold(0, (sum, i) => sum + i.quantity) +
                                  ((ing == 'specimen' || ing == 'rat_specimen')
                                      ? (state.resources['rat'] ?? 0) +
                                            (state.resources['bat'] ?? 0) +
                                            (state.resources['chicken'] ?? 0)
                                      : (state.resources[ing] ?? 0));
                              final hasEnough = available.round() >= count.round();

                              return Text(
                                '${_getPrettyTypeName(e.key)}: ${e.value.round()}',
                                style: GoogleFonts.oldStandardTt(
                                  color: hasEnough
                                      ? const Color(0xFFC4B89B)
                                      : Colors.redAccent,
                                  fontSize: 10,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EFFICIENCY STATS',
                            style: GoogleFonts.oswald(
                              fontSize: 9,
                              color: const Color(
                                0xFFE5D5B0,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metadata.relevantAttributes
                                .join(", ")
                                .toUpperCase(),
                            style: GoogleFonts.oldStandardTt(
                              fontSize: 10,
                              color: const Color(0xFFC4B89B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: canStart
                        ? () => _showScienceActivityTargetDialog(context, state, activity)
                        : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: canStart
                            ? const Color(0xFFC4B89B)
                            : Colors.white10,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'COMMENCE STUDY',
                      style: GoogleFonts.playfairDisplay(
                        color: canStart
                            ? const Color(0xFFE5D5B0)
                            : Colors.white12,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showScienceActivityTargetDialog(
    BuildContext context,
    GameState state,
    ScienceActivity activity,
  ) {
    // Identify specimen requirements
    final specimenRequirements = activity.ingredients.entries.where((e) => e.key == 'rat_specimen' || e.key == 'captive_human').toList();

    if (specimenRequirements.isEmpty) {
      state.addScienceActivityToQueue(activity.id);
      return;
    }

    final reqType = specimenRequirements.first.key;
    final reqCount = specimenRequirements.first.value;
    final available = state.getAvailableSpecimenTargets(reqType);

    showDialog(
      context: context,
      builder: (context) {
        final List<String> selectedIds = [];
        return StatefulBuilder(
          builder: (context, setDialogState) {

            return AlertDialog(
              backgroundColor: const Color(0xFF1A1612),
              title: Text(
                'SELECT SUBJECTS (${selectedIds.length}/$reqCount)',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'REQUIRED: $reqCount ${reqType.replaceAll('_', ' ').toUpperCase()}',
                      style: GoogleFonts.oldStandardTt(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: available.length,
                        itemBuilder: (context, index) {
                          final target = available[index];
                          final isSelected = selectedIds.contains(target['id']);
                          return CheckboxListTile(
                            title: Text(
                              target['name'].toUpperCase(),
                              style: GoogleFonts.oldStandardTt(
                                color: const Color(0xFFC4B89B),
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Text(
                              target['type'].toUpperCase(),
                              style: GoogleFonts.oldStandardTt(
                                color: Colors.white24,
                                fontSize: 9,
                              ),
                            ),
                            value: isSelected,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  if (selectedIds.length < reqCount) {
                                    selectedIds.add(target['id']);
                                  }
                                } else {
                                  selectedIds.remove(target['id']);
                                }
                              });
                            },
                            activeColor: const Color(0xFFC4B89B),
                            checkColor: Colors.black,
                            side: const BorderSide(color: Colors.white24),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'ABANDON',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white24,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: selectedIds.length == reqCount
                      ? () {
                          state.addScienceActivityToQueue(
                            activity.id,
                            reservedEntityIds: selectedIds,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${activity.name.toUpperCase()} COMMENCED IN STUDY QUEUE',
                              ),
                              backgroundColor: const Color(0xFFC4B89B),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      : null,
                  child: Text(
                    'PROCEED',
                    style: GoogleFonts.playfairDisplay(
                      color: selectedIds.length == reqCount
                          ? const Color(0xFFC4B89B)
                          : Colors.white10,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildResearchQueue(BuildContext context, GameState state) {
    if (state.researchQueue.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white10),
          color: Colors.black.withValues(alpha: 0.2),
        ),
        child: Center(
          child: Text(
            'QUEUE IS EMPTY',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white12,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Column(
      children: state.researchQueue.map((queueId) {
        final index = state.researchQueue.indexOf(queueId);
        final parts = queueId.split(':');
        final category = parts[0];
        final activityId = parts.length > 1 ? parts[1] : null;
        final isActivity = category == 'activity';
        final isRecipe = category == 'recipe';

        final activity = isActivity
            ? ScienceService.getActivityById(activityId!)
            : null;
        final recipe = isRecipe
            ? KitchenService.getAvailableRecipes()
                  .where((r) => r.id == activityId)
                  .firstOrNull
            : null;

        final item = (!isActivity && !isRecipe)
            ? state.inventory.where((i) => i.id == queueId).firstOrNull
            : null;

        // Find assigned NPC
        final assignedNpc = state.npcs.where((n) {
          if (n.activeTaskId == null) return false;
          return n.intentQueue.any(
            (intent) =>
                ((isActivity || isRecipe) && intent.recipeId == activityId) ||
                (!isActivity && !isRecipe && intent.recipeId == queueId),
          );
        }).firstOrNull;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
            ),
            color: Colors.black.withValues(alpha: 0.3),
          ),
          child: ListTile(
            dense: true,
            leading: (isActivity || isRecipe)
                ? Icon(
                    isActivity ? Icons.science : Icons.restaurant_menu,
                    color: const Color(0xFFC4B89B),
                    size: 16,
                  )
                : item != null
                ? GameItemRenderer(item: item, size: 16)
                : const Icon(
                    Icons.help_outline,
                    color: Colors.white24,
                    size: 16,
                  ),
            title: Text(
              (activity?.name ??
                      recipe?.name ??
                      (item != null ? _getPrettyItemName(item) : null) ??
                      (isActivity ? "RESEARCH PROJECT: $activityId" : 'UNKNOWN'))
                  .toUpperCase(),
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFE5D5B0),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignedNpc != null
                      ? 'ASSIGNED: ${assignedNpc.name.toUpperCase()}'
                      : 'PENDING ASSIGNMENT',
                  style: GoogleFonts.oldStandardTt(
                    color: assignedNpc != null
                        ? const Color(0xFFC4B89B).withValues(alpha: 0.6)
                        : Colors.white24,
                    fontSize: 9,
                  ),
                ),
                if (parts.length > 2) 
                  Text(
                    'SUBJECTS: ${parts.sublist(2).join(", ").toUpperCase()}',
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFC4B89B).withValues(alpha: 0.4),
                      fontSize: 8,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.white24, size: 14),
              onPressed: () => state.removeResearchFromQueue(index),
            ),
          ),
        );
      }).toList(),
    );
  }
  String _getPrettyItemName(GameItem item) {
    if (item.type == 'research_note' ||
        item.category == ItemCategory.knowledge) {
      final discipline = item.metadata['discipline'] as String?;
      if (discipline != null) {
        return '${discipline.toUpperCase()} NOTES';
      }
    }
    return _getPrettyTypeName(item.type);
  }

  String _getPrettyTypeName(String type) {
    if (type == 'rat_specimen') return 'SMALL SPECIMEN';
    if (type == 'bat_specimen') return 'SMALL SPECIMEN (FLYING)';
    if (type == 'chicken') return 'LIVESTOCK (CHICKEN)';
    if (type == 'herb_reagent') return 'HERB REAGENT';
    if (type == 'unreviewed_document') return 'UNREVIEWED DOCUMENT';
    if (type == 'old_notes') return 'OLD NOTES';
    return type.replaceAll('_', ' ').toUpperCase();
  }
}
