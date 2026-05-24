import 'package:spokiai/payment/SubscriptionService.dart';
import 'package:spokiai/payment/chat_freemium.dart';
import 'package:spokiai/payment/story_freemium.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/viewmodel/repository/app_repository.dart';

/// After `users/me` succeeds and [token] is stored — sync IAP flag from prefs and refresh
/// chat freemium from the backend so premium + quotas match the logged-in account.
Future<void> syncBillingAndChatQuotasAfterLogin(AppRepository repo) async {
  SubscriptionService.instance.reloadBillingFlagFromPrefs();
  final token =
      PreferenceManager.getStringValue(key: 'token')?.trim() ?? '';
  if (token.isEmpty) return;
  await Future.wait<void>([
    ChatFreemium.syncFromBackend(repo, token),
    StoryFreemium.syncFromBackend(repo, token),
  ]);
}
