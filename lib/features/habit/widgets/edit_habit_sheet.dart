import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import '../../../domain/models/models.dart';
import '../../../core/enums/enums.dart';

/// Bottom sheet for editing an existing habit.
class EditHabitSheet extends ConsumerStatefulWidget {
  final HabitModel habit;

  const EditHabitSheet({super.key, required this.habit});

  @override
  ConsumerState<EditHabitSheet> createState() => _EditHabitSheetState();
}

class _EditHabitSheetState extends ConsumerState<EditHabitSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  Category? _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit.name);
    _descriptionController = TextEditingController(
      text: widget.habit.description ?? '',
    );
    final categories = ref.read(userCategoriesProvider);
    _selectedCategory = categories.firstWhere(
      (c) => c.id == widget.habit.categoryId || (widget.habit.categoryId == null && c.id == 'none'),
      orElse: () => categories.firstWhere((c) => c.id == 'none'),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userLevel = ref.read(userLevelProvider);

      // Apply defaults/preserve values based on user level
      final description = userLevel == UserLevel.expert
          ? (_descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim())
          : widget.habit.description; // Preserve existing value if hidden

      final categoryId = userLevel.index >= UserLevel.intermediate.index
          ? (_selectedCategory?.id == 'none' ? null : _selectedCategory?.id)
          : widget.habit.categoryId; // Preserve existing value if hidden

      final updated = widget.habit.copyWith(
        name: _nameController.text.trim(),
        description: description,
        categoryId: categoryId,
      );

      await ref.read(habitNotifierProvider.notifier).updateHabit(updated);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit?'),
        content: const Text(
          'This will delete the habit and all its completion history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(habitNotifierProvider.notifier)
          .deleteHabit(widget.habit.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleArchive() async {
    await ref
        .read(habitNotifierProvider.notifier)
        .toggleHabitActive(widget.habit.id, false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Habit archived')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userLevel = ref.watch(userLevelProvider);
    final categories = ref.watch(userCategoriesProvider);
    final streakAsync = ref.watch(habitStreakProvider(widget.habit.id));

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                children: [
                  const Spacer(),
                  Text('Edit Habit', style: theme.textTheme.headlineSmall),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: _handleDelete,
                  ),
                ],
              ),

              // Streak display
              streakAsync.when(
                data: (streak) {
                  if (streak == 0) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$streak day streak!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Habit Name',
                  hintText: 'e.g., Morning Meditation',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a habit name';
                  }
                  if (value.trim().split(RegExp(r'\s+')).length > 15) {
                    return 'Habit name cannot exceed 15 words';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description (Expert only)
              if (userLevel == UserLevel.expert) ...
              [
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Why is this habit important?',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
              ],

              // Category (Intermediate+)
              if (userLevel.index >= UserLevel.intermediate.index) ...
              [
                Text('Category (optional)', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...categories.map((category) {
                      final isSelected = _selectedCategory?.id == category.id;
                      return FilterChip(
                        selected: isSelected,
                        label: Text(category.name),
                        avatar: CircleAvatar(
                          backgroundColor: category.color,
                          radius: 8,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 24),
              ]
              else
                const SizedBox(height: 16),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _handleArchive,
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Archive Habit'),
            ),
          ],
        ),
      ),
    ],
  ),
  ),
);
  }
}
