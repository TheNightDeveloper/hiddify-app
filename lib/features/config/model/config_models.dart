import 'package:freezed_annotation/freezed_annotation.dart';

part 'config_models.freezed.dart';
part 'config_models.g.dart';

// نوع کانفیگ را مشخص می کند
enum ConfigType { v2ray, openvpn }

// داده های کاربر و لیست کانفیگ ها را نگه می دارد
@freezed
class ServerData with _$ServerData {
  const factory ServerData({required UserUsage usage, required List<ServerConfig> configs}) = _ServerData;

  factory ServerData.fromJson(Map<String, dynamic> json) => _$ServerDataFromJson(json);
}

// اطلاعات مصرف کاربر را نگه می دارد
@freezed
class UserUsage with _$UserUsage {
  const factory UserUsage({required double remainingDataGB, required int remainingDays}) = _UserUsage;

  factory UserUsage.fromJson(Map<String, dynamic> json) => _$UserUsageFromJson(json);
}

// یک کانفیگ سرور را نشان می دهد
@freezed
class ServerConfig with _$ServerConfig {
  const factory ServerConfig({required String id, required String name, required ConfigType type, required String data}) = _ServerConfig;

  factory ServerConfig.fromJson(Map<String, dynamic> json) => _$ServerConfigFromJson(json);
}
