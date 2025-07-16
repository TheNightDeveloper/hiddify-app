import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';

extension VPNStageMapper on VPNStage {
  ConnectionStatus toConnectionStatus([String? rawStage]) {
    switch (this) {
      case VPNStage.prepare:
      case VPNStage.resolve:
      case VPNStage.wait_connection:
      case VPNStage.connecting:
      case VPNStage.tcp_connect:
      case VPNStage.udp_connect:
      case VPNStage.authenticating:
      case VPNStage.authentication:
      case VPNStage.get_config:
      case VPNStage.assign_ip:
      case VPNStage.vpn_generate_config:
        return const ConnectionStatus.connecting();

      case VPNStage.connected:
        return const ConnectionStatus.connected();

      case VPNStage.disconnected:
      case VPNStage.exiting:
      case VPNStage.disconnecting:
        return const ConnectionStatus.disconnected();

      case VPNStage.error:
      case VPNStage.denied:
      case VPNStage.unknown:
        return ConnectionStatus.disconnected(ConnectionFailure.unexpected(Exception(rawStage ?? "Unknown OpenVPN error")));
    }
  }
}
