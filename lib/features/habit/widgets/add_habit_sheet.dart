import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import '../../../domain/models/models.dart';
import '../../../core/enums/enums.dart';

/// Bottom sheet for adding a new habit.
class AddHabitSheet extends ConsumerStatefulWidget {
  final bool isFuture;

  const AddHabitSheet({super.key, this.isFuture = false});

  @override
  ConsumerState<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends ConsumerState<AddHabitSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  Category? _selectedCategory;
  DateTime? _startDate;
  bool _isLoading = false;

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

      // Apply defaults based on user level
      final description = userLevel == UserLevel.expert
          ? (_descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim())
          : null;

      final categoryId = userLevel.index >= UserLevel.intermediate.index
          ? (_selectedCategory?.id == 'none' ? null : _selectedCategory?.id)
          : null;

      await ref.read(habitNotifierProvider.notifier).createHabit(
            name: _nameController.text.trim(),
            description: description,
            categoryId: categoryId,
            startDate: _startDate,
            isFuture: widget.isFuture,
          );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userLevel = ref.watch(userLevelProvider);
    final categories = ref.watch(userCategoriesProvider);
    _selectedCategory ??= categories.firstWhere((c) => c.id == 'none', orElse: () => categories.first);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isFuture ? 'Add to Wishlist' : 'New Habit',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
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
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a habit name';
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
                Text(
                  'Category (optional)',
                  style: theme.textTheme.labelLarge,
                ),
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
              ],

              if (widget.isFuture) ...[
                const SizedBox(height: 16),
                Text(
                  'This habit will be added to your wishlist. You can start it anytime from the wishlist.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isFuture ? 'Add to Wishlist' : 'Create Habit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
