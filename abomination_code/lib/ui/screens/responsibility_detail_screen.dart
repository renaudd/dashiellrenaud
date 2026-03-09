import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../state/game_state.dart';
import '../../models/responsibility.dart';
import '../../services/task_service.dart';

class ResponsibilityDetailScreen extends StatelessWidget {
  final ResponsibilityCategory category;

  const ResponsibilityDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        final tasks = state.categoryPriorities[category] ?? [];
        final dividerIndex = state.categoryDividers[category] ?? 0;

        return Scaffold(
          backgroundColor: const Color(0xFF1A1612),
          appBar: AppBar(
            backgroundColor: Colors.black45,
            title: Text(
              category.displayName.toUpperCase(),
              style: GoogleFonts.oswald(
                letterSpacing: 2,
                color: const Color(0xFFC4B89B),
              ),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Tasks above the red divider are considered High Priority and will be performed even during leisure or sleep hours by focused characters.',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: tasks.length + 1, // +1 for the divider
                  itemBuilder: (context, index) {
                    if (index == dividerIndex) {
                      return ListTile(
                        key: const ValueKey('priority_divider'),
                        tileColor: Colors.red.withValues(alpha: 0.1),
                        title: Center(
                          child: Container(
                            height: 2,
                            width: double.infinity,
                            color: Colors.red.withValues(alpha: 0.5),
                          ),
                        ),
                        subtitle: Center(
                          child: Text(
                            'PRIORITY DIVIDER',
                            style: GoogleFonts.oswald(
                              color: Colors.red,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      );
                    }

                    // Adjust index for items after the divider
                    final actualIndex = index > dividerIndex
                        ? index - 1
                        : index;
                    final task = tasks[actualIndex];

                    return ListTile(
                      key: ValueKey(task.name),
                      leading: Icon(
                        index < dividerIndex
                            ? Icons.priority_high
                            : Icons.low_priority,
                        color: index < dividerIndex
                            ? Colors.orange
                            : Colors.blueGrey,
                      ),
                      title: Text(
                        task.name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.drag_handle,
                        color: Colors.white24,
                      ),
                      tileColor: index < dividerIndex
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.2),
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    // Logic to handle both task reordering and divider repositioning
                    if (oldIndex == dividerIndex) {
                      // Move the divider
                      if (newIndex > tasks.length) newIndex = tasks.length;
                      state.updateCategoryDivider(
                        category,
                        newIndex > oldIndex ? newIndex - 1 : newIndex,
                      );
                    } else {
                      // Move a task
                      final actualOldIndex = oldIndex > dividerIndex
                          ? oldIndex - 1
                          : oldIndex;
                      var actualNewIndex = newIndex > dividerIndex
                          ? newIndex - 1
                          : newIndex;
                      if (actualOldIndex < actualNewIndex) actualNewIndex -= 1;

                      final newTasks = List<TaskType>.from(tasks);
                      final item = newTasks.removeAt(actualOldIndex);
                      newTasks.insert(actualNewIndex, item);
                      state.updateCategoryPriority(category, newTasks);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
