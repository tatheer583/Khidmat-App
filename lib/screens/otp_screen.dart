import '../localization/app_language.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/backend_session.dart';

String normalizePhone(String input) {
  var value = input.replaceAll(RegExp(r'[\s()-]'), '');
  if (value.startsWith('03')) value = '+92${value.substring(1)}';
  if (value.startsWith('923')) value = '+$value';
  if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(value)) {
    throw const FormatException(
      'Use a phone number with country code, such as +923001234567.',
    );
  }
  return value;
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  String? _sentTo;
  String? _error;
  bool _busy = false;
  int _seconds = 0;
  Timer? _timer;
  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final phone = normalizePhone(_phone.text);
      await context.read<BackendSession>().client.auth.signInWithOtp(
        phone: phone,
      );
      if (!mounted) return;
      setState(() {
        _sentTo = phone;
        _seconds = 60;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _seconds--);
        if (_seconds <= 0) timer.cancel();
      });
    } catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_sentTo == null || !RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
      setState(() => _error = 'Enter the six-digit SMS code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<BackendSession>().client.auth.verifyOTP(
        phone: _sentTo,
        token: _code.text.trim(),
        type: OtpType.sms,
      );
    } catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: const [LanguageButton()],
      title: const LocalizedText('Phone sign in'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const LocalizedText(
          'Enter your phone number. We will send you a verification code.',
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _phone,
          enabled: !_busy && _sentTo == null,
          keyboardType: TextInputType.phone,
          decoration: localizedDecoration(
            context,
            labelText: 'Phone number',
            hintText: '+92…',
          ),
        ),
        const SizedBox(height: 16),
        if (_sentTo != null) ...[
          LocalizedText('Code sent to $_sentTo'),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: localizedDecoration(context, labelText: 'SMS code'),
          ),
        ],
        if (_error != null)
          LocalizedText(
            _error!,
            style: const TextStyle(color: Colors.redAccent),
          ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _busy
              ? null
              : _sentTo == null
              ? _send
              : _verify,
          child: LocalizedText(
            _busy
                ? 'Please wait…'
                : _sentTo == null
                ? 'Send code'
                : 'Verify & continue',
          ),
        ),
        if (_sentTo != null) ...[
          TextButton(
            onPressed: _busy || _seconds > 0 ? null : _send,
            child: LocalizedText(
              _seconds > 0 ? 'Resend in ${_seconds}s' : 'Resend code',
            ),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () {
                    _timer?.cancel();
                    setState(() {
                      _sentTo = null;
                      _code.clear();
                      _error = null;
                    });
                  },
            child: const LocalizedText('Use another number'),
          ),
        ],
      ],
    ),
  );
}
