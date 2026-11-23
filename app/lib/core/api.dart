import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when the user hit a daily AI limit; the UI shows the paywall.
class QuotaExceeded implements Exception {
  QuotaExceeded(this.feature, {required this.premium, required this.limit});
  final String feature;
  final bool premium;
  final int limit;
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
            premium: details['premium'] == true, limit: (details['limit'] as num?)?.toInt() ?? 0);
      }
      throw ApiError('${details['error'] ?? 'http_${e.status}'}', details['message'] as String?);
    }
  }
}
