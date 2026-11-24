import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'demo_store.dart';

/// HTTP client handed to Supabase in the web preview. It answers the auth
/// endpoints locally (guest sign-up, email code, sign-out) so the real
/// GoTrue client, router redirects and session persistence all run unchanged.
/// Database and function calls never reach here: the repositories are replaced.
class DemoHttpClient extends http.BaseClient {
  static const url = 'https://demo.muslimai.invalid';
  static const anonKey = 'demo-preview-key';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    Map<String, dynamic> body = {};
    if (request is http.Request && request.body.isNotEmpty) {
      try {
        body = (jsonDecode(request.body) as Map).cast<String, dynamic>();
      } catch (_) {}
    }

    if (path.endsWith('/auth/v1/signup')) {
      final meta = (body['data'] as Map?)?.cast<String, dynamic>() ?? {};
      DemoStore.instance.bootstrapUser('${meta['locale'] ?? 'ar'}');
      await DemoStore.instance.save();
      return _json(_session(email: null, meta: meta));
    }
    if (path.endsWith('/auth/v1/token') || path.endsWith('/auth/v1/verify')) {
      final email = body['email'] as String?;
      if (DemoStore.instance.profile.isEmpty) DemoStore.instance.bootstrapUser('ar');
      return _json(_session(email: email, meta: const {}));
    }
    if (path.endsWith('/auth/v1/user')) {
      return _json(_user(email: body['email'] as String?, meta: const {}));
    }
    if (path.endsWith('/auth/v1/otp') || path.endsWith('/auth/v1/recover')) {
      return _json({});
    }
    if (path.endsWith('/auth/v1/logout')) {
      return http.StreamedResponse(const Stream.empty(), 204, request: request);
    }
    return _json({'error': 'not_available_in_demo'}, status: 404);
  }

  static Map<String, dynamic> _user({String? email, required Map<String, dynamic> meta}) {
    final id = DemoStore.instance.state['user_id'] ??= const Uuid().v4();
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': id,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': email ?? '',
      'is_anonymous': email == null,
      'app_metadata': {'provider': email == null ? 'anonymous' : 'email'},
      'user_metadata': meta,
      'identities': <dynamic>[],
      'created_at': now,
      'updated_at': now,
    };
  }

  static Map<String, dynamic> _session({String? email, required Map<String, dynamic> meta}) {
    const expiresIn = 10 * 365 * 24 * 3600;
    final user = _user(email: email, meta: meta);
    final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn;
    String b64(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
    final jwt =
        '${b64({'alg': 'HS256', 'typ': 'JWT'})}.'
        '${b64({'sub': user['id'], 'role': 'authenticated', 'aud': 'authenticated', 'exp': exp, 'is_anonymous': email == null})}.'
        'demo-signature';
    return {
      'access_token': jwt,
      'token_type': 'bearer',
      'expires_in': expiresIn,
      'expires_at': exp,
      'refresh_token': 'demo-refresh-token',
      'user': user,
    };
  }

  static http.StreamedResponse _json(Object body, {int status = 200}) {
    final bytes = utf8.encode(jsonEncode(body));
    return http.StreamedResponse(
      Stream.value(bytes),
      status,
      headers: {'content-type': 'application/json'},
      contentLength: bytes.length,
    );
  }
}
