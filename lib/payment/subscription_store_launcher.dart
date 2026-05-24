import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

/// Opens the platform subscription management UI (user can switch/cancel there).
class SubscriptionStoreLauncher {
  SubscriptionStoreLauncher._();

  static String? _playPackageName;

  /// Call once at startup with your Android applicationId (e.g. from `android/app/build.gradle`).
  static void configureAndroidPackageName(String packageName) {
    _playPackageName = packageName.trim().isEmpty ? null : packageName.trim();
  }

  static Future<bool> openManageSubscriptions() async {
    if (Platform.isIOS) {
      final u = Uri.parse('https://apps.apple.com/account/subscriptions');
      if (await canLaunchUrl(u)) {
        return launchUrl(u, mode: LaunchMode.externalApplication);
      }
      return false;
    }
    if (Platform.isAndroid) {
      final pkg = _playPackageName ?? 'com.spokiai';
      final u = Uri.parse(
        'https://play.google.com/store/account/subscriptions?package=$pkg&hl=en',
      );
      if (await canLaunchUrl(u)) {
        return launchUrl(u, mode: LaunchMode.externalApplication);
      }
      return false;
    }
    return false;
  }
}
