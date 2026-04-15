import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import '../../../domain/models/models.dart';

/// Array of 24 basic colors for the color picker
const List<Color> _basicColorPalette = [
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.lightBlue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lightGreen,
  Colors.lime,
  Colors.yellow,
  Colors.amber,
  Colors.orange,
  Colors.deepOrange,
  Colors.brown,
  Colors.grey,
  Colors.blueGrey,
  Color(0xFF6366F1), // Indigo default
  Color(0xFF3B82F6), // Blue default
  Color(0xFF22C55E), // Green default
  Color(0xFFF59E0B), // Amber default
  Color(0xFFEC4899), // Pink default
];

class CategoryColorsDialog extends ConsumerWidget {
  const CategoryColorsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = ref.watch(userCategoriesProvider);

    return AlertDialog(
      title: const Text('Category Colors'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: categories.length,
          separatorBuilder: (context, _) => const Divider(),
          itemBuilder: (context, index) {
            final category = categories[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(category.name),
              trailing: GestureDetector(
                onTap: () => _pickColorForCategory(context, ref, category),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _pickColorForCategory(BuildContext context, WidgetRef ref, Category category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ColorPickerSheet(category: category),
    );
  }
}

class _ColorPickerSheet extends ConsumerWidget {
  final Category category;

  const _ColorPickerSheet({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pick Color for ${category.name}',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _basicColorPalette.map((color) {
                  final isSelected = category.color.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(context); // Close bottom sheet
                      
                      final userProfile = ref.read(userProfileProvider).value;
                      if (userProfile == null) return;

                      // Update preference map
                      final currentColors = Map<String, int>.from(
                        userProfile.preferences.categoryColors,
                      );
                      currentColors[category.id] = color.toARGB32();

                      final newPrefs = userProfile.preferences.copyWith(
                        categoryColors: currentColors,
                      );

                      await ref.read(userNotifierProvider.notifier).updatePreferences(newPrefs);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.outlineVariant,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
