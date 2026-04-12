import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/providers.dart';
import '../../../domain/models/models.dart';
import '../../../core/enums/enums.dart';

/// Bottom sheet for adding a new todo.
class AddTodoSheet extends ConsumerStatefulWidget {
  const AddTodoSheet({super.key});

  @override
  ConsumerState<AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends ConsumerState<AddTodoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  Category _selectedCategory = Category.defaults.first;
  int _priority = 2;
  DateTime? _dueDate;
  TimeOfDay? _reminderTime;
  RepeatRule _repeatRule = RepeatRule.none;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      DateTime? reminderAt;
      if (_dueDate != null && _reminderTime != null) {
        reminderAt = DateTime(
          _dueDate!.year,
          _dueDate!.month,
          _dueDate!.day,
          _reminderTime!.hour,
          _reminderTime!.minute,
        );
      }

      await ref.read(todoNotifierProvider.notifier).createTodo(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            categoryId: _selectedCategory.id,
            color: _selectedCategory.color.toARGB32(),
            priority: _priority,
            dueDate: _dueDate,
            reminderAt: reminderAt,
            repeatRule: _repeatRule,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
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
                'New Task',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'What needs to be done?',
                ),
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add more details...',
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Category
              Text(
                'Category',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Category.defaults.map((category) {
                  final isSelected = _selectedCategory.id == category.id;
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
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Priority
              Text(
                'Priority',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 1,
                    label: Text('Urgent'),
                    icon: Icon(Icons.priority_high, size: 18),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text('High'),
                  ),
                  ButtonSegment(
                    value: 3,
                    label: Text('Medium'),
                  ),
                  ButtonSegment(
                    value: 4,
                    label: Text('Low'),
                  ),
                ],
                selected: {_priority},
                onSelectionChanged: (set) {
                  setState(() {
                    _priority = set.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Due date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.calendar_today,
                  color: _dueDate != null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  _dueDate != null
                      ? DateFormat('EEE, MMM d, y').format(_dueDate!)
                      : 'Set due date',
                ),
                trailing: _dueDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _dueDate = null;
                            _reminderTime = null;
                          });
                        },
                      )
                    : null,
                onTap: _pickDueDate,
              ),

              // Reminder
              if (_dueDate != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.notifications,
                    color: _reminderTime != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    _reminderTime != null
                        ? 'Remind at ${_reminderTime!.format(context)}'
                        : 'Set reminder',
                  ),
                  trailing: _reminderTime != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _reminderTime = null;
                            });
                          },
                        )
                      : null,
                  onTap: _pickReminderTime,
                ),

              // Repeat
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.repeat,
                  color: _repeatRule != RepeatRule.none
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(_repeatRule.displayName),
                onTap: _pickRepeatRule,
              ),
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
                    : const Text('Create Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  Future<void> _pickReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) {
      setState(() {
        _reminderTime = time;
      });
    }
  }

  void _pickRepeatRule() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: RepeatRule.values.map((rule) {
          return ListTile(
            title: Text(rule.displayName),
            trailing: _repeatRule == rule
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () {
              setState(() {
                _repeatRule = rule;
              });
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }
}
