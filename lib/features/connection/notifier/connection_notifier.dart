import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/config/model/config_models.dart';
import 'package:hiddify/features/config/notifier/selected_config_notifier.dart';
import 'package:hiddify/features/connection/data/connection_data_providers.dart';
import 'package:hiddify/features/connection/data/connection_repository.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/open_vpn/service/openvpn_service.dart';
import 'package:hiddify/features/open_vpn/service/openvpn_status_mapper.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'connection_notifier.g.dart';

@Riverpod(keepAlive: true)
class ConnectionNotifier extends _$ConnectionNotifier with AppLogger {
  @override
  Stream<ConnectionStatus> build() {
    if (Platform.isIOS) {
      _connectionRepo.setup().getOrElse((l) {
        loggy.error("error setting up connection repository", l);
        return unit;
      }).run();
    }

    ref.listenSelf((previous, next) async {
      if (previous == next) return;
      if (previous case AsyncData(:final value) when !value.isConnected) {
        if (next case AsyncData(value: final Connected _)) {
          await ref.read(hapticServiceProvider.notifier).heavyImpact();

          if (Platform.isAndroid && !ref.read(Preferences.storeReviewedByUser)) {
            if (await InAppReview.instance.isAvailable()) {
              InAppReview.instance.requestReview();
              ref.read(Preferences.storeReviewedByUser.notifier).update(true);
            }
          }
        }
      }
    });

    ref.listen(selectedConfigNotifierProvider, (previous, next) async {
      if (previous == null) return;
      final shouldReconnect = next == null || previous.id != next.id;
      if (shouldReconnect && state.value is Connected) {
        await reconnect(next);
      }
    });

    final openvpnEvents = _openVpnService.stage.map((event) => event.$1.toConnectionStatus(event.$2));

    return MergeStream([_connectionRepo.watchConnectionStatus(), openvpnEvents]).doOnData((event) {
      if (event case Disconnected(connectionFailure: final _?) when PlatformUtils.isDesktop) {
        ref.read(Preferences.startedByUser.notifier).update(false);
      }
      loggy.info("connection status: ${event.format()}");
    });
  }

  ConnectionRepository get _connectionRepo => ref.read(connectionRepositoryProvider);
  OpenVpnService get _openVpnService => ref.read(openVpnServiceProvider.notifier);

  Future<void> mayConnect() async {
    if (state case AsyncData(:final value)) {
      if (value case Disconnected()) return _connect();
    }
  }

  Future<void> toggleConnection() async {
    final haptic = ref.read(hapticServiceProvider.notifier);
    if (state case AsyncError()) {
      await haptic.lightImpact();
      await _connect();
    } else if (state case AsyncData(:final value)) {
      switch (value) {
        case Disconnected():
          await haptic.lightImpact();
          await ref.read(Preferences.startedByUser.notifier).update(true);
          await _connect();
        case Connected():
          await haptic.mediumImpact();
          await ref.read(Preferences.startedByUser.notifier).update(false);
          await _disconnect();
        default:
          loggy.warning("switching status, debounce");
      }
    }
  }

  Future<void> reconnect(ServerConfig? config) async {
    if (state case AsyncData(:final value) when value == const Connected()) {
      if (config == null) {
        loggy.info("no selected config, disconnecting");
        return _disconnect();
      }
      loggy.info("selected config changed, reconnecting");
      await ref.read(Preferences.startedByUser.notifier).update(true);

      if (config.type == ConfigType.openvpn) {
        await _openVpnService.disconnect();
        await _openVpnService.connect(config);
      } else {
        await _connectionRepo
            .reconnect(
              config,
              ref.read(Preferences.disableMemoryLimit),
              "https://www.gstatic.com/generate_204", // Default test URL
            )
            .mapLeft((err) {
              loggy.warning("error reconnecting", err);
              state = AsyncError(err, StackTrace.current);
            })
            .run();
      }
    }
  }

  Future<void> abortConnection() async {
    if (state case AsyncData(:final value)) {
      switch (value) {
        case Connected() || Connecting():
          loggy.debug("aborting connection");
          await _disconnect();
        default:
      }
    }
  }

  Future<void> _connect() async {
    final selectedConfig = ref.read(selectedConfigNotifierProvider);
    if (selectedConfig == null) {
      loggy.info("no selected config, not connecting");
      return;
    }

    if (selectedConfig.type == ConfigType.openvpn) {
      await _openVpnService.connect(selectedConfig);
    } else {
      await _connectionRepo
          .connect(
            selectedConfig,
            ref.read(Preferences.disableMemoryLimit),
            "https://www.gstatic.com/generate_204", // Default test URL
          )
          .mapLeft((err) async {
            loggy.warning("error connecting", err);
            //Go err is not normal object to see the go errors are string and need to be dumped
            loggy.warning(err);
            if (err.toString().contains("panic")) {
              await Sentry.captureException(Exception(err.toString()));
            }
            await ref.read(Preferences.startedByUser.notifier).update(false);
            state = AsyncError(err, StackTrace.current);
          })
          .run();
    }
  }

  Future<void> _disconnect() async {
    final selectedConfig = ref.read(selectedConfigNotifierProvider);
    if (selectedConfig?.type == ConfigType.openvpn) {
      await _openVpnService.disconnect();
    } else {
      await _connectionRepo.disconnect().mapLeft((err) {
        loggy.warning("error disconnecting", err);
        state = AsyncError(err, StackTrace.current);
      }).run();
    }
  }
}

@Riverpod(keepAlive: true)
Future<bool> serviceRunning(ServiceRunningRef ref) => ref.watch(connectionNotifierProvider.selectAsync((data) => data.isConnected)).onError((error, stackTrace) => false);
