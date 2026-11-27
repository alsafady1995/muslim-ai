import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_ai/l10n/app_localizations_ar.dart';
import 'package:muslim_ai/l10n/app_localizations_en.dart';

void main() {
  test('Arabic ayah counts agree with the number', () {
    final ar = AppLocalizationsAr();
    expect(ar.ayahCount(1), 'آية واحدة');
    expect(ar.ayahCount(2), 'آيتان');
    expect(ar.ayahCount(7), '7 آيات');
    expect(ar.ayahCount(29), '29 آية');
    expect(ar.ayahCount(286), '286 آية');
    expect(ar.ayahsPerDay(20), '20 آية يوميًا');
    expect(ar.ayahsPerDay(5), '5 آيات يوميًا');
  });

  test('English ayah counts', () {
    final en = AppLocalizationsEn();
    expect(en.ayahCount(1), '1 ayah');
    expect(en.ayahCount(7), '7 ayahs');
  });
}
