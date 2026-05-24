import 'dart:convert';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

/// Builds JSON for `POST /subscriptions/iap/register` from Flutter IAP payloads.
///
/// Payload fields are forwarded for backend persistence — this is **not** receipt
/// or Play API verification by itself.
class IapRegisterPayload {
  IapRegisterPayload._();

  /// `monthly` / `yearly` for known app SKUs; omit for `test_plan` etc. when
  /// backend maps by product id alone.
  static String? planCodeForProduct(String productId) {
    switch (productId.trim().toLowerCase()) {
      case 'montlhy_subs':
      case 'monthly_subs':
      case 'montlhy':
        return 'monthly';
      case 'yearly_subs':
      case 'yearly':
        return 'yearly';
      default:
        return null;
    }
  }

  /// Returns null when mandatory fields cannot be filled (skip the HTTP call).
  static Map<String, dynamic>? build(PurchaseDetails purchase) {
    switch (purchase.verificationData.source) {
      case 'google_play':
        return _googlePlay(purchase);
      case 'app_store':
        return _appStore(purchase);
      default:
        return null;
    }
  }

  static Map<String, dynamic>? _googlePlay(PurchaseDetails p) {
    final token = p.verificationData.serverVerificationData.trim();
    if (token.isEmpty) return null;

    final body = <String, dynamic>{
      'platform': 'google',
      'productId': p.productID,
      'purchaseToken': token,
    };

    Map<String, dynamic>? jsonObj;
    final localRaw = p.verificationData.localVerificationData.trim();
    if (localRaw.startsWith('{')) jsonObj = _tryParseObj(localRaw);

    if (jsonObj != null) {
      final pkg = jsonObj['packageName'] ?? jsonObj['package_name'];
      final pkgStr = stringify(pkg);
      if (pkgStr != null) body['packageName'] = pkgStr;

      final order = jsonObj['orderId'] ?? jsonObj['order_id'];
      final orderStr = stringify(order);
      if (orderStr != null) body['orderId'] = orderStr;

      final exp = _expiresMillisFlat(jsonObj);
      if (exp != null) body['expiresAtMillis'] = exp;
    }

    if (p is GooglePlayPurchaseDetails) {
      final bw = p.billingClientPurchase;
      if (!body.containsKey('packageName') && bw.packageName.isNotEmpty) {
        body['packageName'] = bw.packageName;
      }
      if ((!body.containsKey('orderId') || '${body['orderId']}'.isEmpty) &&
          bw.orderId.isNotEmpty) {
        body['orderId'] = bw.orderId;
      }
      if (!body.containsKey('expiresAtMillis')) {
        final j = _tryParseObj(bw.originalJson);
        final exp = j == null ? null : _expiresMillisFlat(j);
        if (exp != null) body['expiresAtMillis'] = exp;
      }
    }

    final pc = planCodeForProduct(p.productID);
    if (pc != null) body['planCode'] = pc;

    _omitNullEmpty(body);
    return body;
  }

  static Map<String, dynamic>? _appStore(PurchaseDetails p) {
    final local = p.verificationData.localVerificationData.trim();
    final server = p.verificationData.serverVerificationData.trim();

    final merged = <String, dynamic>{};

    if (_looksLikeJws(server)) {
      final jwsPayload = _decodeJwtPayloadMap(server);
      if (jwsPayload != null) merged.addAll(jwsPayload);
    }

    final localObj = local.startsWith('{') ? _tryParseObj(local) : null;
    if (localObj != null) merged.addAll(localObj);

    final fromMergedTxn = digStringInsensitive(merged, const [
      'transactionId',
      'transactionIdentifier',
    ]);
    final fromMergedOriginal = digStringInsensitive(merged, const [
      'originalTransactionId',
      'originalTransactionIdentifier',
    ]);

    var transactionId =
        firstNonEmpty([fromMergedTxn, p.purchaseID?.trim()]);
    var originalTx = firstNonEmpty([fromMergedOriginal]);

    transactionId ??= '';
    originalTx ??= '';

    if (transactionId.isEmpty && originalTx.isNotEmpty) {
      transactionId = originalTx;
    }
    if (originalTx.isEmpty && transactionId.isNotEmpty) {
      originalTx = transactionId;
    }
    if (transactionId.isEmpty && originalTx.isEmpty) return null;

    final expiresMillis = _expiresMillisFlat(merged);

    final body = <String, dynamic>{
      'platform': 'apple',
      'productId': p.productID,
      'transactionId': transactionId,
      'originalTransactionId': originalTx,
      if (expiresMillis != null) 'expiresAtMillis': expiresMillis,
    };

    if (p is SK2PurchaseDetails) {
      final aat = p.appAccountToken?.trim();
      if (aat != null && aat.isNotEmpty) body['appAccountToken'] = aat;
    }

    final pc = planCodeForProduct(p.productID);
    if (pc != null) body['planCode'] = pc;

    _omitNullEmpty(body);
    return body;
  }

  static void _omitNullEmpty(Map<String, dynamic> m) {
    m.removeWhere((_, v) =>
        v == null || (v is String && v.trim().isEmpty));
  }

  static bool _looksLikeJws(String s) =>
      RegExp(r'^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$').hasMatch(
        s.trim(),
      );

  static Map<String, dynamic>? _decodeJwtPayloadMap(String jwt) {
    try {
      final parts = jwt.trim().split('.');
      if (parts.length != 3) return null;

      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final jsonStr = utf8.decode(base64.decode(payload));
      final decoded = json.decode(jsonStr);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  static Map<String, dynamic>? _tryParseObj(String raw) {
    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  static String? digStringInsensitive(
    Map<String, dynamic> map,
    List<String> aliases,
  ) {
    aliasLoop:
    for (final alias in aliases) {
      final want = alias.toLowerCase();
      for (final e in map.entries) {
        if (e.key.toLowerCase() == want) {
          final s = stringify(e.value);
          if (s != null) return s;
          continue aliasLoop;
        }
      }
    }
    return null;
  }

  static String? stringify(dynamic value) {
    if (value == null) return null;
    if (value is double) {
      if (value.remainder(1) == 0 && value.abs() <= 9007199254740992.0) {
        return value.toInt().toString();
      }
      final s = value.toString().trim();
      return s.isEmpty ? null : s;
    }
    if (value is num) {
      final t = value.toString().trim();
      return t.isEmpty ? null : t;
    }

    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String? firstNonEmpty(List<String?> values) {
    for (final v in values) {
      final t = v?.trim() ?? '';
      if (t.isNotEmpty) return t;
    }
    return null;
  }

  static int? _expiresMillisFlat(Map<String, dynamic> flat) {
    for (final e in flat.entries) {
      final lk = e.key.toLowerCase();
      if (!lk.contains('expir')) continue;
      final v = coerceExpiryMillis(e.value);
      if (v != null) return v;
    }
    return null;
  }

  /// Best-effort: seconds vs ms heuristic for ints.
  static int? coerceExpiryMillis(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw > 946684800000 ? raw : raw * 1000;
    if (raw is double) return coerceExpiryMillis(raw.toInt());
    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return null;
      final n = int.tryParse(s);
      if (n != null) {
        return n > 946684800000 ? n : n * 1000;
      }
      return DateTime.tryParse(s)?.millisecondsSinceEpoch;
    }
    return null;
  }
}
