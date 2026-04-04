import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/providers.dart';
import '../../../core/enums/enums.dart';

/// Level selection screen for choosing user experience level.
class LevelSelectionScreen extends ConsumerStatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  ConsumerState<LevelSelectionScreen> createState() =>
      _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends ConsumerState<LevelSelectionScreen> {
  UserLevel? _selectedLevel;
  bool _isLoading = false;

  Future<void> _handleContinue() async {
    if (_selectedLevel == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(userNotifierProvider.notifier).completeOnboarding(
            _selectedLevel!,
          );
      // Router will automatically redirect to home
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    'Choose Your Style',
                    style: theme.textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can change this anytime in settings',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Level options
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: UserLevel.values.length,
                itemBuilder: (context, index) {
                  final level = UserLevel.values[index];
                  return _LevelCard(
                    level: level,
                    isSelected: _selectedLevel == level,
                    onTap: () {
                      setState(() {
                        _selectedLevel = level;
                      });
                    },
                  ).animate(delay: (100 * index).ms).fadeIn().slideX(
                        begin: 0.1,
                        end: 0,
                        curve: Curves.easeOut,
                      );
                },
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed:
                    _selectedLevel != null && !_isLoading ? _handleContinue : null,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final UserLevel level;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icon/Emoji
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      level.iconName,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : null,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        level.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.grid_view,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${level.tabCount} navigation tabs',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Checkmark
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
