import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';

/// Notifier for the user's column count override setting (Riverpod v3).
class ColumnOverrideNotifier extends Notifier<int?> {
  @override
  int? build() => ref.read(settingsServiceProvider).columnOverride;

  Future<void> set(int? count) async {
    await ref.read(settingsServiceProvider).setColumnOverride(count);
    state = count;
  }
}

final columnOverrideProvider = NotifierProvider<ColumnOverrideNotifier, int?>(
  ColumnOverrideNotifier.new,
);
