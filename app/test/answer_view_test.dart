import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_ai/data/models.dart';
import 'package:muslim_ai/features/ask/answer_view.dart';
import 'package:muslim_ai/l10n/app_localizations.dart';

Widget _wrap(Widget child, Locale locale) => MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  final answer = GroundedAnswer({
    'answer_type': 'needs_scholar',
    'quran': [],
    'hadith': [
      {'reference': 'Sahih Muslim 2999', 'text_ar': 'عجبا لأمر المؤمن', 'text_en': 'How wonderful', 'grade': 'Sahih'},
    ],
    'explanation': 'Patience is rewarded.',
    'scholarly_differences': 'Schools differ.',
    'follow_up_questions': ['What is sabr?'],
    'disclaimer': 'Not a fatwa.',
  });

  testWidgets('renders labelled sections in English', (tester) async {
    await tester.pumpWidget(_wrap(AnswerView(answer: answer, onFollowUp: (_) {}), const Locale('en')));
    expect(find.text('From the Hadith'), findsOneWidget);
    expect(find.text('Explanation'), findsOneWidget);
    expect(find.text('Scholarly views'), findsOneWidget);
    expect(find.textContaining('consult a qualified scholar'), findsOneWidget);
    expect(find.text('Sahih Muslim 2999'), findsOneWidget);
    expect(find.text('What is sabr?'), findsOneWidget);
  });

  testWidgets('renders right-to-left in Arabic', (tester) async {
    await tester.pumpWidget(_wrap(AnswerView(answer: answer), const Locale('ar')));
    expect(find.text('من الحديث الشريف'), findsOneWidget);
    final dir = tester.widget<Directionality>(find.byType(Directionality).first);
    expect(dir.textDirection, TextDirection.rtl);
  });
}
