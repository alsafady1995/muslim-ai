import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/analytics.dart';
import '../../core/config.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

/// linkMode = true: a guest saves progress by attaching Apple / Google / email to the
/// existing anonymous account (keeps all XP, streaks, hifz). Otherwise a normal sign-in.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.linkMode = false});
  final bool linkMode;
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  GoTrueClient get _auth => ref.read(supabaseProvider).auth;

  Future<void> _run(String method, Future<void> Function() action) async {
    final genericError = context.l10n.errorGeneric;
    setState(() => _busy = true);
    try {
      await action();
      Analytics.track(Events.accountLinked, {'method': method, 'link': widget.linkMode});
      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (e) {
      if (e is SignInWithAppleAuthorizationException && e.code == AuthorizationErrorCode.canceled) return;
      if (e is GoogleSignInException && e.code == GoogleSignInExceptionCode.canceled) return;
      _toast(genericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _nonce() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(32, (_) => r.nextInt(256)));
  }

  Future<void> _apple() => _run('apple', () async {
        final rawNonce = _nonce();
        final cred = await SignInWithApple.getAppleIDCredential(
          scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
          nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
        );
        final idToken = cred.identityToken!;
        if (widget.linkMode) {
          await _auth.linkIdentityWithIdToken(provider: OAuthProvider.apple, idToken: idToken, nonce: rawNonce);
        } else {
          await _auth.signInWithIdToken(provider: OAuthProvider.apple, idToken: idToken, nonce: rawNonce);
        }
        final name = [cred.givenName, cred.familyName].whereType<String>().join(' ');
        if (name.isNotEmpty) await ref.read(userRepoProvider).updateProfile({'display_name': name});
      });

  Future<void> _google() => _run('google', () async {
        final google = GoogleSignIn.instance;
        await google.initialize(
          clientId: Platform.isIOS ? AppConfig.googleIosClientId : null,
          serverClientId: AppConfig.googleWebClientId,
        );
        final account = await google.authenticate();
        final idToken = account.authentication.idToken!;
        if (widget.linkMode) {
          await _auth.linkIdentityWithIdToken(provider: OAuthProvider.google, idToken: idToken);
        } else {
          await _auth.signInWithIdToken(provider: OAuthProvider.google, idToken: idToken);
        }
        if (account.displayName != null) {
          await ref.read(userRepoProvider).updateProfile({'display_name': account.displayName});
        }
      });

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!email.contains('@')) return _toast(context.l10n.invalidEmail);
    setState(() => _busy = true);
    try {
      if (widget.linkMode) {
        await _auth.updateUser(UserAttributes(email: email));
      } else {
        await _auth.signInWithOtp(email: email, shouldCreateUser: true);
      }
      setState(() => _codeSent = true);
    } on AuthException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() => _run('email', () async {
        await _auth.verifyOTP(
          email: _email.text.trim(),
          token: _code.text.trim(),
          type: widget.linkMode ? OtpType.emailChange : OtpType.email,
        );
      });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(widget.linkMode ? l10n.saveProgress : l10n.signIn)),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Text(widget.linkMode ? l10n.saveProgressBody : l10n.signInBody, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (Platform.isIOS) ...[
            FilledButton.icon(onPressed: _busy ? null : _apple, icon: const Icon(Icons.apple), label: Text(l10n.continueWithApple)),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(onPressed: _busy ? null : _google, icon: const Icon(Icons.g_mobiledata, size: 32), label: Text(l10n.continueWithGoogle)),
          const SizedBox(height: 24),
          Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.all(8), child: Text(l10n.or)), const Expanded(child: Divider())]),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            enabled: !_codeSent,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: l10n.email),
          ),
          const SizedBox(height: 12),
          if (_codeSent) ...[
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(labelText: l10n.verificationCode),
            ),
            FilledButton(onPressed: _busy ? null : _verify, child: Text(l10n.verify)),
          ] else
            FilledButton.tonal(onPressed: _busy ? null : _sendCode, child: Text(l10n.sendCode)),
          if (_busy) const Padding(padding: EdgeInsets.all(16), child: LoadingView()),
        ]),
      ),
    );
  }
}
