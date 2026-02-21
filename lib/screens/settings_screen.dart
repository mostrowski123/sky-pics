import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(columnOverrideProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Column Count', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Override the number of columns in the image grid. '
            'Set to Auto to let the app decide based on screen width.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(context, ref, label: 'Auto', value: null, current: current),
              for (int i = 1; i <= 6; i++)
                _chip(context, ref, label: '$i', value: i, current: current),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required int? value,
    required int? current,
  }) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => ref.read(columnOverrideProvider.notifier).set(value),
    );
  }
}
