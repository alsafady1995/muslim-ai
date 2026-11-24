import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when the user hit a weekly AI limit; the UI shows the limit sheet (lib/core/limits.dart).
class QuotaExceeded implements Exception {
  QuotaExceeded(this.feature, {required this.premium, required this.limit, this.resetsAt});
  final String feature; // recitation | hifz | ask | search
  final bool premium;
  final int limit;
  final DateTime? resetsAt; // Friday 00:00 local time
}

/// Thrown when the user's AI allowance for the current period is used up (server-enforced
/// cost cap: AI may never cost more than half of what the user pays). Not a paywall moment
/// for subscribers; show a friendly message with the reset date instead.
class AiBudgetExhausted implements Exception {
  AiBudgetExhausted(this.feature, {required this.premium, required this.tier, this.resetsAt});
  final String feature;
  final bool premium;
  final String tier; // free | trial | premium | promo
  final DateTime? resetsAt;
}

class ApiError implements Exception {
  ApiError(this.code, [this.message]);
  final String code;
  final String? message;
  @override
  String toString() => 'ApiError($code, $message)';
}

/// Thin wrapper around Supabase Edge Functions with uniform error mapping.
class EdgeApi {
  EdgeApi(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>> call(String fn, Map<String, dynamic> body) async {
    try {
      final res = await _client.functions.invoke(fn, body: body);
      return (res.data as Map).cast<String, dynamic>();
    } on FunctionException catch (e) {
      final details = e.details is Map ? (e.details as Map).cast<String, dynamic>() : <String, dynamic>{};
      if (e.status == 402 && details['error'] == 'quota_exceeded') {
        throw QuotaExceeded('${details['feature']}',
            premium: details['premium'] == true,
            limit: (details['limit'] as num?)?.toInt() ?? 0,
            resetsAt: DateTime.tryParse('${details['resets_at'] ?? ''}')?.toLocal());
      }
      if (e.status == 429 && details['error'] == 'ai_budget_exhausted') {
        throw AiBudgetExhausted('${details['feature']}',
            premium: details['premium'] == true,
            tier: '${details['tier'] ?? 'free'}',
            resetsAt: DateTime.tryParse('${details['resets_at'] ?? ''}'));
      }
      throw ApiError('${details['error'] ?? 'http_${e.status}'}', details['message'] as String?);
    }
  }
}
