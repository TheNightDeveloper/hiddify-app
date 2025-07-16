import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/connection/data/connection_platform_source.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/config/model/config_models.dart';

import 'package:hiddify/features/profile/data/profile_path_resolver.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/singbox/model/singbox_status.dart';
import 'package:hiddify/singbox/service/singbox_service.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:meta/meta.dart';
import 'dart:convert';

abstract interface class ConnectionRepository {
  SingboxConfigOption? get configOptionsSnapshot;

  TaskEither<ConnectionFailure, Unit> setup();
  Stream<ConnectionStatus> watchConnectionStatus();
  TaskEither<ConnectionFailure, Unit> connect(ServerConfig config, bool disableMemoryLimit, String? testUrl);
  TaskEither<ConnectionFailure, Unit> disconnect();
  TaskEither<ConnectionFailure, Unit> reconnect(ServerConfig config, bool disableMemoryLimit, String? testUrl);
}

class ConnectionRepositoryImpl with ExceptionHandler, InfraLogger implements ConnectionRepository {
  ConnectionRepositoryImpl({required this.directories, required this.singbox, required this.platformSource, required this.configOptionRepository, required this.profilePathResolver});

  final Directories directories;
  final SingboxService singbox;
  final ConnectionPlatformSource platformSource;
  final ConfigOptionRepository configOptionRepository;
  final ProfilePathResolver profilePathResolver;

  SingboxConfigOption? _configOptionsSnapshot;
  @override
  SingboxConfigOption? get configOptionsSnapshot => _configOptionsSnapshot;

  bool _initialized = false;

  @override
  Stream<ConnectionStatus> watchConnectionStatus() {
    return singbox.watchStatus().map(
      (event) => switch (event) {
        SingboxStopped(:final alert?, :final message) => Disconnected(switch (alert) {
          SingboxAlert.emptyConfiguration => ConnectionFailure.invalidConfig(message),
          SingboxAlert.requestNotificationPermission => ConnectionFailure.missingNotificationPermission(message),
          SingboxAlert.requestVPNPermission => ConnectionFailure.missingVpnPermission(message),
          SingboxAlert.startCommandServer || SingboxAlert.createService || SingboxAlert.startService => ConnectionFailure.unexpected(message),
        }),
        SingboxStopped() => const Disconnected(),
        SingboxStarting() => const Connecting(),
        SingboxStarted() => const Connected(),
        SingboxStopping() => const Disconnecting(),
      },
    );
  }

  @visibleForTesting
  TaskEither<ConnectionFailure, SingboxConfigOption> getConfigOption() {
    return TaskEither<ConnectionFailure, SingboxConfigOption>.Do(($) async {
      final options = await $(configOptionRepository.getFullSingboxConfigOption().mapLeft((l) => const InvalidConfigOption()));

      return $(
        TaskEither(() async {
          // final geoip = geoAssetPathResolver.resolvePath(options.geoipPath);
          // final geosite =
          //     geoAssetPathResolver.resolvePath(options.geositePath);
          // if (!await File(geoip).exists() ||
          //     !await File(geosite).exists()) {
          //   return left(const ConnectionFailure.missingGeoAssets());
          // }
          return right(options);
        }),
      );
    }).handleExceptions(UnexpectedConnectionFailure.new);
  }

  @visibleForTesting
  TaskEither<ConnectionFailure, Unit> applyConfigOption(SingboxConfigOption options, String? testUrl) {
    return exceptionHandler(() {
      _configOptionsSnapshot = options;
      var newOptions = options;
      if (testUrl != null) {
        newOptions = options.copyWith(connectionTestUrl: testUrl);
      }
      return singbox.changeOptions(newOptions).mapLeft(InvalidConfigOption.new).run();
    }, UnexpectedConnectionFailure.new);
  }

  @override
  TaskEither<ConnectionFailure, Unit> setup() {
    if (_initialized) return TaskEither.of(unit);
    return exceptionHandler(() {
      loggy.debug("setting up singbox");
      return singbox
          .setup(directories, false)
          .map((r) {
            _initialized = true;
            return r;
          })
          .mapLeft(UnexpectedConnectionFailure.new)
          .run();
    }, UnexpectedConnectionFailure.new);
  }

