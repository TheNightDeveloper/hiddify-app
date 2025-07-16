import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/common/nested_app_bar.dart';
import 'package:hiddify/features/config/model/config_models.dart';
import 'package:hiddify/features/config/notifier/config_notifier.dart';
import 'package:hiddify/features/config/notifier/selected_config_notifier.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hiddify/features/proxy/active/active_proxy_footer.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    final serverData = ref.watch(serverDataProvider);

    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomScrollView(
            slivers: [
              NestedAppBar(
                title: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: t.general.appTitle),
                      const TextSpan(text: " "),
                      const WidgetSpan(child: AppVersionLabel(), alignment: PlaceholderAlignment.middle),
                    ],
                  ),
                ),
                actions: [IconButton(onPressed: () => const QuickSettingsRoute().push(context), icon: const Icon(FluentIcons.options_24_filled), tooltip: t.config.quickSettings)],
              ),
              switch (serverData) {
                AsyncData(value: final data) => MultiSliver(
                  children: [
                    // بخش نمایش اطلاعات مصرف کاربر
                    SliverToBoxAdapter(child: UserUsageInfo(usage: data.usage)),
                    const SliverGap(16),

                    // دکمه اتصال
                    const SliverToBoxAdapter(child: Column(children: [ConnectionButton(), ActiveProxyDelayIndicator()])),
                    const SliverGap(24),

                    // لیست کانفیگ ها
                    ConfigSection(title: "V2Ray", configs: data.configs.where((c) => c.type == ConfigType.v2ray).toList()),
                    const SliverGap(16),
                    ConfigSection(title: "OpenVPN", configs: data.configs.where((c) => c.type == ConfigType.openvpn).toList()),

                    // فوتر در حالت موبایل
                    if (MediaQuery.sizeOf(context).width < 840) const SliverToBoxAdapter(child: ActiveProxyFooter()),
                  ],
                ),
                AsyncError(:final error) => SliverErrorBodyPlaceholder(t.presentShortError(error)),
                _ => const SliverLoadingBodyPlaceholder(),
              },
            ],
          ),
        ],
      ),
    );
  }
}

// ویجت نمایش اطلاعات مصرف
class UserUsageInfo extends HookConsumerWidget {
  const UserUsageInfo({super.key, required this.usage});
  final UserUsage usage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(t.profile.subscription.traffic, style: theme.textTheme.bodyMedium),
                  Text("${usage.remainingDataGB.toStringAsFixed(2)} GB", style: theme.textTheme.titleMedium),
                ],
              ),
              Column(
                children: [
                  Text(t.profile.subscription.expireDate, style: theme.textTheme.bodyMedium),
                  Text(t.profile.subscription.remainingDuration(duration: usage.remainingDays.toString()), style: theme.textTheme.titleMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ویجت نمایش لیست کانفیگ ها
class ConfigSection extends ConsumerWidget {
  const ConfigSection({super.key, required this.title, required this.configs});

  final String title;
  final List<ServerConfig> configs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedConfig = ref.watch(selectedConfigNotifierProvider);

    if (configs.isEmpty) return const SliverToBoxAdapter();

    return MultiSliver(
      pushPinnedChildren: true,
      children: [
        SliverPinnedHeader(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surface,
            child: Text(title, style: theme.textTheme.titleLarge),
          ),
        ),
        SliverList.builder(
          itemCount: configs.length,
          itemBuilder: (context, index) {
            final config = configs[index];
            final isSelected = selectedConfig?.id == config.id;

            return ListTile(
              title: Text(config.name),
              leading: Icon(config.type == ConfigType.v2ray ? FluentIcons.globe_24_regular : FluentIcons.shield_24_regular, color: isSelected ? theme.colorScheme.primary : null),
              trailing: isSelected ? Icon(FluentIcons.checkmark_24_filled, color: theme.colorScheme.primary) : null,
              selected: isSelected,
              selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.2),
              onTap: () {
                // انتخاب کانفیگ جدید
                ref.read(selectedConfigNotifierProvider.notifier).selectConfig(config);

                // نمایش اعلان موفقیت
                ref.read(inAppNotificationControllerProvider).showSuccessToast("کانفیگ ${config.name} انتخاب شد");
              },
            );
          },
        ),
      ],
    );
  }
}

class AppVersionLabel extends HookConsumerWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    final version = ref.watch(appInfoProvider).requireValue.presentVersion;
    if (version.isBlank) return const SizedBox();

    return Semantics(
      label: t.about.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Text(
          version,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
        ),
      ),
    );
  }
}
