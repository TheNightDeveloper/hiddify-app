import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/features/auth/notifier/auth_state_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// فایل صفحه ورود به حساب کاربری
// This is the login screen file

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    // کنترل کننده های متن برای فیلدهای ورودی
    final usernameController = useTextEditingController(text: "admin@example.com");
    final passwordController = useTextEditingController(text: "Admin123");

    // گوش دادن به تغییرات وضعیت برای نمایش خطا
    ref.listen(authStateNotifierProvider, (previous, next) {
      if (next case AsyncError(:final error)) {
        ref.read(inAppNotificationControllerProvider).showErrorToast(t.presentError(error).message ?? "Unknown error");
      }
    });

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Hiddify", // Or your app's name
                  style: theme.textTheme.headlineMedium,
                ),
                const Gap(32),
                TextFormField(
                  controller: usernameController,
                  decoration: InputDecoration(labelText: t.auth.username, border: const OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const Gap(16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: t.auth.password, border: const OutlineInputBorder()),
                ),
                const Gap(24),
                Consumer(
                  builder: (context, ref, child) {
                    final state = ref.watch(authStateNotifierProvider);
                    return FilledButton(
                      onPressed: state.isLoading
                          ? null
                          : () {
                              ref.read(authStateNotifierProvider.notifier).login(usernameController.text, passwordController.text);
                            },
                      child: state.isLoading ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(t.auth.login),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
