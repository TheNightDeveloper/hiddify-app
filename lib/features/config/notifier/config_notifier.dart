import 'package:hiddify/features/config/data/config_repository.dart';
import 'package:hiddify/features/config/model/config_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'config_notifier.g.dart';

// ارائه دهنده داده های سرور
// Provides the server data to the UI.
@riverpod
Future<ServerData> serverData(ServerDataRef ref) async {
  return ref.watch(configRepositoryProvider).fetchData();
}
