import 'dart:async';

import 'package:hiddify/features/config/model/config_models.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'openvpn_service.g.dart';

// سرویس مدیریت اتصال OpenVPN
// Service for managing OpenVPN connections
@Riverpod(keepAlive: true)
class OpenVpnService extends _$OpenVpnService with AppLogger {
  late OpenVPN _openVPN;
  final _statusController = StreamController<VpnStatus>.broadcast();
  final _stageController = StreamController<(VPNStage, String)>.broadcast();

  Stream<VpnStatus> get status => _statusController.stream;
  Stream<(VPNStage, String)> get stage => _stageController.stream;

  @override
  void build() {
    _openVPN = OpenVPN(onVpnStatusChanged: _onVpnStatusChanged, onVpnStageChanged: _onVpnStageChanged);

    _initialize();

    ref.onDispose(() {
      _statusController.close();
      _stageController.close();
    });
  }

  void _initialize() {
    try {
      _openVPN.initialize(
        groupIdentifier: "group.com.hiddify.app", // باید با تنظیمات iOS مطابقت داشته باشد
        providerBundleIdentifier: "com.hiddify.app.VPNExtension", // باید با تنظیمات iOS مطابقت داشته باشد
        localizedDescription: "Hiddify VPN",
      );
      loggy.info("OpenVPN service initialized successfully");
    } catch (e, stackTrace) {
      loggy.error("Failed to initialize OpenVPN service", e, stackTrace);
    }
  }

  void _onVpnStatusChanged(VpnStatus? status) {
    if (status != null) {
      loggy.info("OpenVPN status changed: ${status.toJson()}");
      _statusController.add(status);
    }
  }

  void _onVpnStageChanged(VPNStage stage, String rawStage) {
    loggy.info("OpenVPN stage changed: $stage, message: $rawStage");
    _stageController.add((stage, rawStage));
  }

  // اتصال به سرور OpenVPN
  // Connect to OpenVPN server
  Future<void> connect(ServerConfig config) async {
    if (config.type != ConfigType.openvpn) {
      throw Exception("Config is not an OpenVPN config");
    }

    try {
      loggy.info("Connecting to OpenVPN server: ${config.name}");
      await _openVPN.connect(config.data, config.name, bypassPackages: [], certIsRequired: false, username: 'A99_11000053-test', password: 'UimO13qn');
      loggy.info("OpenVPN connection initiated");
    } catch (e, stackTrace) {
      loggy.error("Failed to connect to OpenVPN server", e, stackTrace);
      rethrow;
    }
  }

  // قطع اتصال از سرور OpenVPN
  // Disconnect from OpenVPN server
  Future<void> disconnect() async {
    try {
      loggy.info("Disconnecting from OpenVPN server");
      _openVPN.disconnect();
      loggy.info("OpenVPN disconnected");
    } catch (e, stackTrace) {
      loggy.error("Failed to disconnect from OpenVPN server", e, stackTrace);
      rethrow;
    }
  }

  // بررسی وضعیت فعلی اتصال
  // Check current connection status
  Future<VpnStatus> getCurrentStatus() async {
    try {
      final status = await _openVPN.status();
      loggy.info("Current OpenVPN status: ${status.toJson()}");
      return status;
    } catch (e, stackTrace) {
      loggy.error("Failed to get OpenVPN status", e, stackTrace);
      return VpnStatus.empty();
    }
  }
}