  @override
  TaskEither<ConnectionFailure, Unit> connect(ServerConfig config, bool disableMemoryLimit, String? testUrl) {
    return TaskEither<ConnectionFailure, Unit>.Do(($) async {
      var options = await $(getConfigOption());
      loggy.info("config options: ${options.format()}\nMemory Limit: ${!disableMemoryLimit}");

      await $(_generateV2rayConfig(config));

      await $(
        TaskEither(() async {
          if (options.enableTun) {
            final hasPrivilege = await platformSource.checkPrivilege();
            if (!hasPrivilege) {
              loggy.warning("missing privileges for tun mode");
              return left(const MissingPrivilege());
            }
          }
          return right(unit);
        }),
      );
      await $(setup());
      await $(applyConfigOption(options, testUrl));
      return await $(singbox.start(profilePathResolver.file(config.id).path, config.name, disableMemoryLimit).mapLeft(UnexpectedConnectionFailure.new));
    }).handleExceptions(UnexpectedConnectionFailure.new);
  }

  @override
  TaskEither<ConnectionFailure, Unit> disconnect() {
    return TaskEither<ConnectionFailure, Unit>.Do(($) async {
      final options = await $(getConfigOption());

      await $(
        TaskEither(() async {
          if (options.enableTun) {
            final hasPrivilege = await platformSource.checkPrivilege();
            if (!hasPrivilege) {
              loggy.warning("missing privileges for tun mode");
              return left(const MissingPrivilege());
            }
          }
          return right(unit);
        }),
      );
      return await $(singbox.stop().mapLeft(UnexpectedConnectionFailure.new));
    }).handleExceptions(UnexpectedConnectionFailure.new);
  }

  @override
  TaskEither<ConnectionFailure, Unit> reconnect(ServerConfig config, bool disableMemoryLimit, String? testUrl) {
    return TaskEither<ConnectionFailure, Unit>.Do(($) async {
      var options = await $(getConfigOption());
      loggy.info("config options: ${options.format()}\nMemory Limit: ${!disableMemoryLimit}");

      await $(_generateV2rayConfig(config));

      await $(applyConfigOption(options, testUrl));
      return await $(singbox.restart(profilePathResolver.file(config.id).path, config.name, disableMemoryLimit).mapLeft(UnexpectedConnectionFailure.new));
    }).handleExceptions(UnexpectedConnectionFailure.new);
  }

  TaskEither<ConnectionFailure, Unit> _generateV2rayConfig(ServerConfig config) {
    return TaskEither.tryCatch(
      () async {
        if (config.type != ConfigType.v2ray) {
          loggy.debug("config is not v2ray, skipping generation");
          return unit;
        }

        final uri = Uri.parse(config.data);
        final singboxConfig = {
          "log": {"disabled": false, "level": "info", "output": "app.log", "timestamp": true},
          "outbounds": [
            {
              "type": "vless",
              "tag": "vless-out",
              "server": uri.host,
              "server_port": uri.port,
              "uuid": uri.userInfo,
              "flow": uri.queryParameters['flow'] ?? "",
              "network": "tcp",
              "tls": {
                "enabled": uri.queryParameters['security'] == 'tls',
                "server_name": uri.queryParameters['sni'],
                "utls": {"enabled": true, "fingerprint": "chrome"},
              },
              "transport": {
                "type": uri.queryParameters['type'] ?? 'ws',
                "path": uri.queryParameters['path'],
                "headers": {"Host": uri.queryParameters['host']},
              },
            },
          ],
        };

        final file = profilePathResolver.file(config.id);
        if (!await file.parent.exists()) {
          await file.parent.create(recursive: true);
        }
        await file.writeAsString(jsonEncode(singboxConfig));
        loggy.info("generated v2ray config for [${config.name}] at [${file.path}]");
        return unit;
      },
      (error, stackTrace) {
        loggy.error("error generating v2ray config", error, stackTrace);
        return UnexpectedConnectionFailure(error);
      },
    );
  }
}
