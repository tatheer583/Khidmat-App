import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'urdu_strings.dart';

class AppLanguage extends ChangeNotifier {
  Locale locale = const Locale('en');
  bool _disposed = false;
  bool saving = false;
  int _generation = 0;
  Future<void> load() async {
    final generation = _generation;
    try {
      final preferences = await SharedPreferences.getInstance();
      if (_disposed || generation != _generation) return;
      locale = Locale(
        preferences.getString('app_language') == 'ur' ? 'ur' : 'en',
      );
      notifyListeners();
    } catch (_) {
      /* English remains usable before preferences are available. */
    }
  }

  Future<void> toggle() async {
    if (saving) return;
    saving = true;
    notifyListeners();
    try {
      _generation++;
      final next = Locale(locale.languageCode == 'ur' ? 'en' : 'ur');
      final preferences = await SharedPreferences.getInstance();
      if (!await preferences.setString('app_language', next.languageCode)) {
        throw StateError('Language could not be saved. Please try again.');
      }
      if (_disposed) return;
      locale = next;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

String translateUrdu(String text) {
  final exact = urduStrings[text];
  if (exact != null) return exact;
  for (final entry in urduStrings.entries.where(
    (entry) => entry.key.contains('{'),
  )) {
    final placeholders = RegExp(r'\{(\w+)\}').allMatches(entry.key).toList();
    var pattern = '^';
    var offset = 0;
    for (final placeholder in placeholders) {
      pattern += RegExp.escape(entry.key.substring(offset, placeholder.start));
      pattern += r'([\s\S]*?)';
      offset = placeholder.end;
    }
    pattern += RegExp.escape(entry.key.substring(offset)) + r'$';
    final match = RegExp(pattern).firstMatch(text);
    if (match == null) continue;
    var result = entry.value;
    for (var i = 0; i < placeholders.length; i++) {
      result = result.replaceAll(
        placeholders[i].group(0)!,
        match.group(i + 1)!,
      );
    }
    return result;
  }
  return text;
}

extension KhidmatTranslations on BuildContext {
  String tr(String text) => Localizations.localeOf(this).languageCode == 'ur'
      ? translateUrdu(text)
      : text;
}

class LocalizedText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final bool translate;
  const LocalizedText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.translate = true,
  });
  @override
  Widget build(BuildContext context) => Text(
    translate ? context.tr(data) : data,
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    softWrap: softWrap,
  );
}

InputDecoration localizedDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
  String? helperText,
  String? counterText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) => InputDecoration(
  labelText: labelText == null ? null : context.tr(labelText),
  hintText: hintText == null ? null : context.tr(hintText),
  helperText: helperText == null ? null : context.tr(helperText),
  counterText: counterText,
  prefixIcon: prefixIcon,
  suffixIcon: suffixIcon,
);

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});
  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: context.watch<AppLanguage>().saving
        ? null
        : () async {
            try {
              await context.read<AppLanguage>().toggle();
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr(
                        'Language could not be saved. Please try again.',
                      ),
                    ),
                  ),
                );
              }
            }
          },
    icon: const Icon(Icons.language),
    label: Text(
      Localizations.localeOf(context).languageCode == 'ur' ? 'English' : 'اردو',
    ),
  );
}
