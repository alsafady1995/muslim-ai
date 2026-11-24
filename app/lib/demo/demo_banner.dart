import 'package:flutter/material.dart';

/// Thin strip on top of every screen in the web preview, so nobody mistakes
/// simulated parts for the real thing. Tap it for the full list.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key, required this.child});
  final Widget child;

  static bool _ar(BuildContext c) => Localizations.localeOf(c).languageCode == 'ar';

  void _details(BuildContext context) {
    final ar = _ar(context);
    final lines = ar
        ? const [
            'حقيقي: نص القرآن والترجمة، تلاوة القرّاء الصوتية، الأذكار، كل الشاشات والتصميم، النقاط والمستويات والسلسلة والأهداف وخطة الحفظ (تُحسب على جهازك).',
            'محاكاة: الحساب (ضيف محلي، تسجيل Apple/Google/البريد شكلي)، إجابات الذكاء الاصطناعي (آيات حقيقية لكن الشرح نص ثابت)، البحث الذكي (بحث بالكلمات)، تحليل التلاوة (لا يستمع فعلاً، النتيجة عشوائية)، الاشتراك (لا دفع، يتفعّل محلياً).',
            'غير متاح على الويب: الإشعارات اليومية.',
            'بياناتك محفوظة في هذا المتصفح فقط.',
          ]
        : const [
            'Real: Quran text and translation, reciter audio, adhkar, every screen and the design, XP, levels, streaks, goals and hifz scheduling (computed on your device).',
            'Simulated: account (local guest; Apple/Google/email sign-in is cosmetic), AI answers (real verses, placeholder explanation), smart search (keyword match), recitation analysis (does not really listen; random result), subscription (no payment; unlocks locally).',
            'Not available on web: daily notifications.',
            'Your data is kept in this browser only.',
          ];
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(ar ? 'نسخة معاينة تجريبية' : 'Preview build'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final l in lines) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(l))],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(ar ? 'حسناً' : 'OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = _ar(context);
    final top = MediaQuery.paddingOf(context).top;
    return Column(
      children: [
        Material(
          color: const Color(0xFFF5B841),
          child: InkWell(
            onTap: () => _details(context),
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, top + 4, 12, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.science_outlined, size: 16, color: Colors.black87),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      ar
                          ? 'نسخة تجريبية: الذكاء الاصطناعي والاشتراك محاكاة · التفاصيل'
                          : 'Preview: AI and payments are simulated · details',
                      style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(context: context, removeTop: true, child: child),
        ),
      ],
    );
  }
}
