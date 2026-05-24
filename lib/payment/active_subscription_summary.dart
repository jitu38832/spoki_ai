/// Server snapshot from `GET /subscriptions/me`.
class ActiveSubscriptionSummary {
  const ActiveSubscriptionSummary({
    this.status,
    this.planCode,
    this.billingPeriod,
    this.endsAt,
    this.paymentProvider,
  });

  /// e.g. `active`, `canceled`, `expired`.
  final String? status;

  final String? planCode;

  /// `month`, `year`, etc.
  final String? billingPeriod;

  final DateTime? endsAt;

  final String? paymentProvider;

  /// True only when backend marks active **and** the period has not ended.
  bool get hasActivePremium {
    if ((status ?? '').toLowerCase().trim() != 'active') return false;
    final e = endsAt;
    if (e == null) return true;
    return e.toUtc().isAfter(DateTime.now().toUtc().subtract(const Duration(seconds: 30)));
  }

  bool get isQaBypass =>
      (paymentProvider?.toLowerCase() ?? '') == 'qa_email_allowlist';

  bool get isMonthly =>
      (billingPeriod?.toLowerCase() ?? '') == 'month' ||
      (planCode?.toLowerCase().contains('month') ?? false);

  bool get isYearly =>
      (billingPeriod?.toLowerCase() ?? '') == 'year' ||
      (planCode?.toLowerCase().contains('year') ?? false);

  /// When we cannot classify (e.g. unknown plan code).
  BillingTier get tier {
    if (isMonthly) return BillingTier.monthly;
    if (isYearly) return BillingTier.yearly;
    return BillingTier.unknown;
  }

  static ActiveSubscriptionSummary? fromJson(dynamic rawAny) {
    if (rawAny == null) return null;

    Map<String, dynamic>? asMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v.map((k, val) => MapEntry('$k', val)));
      return null;
    }

    final raw = asMap(rawAny);
    if (raw == null) return null;

    DateTime? parseDate(dynamic v) {
      if (v == null || v.toString().isEmpty) return null;
      return DateTime.tryParse(v.toString());
    }

    final planRaw = asMap(raw['plan']);
    final bpPlan = planRaw?['billingPeriod']?.toString().trim();
    final codePlan = planRaw?['code']?.toString().trim();

    final billingPeriod = bpPlan ??
        raw['billingPeriod']?.toString().trim() ??
        '';

    final planCode = codePlan ?? raw['planCode']?.toString().trim() ?? '';

    final paymentRaw = asMap(raw['payment']);

    final statusStr = raw['status']?.toString().trim();

    return ActiveSubscriptionSummary(
      status: statusStr,
      planCode: planCode.isEmpty ? null : planCode,
      billingPeriod: billingPeriod.isEmpty ? null : billingPeriod,
      endsAt: parseDate(raw['endsAt'] ?? raw['ends_at']),
      paymentProvider: paymentRaw?['provider']?.toString(),
    );
  }
}

enum BillingTier {
  monthly,
  yearly,
  unknown,
}
