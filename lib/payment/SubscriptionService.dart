import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:spokiai/model/commonresponse.dart';
import 'package:spokiai/payment/chat_freemium.dart';
import 'package:spokiai/payment/iap_register_payload.dart';
import 'package:spokiai/payment/story_freemium.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/viewmodel/repository/app_repository.dart';
import 'package:spokiai/viewmodel/repository/response_status.dart';

/// Global store / subscription listener. Use [instance] only — do not dispose from UI.
///
/// **`premium_subscribed` is written only after the backend ACKs IAP** (`subscriptions/iap/register`).
/// Restore/purchase callbacks must not bypass the logged-in user's server entitlement —
/// [ChatFreemium] uses the quota API for chat premium, not this flag alone.
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  final InAppPurchase _iap = InAppPurchase.instance;

  // ignore: unused_field — keeps stream alive; cancelling would break entitlement updates.
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Queries store SKUs for production plans only.
  final List<String> productIds = [
    'montlhy_subs',
    'yearly_subs',
  ];

  List<ProductDetails> products = [];

  bool isSubscribed = false;

  bool _initialized = false;

  /// Idempotent; safe to await from [main] and from [SubscriptionScreen].
  Future<void> ensureInitialized() async {
    if (_initialized) return;

    final bool available = await _iap.isAvailable();

    if (!available) {
      // ignore: avoid_print
      print('Store not available');
      return;
    }

    _initialized = true;

    reloadBillingFlagFromPrefs();

    _subscription = _iap.purchaseStream.listen(
      (purchaseDetailsList) {
        for (final purchase in purchaseDetailsList) {
          switch (purchase.status) {
            case PurchaseStatus.pending:
              // ignore: avoid_print
              print('⏳ Purchase Pending');
              break;

            case PurchaseStatus.purchased:
            case PurchaseStatus.restored:
              // ignore: avoid_print
              print(
                  purchase.status == PurchaseStatus.restored ? '🔄 Purchase Restored' : '✅ Purchase Successful');

              /// Never mark premium locally until `/subscriptions/iap/register` succeeds.
              unawaited(_processStoreReceiptOnServerThenLocal(purchase));
              break;

            case PurchaseStatus.error:
              // ignore: avoid_print
              print('❌ Purchase Failed');
              // ignore: avoid_print
              print(purchase.error);

              break;

            case PurchaseStatus.canceled:
              // ignore: avoid_print
              print('⚠️ Purchase Cancelled');

              break;
          }

          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
        }
      },
    );

    await loadProducts();

    // Replay entitlements — receipts are applied only after backend acknowledgment.
    unawaited(restorePurchases());
  }

  Future<void> loadProducts() async {
    final ProductDetailsResponse response =
        await _iap.queryProductDetails(productIds.toSet());

    if (response.notFoundIDs.isNotEmpty) {
      // ignore: avoid_print
      print('Products not found:');
      // ignore: avoid_print
      print(response.notFoundIDs);
    }

    products = response.productDetails;

    // ignore: avoid_print
    print('Products Loaded:');
    // ignore: avoid_print
    print(products.map((e) => e.id).toList());
  }

  /// Grants Premium via `subscriptions/qa/test-grant` when the cached profile email
  /// matches [PreferenceManager.qaSubscriptionBypassEmail] — server rejects all others with 403.
  Future<bool> tryGrantQaSubscriptionBypassViaServer() async {
    if (!PreferenceManager.cachedProfileMatchesQaSubscriptionBypass()) {
      return false;
    }
    reloadBillingFlagFromPrefs();
    if (isSubscribed) return false;

    final token =
        PreferenceManager.getStringValue(key: 'token')?.trim() ?? '';
    if (token.isEmpty) return false;

    try {
      final res =
          await AppRepository().grantQaSubscriptionBypass(token);
      if (!_registrationSucceeded(res)) return false;
      isSubscribed = true;
      PreferenceManager.insertValue(
          key: PreferenceManager.premiumSubscribedKey, value: true);
      await _syncChatFreemiumAfterBilling();
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Billing QA bypass failed: $e');
      return false;
    }
  }

  Future<void> buySubscription(ProductDetails product) async {
    try {
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: product);

      await _iap.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      // ignore: avoid_print
      print('🚀 Purchase flow started');
    } catch (e) {
      // ignore: avoid_print
      print('Purchase Error: $e');
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();

    // ignore: avoid_print
    print('Restore Started');
  }

  /// Sync [isSubscribed] from persisted prefs after login or app start.
  /// Prefs are only set once the billing API acknowledges IAP for this deployment.
  void reloadBillingFlagFromPrefs() {
    isSubscribed = PreferenceManager.getBooleanValue(
          key: PreferenceManager.premiumSubscribedKey,
        ) ==
        true;
  }

  /// Call on logout alongside [PreferenceManager.clearPreferences] so in-memory IAP state resets.
  void clearSessionBillingState() {
    isSubscribed = false;
  }

  /// No-op — [instance] keeps the IAP stream alive for the app lifetime.
  void dispose() {}

  Future<void> _processStoreReceiptOnServerThenLocal(
      PurchaseDetails purchase) async {
    final registered = await _registerPurchaseWithBackend(purchase);
    if (!registered) {
      // ignore: avoid_print
      print(
        'Billing: entitlement not upgraded — IAP register skipped or failed for ${purchase.productID}',
      );
      return;
    }
    isSubscribed = true;
    PreferenceManager.insertValue(
      key: PreferenceManager.premiumSubscribedKey,
      value: true,
    );
    await _syncChatFreemiumAfterBilling();
  }

  Future<void> _syncChatFreemiumAfterBilling() async {
    final token =
        PreferenceManager.getStringValue(key: 'token')?.trim() ?? '';
    if (token.isEmpty) return;
    try {
      final repo = AppRepository();
      await Future.wait<void>([
        ChatFreemium.syncFromBackend(repo, token),
        StoryFreemium.syncFromBackend(repo, token),
      ]);
    } catch (_) {}
  }

  /// Sends purchase metadata to `{BASEURL}subscriptions/iap/register`.
  Future<bool> _registerPurchaseWithBackend(PurchaseDetails purchase) async {
    final token = PreferenceManager.getStringValue(key: 'token')?.trim() ?? '';
    if (token.isEmpty) {
      // ignore: avoid_print
      print('IAP register skipped: no login token');
      return false;
    }

    final body = IapRegisterPayload.build(purchase);
    if (body == null) {
      // ignore: avoid_print
      print(
        'IAP register skipped: insufficient store metadata for '
        '${purchase.productID} (${purchase.verificationData.source})',
      );
      return false;
    }

    try {
      final res = await AppRepository().registerIapSubscription(token, body);
      // ignore: avoid_print
      print(
        'IAP register: status=${res.statusCode} '
        '${res.response ?? ''}',
      );
      return _registrationSucceeded(res);
    } on ErrorData catch (e) {
      // ignore: avoid_print
      print('IAP register failed (${e.code}): ${e.message}');
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('IAP register error: $e');
      return false;
    }
  }

  static bool _registrationSucceeded(ResponseData res) {
    final code = res.statusCode ?? 0;
    if (code < 200 || code >= 300) return false;
    final raw = res.response;
    if (raw is CommonResponse && raw.success == false) return false;
    return true;
  }
}
