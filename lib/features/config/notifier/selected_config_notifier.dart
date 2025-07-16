import 'package:hiddify/features/config/model/config_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_config_notifier.g.dart';

// مدیریت کانفیگ انتخاب شده
// Manages the currently selected configuration
@Riverpod(keepAlive: true)
class SelectedConfigNotifier extends _$SelectedConfigNotifier {
  @override
  ServerConfig? build() {
    return null; // Initially no config is selected
  }

  // انتخاب یک کانفیگ جدید
  // Select a new configuration
  void selectConfig(ServerConfig config) {
    state = config;
  }

  // پاک کردن انتخاب فعلی
  // Clear the current selection
  void clearSelection() {
    state = null;
  }
}
