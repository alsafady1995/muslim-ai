-- Reference/config data the app needs in every environment.
-- Quran text, translations, tafsir and hadith are loaded by scripts/ingest (too large for a migration).
-- NOTE: every religious text below must be reviewed by a qualified scholar before public launch.

insert into public.xp_rules (kind, xp_per_unit, daily_unit_cap, activity_column) values
  ('ayah_read',       2, 300, 'ayahs_read'),
  ('listen_minute',   1,  60, 'minutes_listened'),
  ('adhkar_set',     15,   5, 'adhkar_completed'),
  ('prayer',          5,   5, 'prayers_logged'),
  ('ayah_memorized', 10,  50, 'ayahs_memorized'),
  ('hifz_review',     3, 100, 'reviews_done'),
  ('recitation',     10,  10, 'recitations')
on conflict (kind) do update set xp_per_unit = excluded.xp_per_unit, daily_unit_cap = excluded.daily_unit_cap,
                                 activity_column = excluded.activity_column;

-- Free tier is generous enough to build the habit; premium caps are fair-use limits
-- that keep worst-case AI cost per subscriber below the $0.99 price.
insert into public.plan_limits (feature, free_daily, premium_daily) values
  ('recitation', 3, 100),
  ('ask',        5,  20),
  ('search',    10, 200)
on conflict (feature) do update set free_daily = excluded.free_daily, premium_daily = excluded.premium_daily;

insert into public.achievements (id, name_ar, name_en, description_ar, description_en, icon, xp_reward, metric, threshold, sort) values
  ('first_step',     'الخطوة الأولى',     'First Step',        'اكسب أول نقاط خبرة',          'Earn your first XP',                 'sparkles',  10, 'xp',               1,  1),
  ('streak_3',       'ثلاثة أيام',        '3-Day Streak',      'حافظ على سلسلة ٣ أيام',       'Keep a 3-day streak',                'flame',     20, 'streak',           3,  2),
  ('streak_7',       'أسبوع ثابت',        'Steady Week',       'حافظ على سلسلة ٧ أيام',       'Keep a 7-day streak',                'flame',     50, 'streak',           7,  3),
  ('streak_30',      'شهر من الثبات',     'Month of Istiqamah','حافظ على سلسلة ٣٠ يومًا',     'Keep a 30-day streak',               'flame',    200, 'streak',          30,  4),
  ('streak_100',     'مئة يوم',           '100 Days',          'حافظ على سلسلة ١٠٠ يوم',      'Keep a 100-day streak',              'crown',    500, 'streak',         100,  5),
  ('read_100',       'قارئ',              'Reader',            'اقرأ ١٠٠ آية',                 'Read 100 ayahs',                     'book',      30, 'ayahs_read',     100,  6),
  ('read_1000',      'قارئ مثابر',        'Devoted Reader',    'اقرأ ١٠٠٠ آية',                'Read 1,000 ayahs',                   'book',     150, 'ayahs_read',    1000,  7),
  ('read_6236',      'ختمة',              'Khatmah',           'اقرأ ٦٢٣٦ آية',                'Read 6,236 ayahs',                   'trophy',   600, 'ayahs_read',    6236,  8),
  ('hifz_10',        'بداية الحفظ',       'Hifz Begins',       'احفظ ١٠ آيات',                 'Memorize 10 ayahs',                  'brain',     50, 'ayahs_memorized', 10,  9),
  ('hifz_100',       'حافظ مجتهد',        'Diligent Hafiz',    'احفظ ١٠٠ آية',                 'Memorize 100 ayahs',                 'brain',    300, 'ayahs_memorized',100, 10),
  ('adhkar_7',       'ذاكر',              'Rememberer',        'أكمل ٧ مجموعات أذكار',         'Complete 7 adhkar sets',             'moon',      40, 'adhkar',           7, 11),
  ('adhkar_60',      'لسان رطب',          'Moist Tongue',      'أكمل ٦٠ مجموعة أذكار',         'Complete 60 adhkar sets',            'moon',     200, 'adhkar',          60, 12),
  ('recite_1',       'أول تلاوة',         'First Recitation',  'أكمل أول تحليل تلاوة',          'Complete your first AI recitation',  'mic',       20, 'recitations',      1, 13),
  ('recite_50',      'مرتل',              'Murattil',          'أكمل ٥٠ تحليل تلاوة',          'Complete 50 AI recitations',         'mic',      300, 'recitations',     50, 14),
  ('prayers_35',     'أسبوع صلاة',        'Week of Salah',     'سجّل ٣٥ صلاة',                 'Log 35 prayers',                     'mosque',    50, 'prayers',         35, 15),
  ('level_5',        'المستوى ٥',         'Level 5',           'بلغ المستوى ٥',                'Reach level 5',                      'star',       0, 'level',            5, 16),
  ('level_10',       'المستوى ١٠',        'Level 10',          'بلغ المستوى ١٠',               'Reach level 10',                     'star',       0, 'level',           10, 17)
on conflict (id) do nothing;

-- Audio: EveryAyah per-ayah MP3s. Licence/usage terms must be confirmed before launch (see BLOCKERS.md).
insert into public.reciters (id, name_en, name_ar, style, audio_url_template, is_premium, sort) values
  (1, 'Mishary Rashid Alafasy',          'مشاري راشد العفاسي',     'murattal', 'https://everyayah.com/data/Alafasy_128kbps/{surah3}{ayah3}.mp3',               false, 1),
  (2, 'Mahmoud Khalil Al-Husary',        'محمود خليل الحصري',      'murattal', 'https://everyayah.com/data/Husary_128kbps/{surah3}{ayah3}.mp3',                false, 2),
  (3, 'Al-Husary (Teaching)',            'الحصري (المعلم)',         'muallim',  'https://everyayah.com/data/Husary_Muallim_128kbps/{surah3}{ayah3}.mp3',        false, 3),
  (4, 'Abdul Basit Abdus Samad',         'عبد الباسط عبد الصمد',   'murattal', 'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps/{surah3}{ayah3}.mp3',  true,  4),
  (5, 'Mohamed Siddiq Al-Minshawi',      'محمد صديق المنشاوي',     'murattal', 'https://everyayah.com/data/Minshawy_Murattal_128kbps/{surah3}{ayah3}.mp3',     true,  5),
  (6, 'Maher Al-Muaiqly',                'ماهر المعيقلي',          'murattal', 'https://everyayah.com/data/MaherAlMuaiqly128kbps/{surah3}{ayah3}.mp3',        true,  6),
  (7, 'Abdur-Rahman As-Sudais',          'عبد الرحمن السديس',      'murattal', 'https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/{surah3}{ayah3}.mp3', true,  7),
  (8, 'Saud Ash-Shuraim',                'سعود الشريم',            'murattal', 'https://everyayah.com/data/Saood_ash-Shuraym_128kbps/{surah3}{ayah3}.mp3',     true,  8)
on conflict (id) do nothing;

insert into public.adhkar_categories (id, slug, name_ar, name_en, sort) values
  (1, 'morning',      'أذكار الصباح',      'Morning Adhkar',      1),
  (2, 'evening',      'أذكار المساء',      'Evening Adhkar',      2),
  (3, 'sleep',        'أذكار النوم',       'Before Sleep',        3),
  (4, 'after_prayer', 'أذكار بعد الصلاة',  'After Prayer',        4),
  (5, 'travel',       'أذكار السفر',       'Travel',              5)
on conflict (id) do nothing;

insert into public.adhkar (id, category_id, text_ar, translation_en, repeat_count, reference, sort) values
-- Morning
(101, 1, 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
  'Ayat al-Kursi (Al-Baqarah 2:255).', 1, 'Quran 2:255; al-Nasa''i, al-Sunan al-Kubra 10731', 1),
(102, 1, 'قُلْ هُوَ اللَّهُ أَحَدٌ ... ، قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ... ، قُلْ أَعُوذُ بِرَبِّ النَّاسِ ...',
  'Recite Surat al-Ikhlas, al-Falaq and an-Nas (the app shows the full surahs).', 3, 'Abu Dawud 5082; al-Tirmidhi 3575', 2),
(103, 1, 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ',
  'We have entered the morning and the dominion belongs to Allah. Praise be to Allah. None has the right to be worshipped but Allah alone, without partner; His is the dominion and His is the praise, and He is over all things competent. My Lord, I ask You for the good of this day and the good after it, and I seek refuge in You from the evil of this day and the evil after it. My Lord, I seek refuge in You from laziness and the misery of old age. My Lord, I seek refuge in You from punishment in the Fire and punishment in the grave.',
  1, 'Muslim 2723', 3),
(104, 1, 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
  'O Allah, You are my Lord; none has the right to be worshipped but You. You created me and I am Your servant, and I keep Your covenant and promise as best I can. I seek refuge in You from the evil of what I have done. I acknowledge Your favour upon me and I acknowledge my sin, so forgive me, for none forgives sins but You. (Sayyid al-Istighfar)',
  1, 'al-Bukhari 6306', 4),
(105, 1, 'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ',
  'O Allah, by You we enter the morning and by You we enter the evening, by You we live and by You we die, and to You is the resurrection.',
  1, 'al-Tirmidhi 3391', 5),
(106, 1, 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
  'In the name of Allah, with whose name nothing on earth or in the heavens can cause harm, and He is the All-Hearing, the All-Knowing.',
  3, 'Abu Dawud 5088; al-Tirmidhi 3388', 6),
(107, 1, 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا',
  'I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad ﷺ as my Prophet.',
  3, 'Abu Dawud 5072', 7),
(108, 1, 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
  'Glory be to Allah and praise be to Him.', 100, 'Muslim 2692', 8),
(109, 1, 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
  'None has the right to be worshipped but Allah alone, without partner; His is the dominion and His is the praise, and He is over all things competent.',
  100, 'al-Bukhari 3293; Muslim 2691', 9),
-- Evening
(201, 2, 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
  'Ayat al-Kursi (Al-Baqarah 2:255).', 1, 'Quran 2:255; al-Nasa''i, al-Sunan al-Kubra 10731', 1),
(202, 2, 'قُلْ هُوَ اللَّهُ أَحَدٌ ... ، قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ... ، قُلْ أَعُوذُ بِرَبِّ النَّاسِ ...',
  'Recite Surat al-Ikhlas, al-Falaq and an-Nas (the app shows the full surahs).', 3, 'Abu Dawud 5082; al-Tirmidhi 3575', 2),
(203, 2, 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ',
  'We have entered the evening and the dominion belongs to Allah. Praise be to Allah. None has the right to be worshipped but Allah alone, without partner; His is the dominion and His is the praise, and He is over all things competent. My Lord, I ask You for the good of this night and the good after it, and I seek refuge in You from the evil of this night and the evil after it. My Lord, I seek refuge in You from laziness and the misery of old age. My Lord, I seek refuge in You from punishment in the Fire and punishment in the grave.',
  1, 'Muslim 2723', 3),
(204, 2, 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
  'Sayyid al-Istighfar (see the morning adhkar for the meaning).', 1, 'al-Bukhari 6306', 4),
(205, 2, 'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ',
  'O Allah, by You we enter the evening and by You we enter the morning, by You we live and by You we die, and to You is the final return.',
  1, 'al-Tirmidhi 3391', 5),
(206, 2, 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
  'In the name of Allah, with whose name nothing on earth or in the heavens can cause harm, and He is the All-Hearing, the All-Knowing.',
  3, 'Abu Dawud 5088; al-Tirmidhi 3388', 6),
(207, 2, 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
  'I seek refuge in the perfect words of Allah from the evil of what He has created.', 3, 'Muslim 2709', 7),
(208, 2, 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
  'Glory be to Allah and praise be to Him.', 100, 'Muslim 2692', 8),
-- Sleep
(301, 3, 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
  'In Your name, O Allah, I die and I live.', 1, 'al-Bukhari 6324', 1),
(302, 3, 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
  'Ayat al-Kursi (Al-Baqarah 2:255).', 1, 'al-Bukhari 2311', 2),
(303, 3, 'قُلْ هُوَ اللَّهُ أَحَدٌ ... ، قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ... ، قُلْ أَعُوذُ بِرَبِّ النَّاسِ ...',
  'Cup the hands, blow lightly into them, recite al-Ikhlas, al-Falaq and an-Nas, then wipe over the body.', 3, 'al-Bukhari 5017', 3),
(304, 3, 'آمَنَ الرَّسُولُ بِمَا أُنْزِلَ إِلَيْهِ مِنْ رَبِّهِ وَالْمُؤْمِنُونَ ۚ كُلٌّ آمَنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِنْ رُسُلِهِ ۚ وَقَالُوا سَمِعْنَا وَأَطَعْنَا ۖ غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيرُ ۝ لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا ۚ لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ ۗ رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِينَا أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِنْ قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
  'The last two ayahs of Al-Baqarah (2:285-286).', 1, 'al-Bukhari 5009; Muslim 808', 4),
(305, 3, 'سُبْحَانَ اللَّهِ', 'Glory be to Allah.', 33, 'al-Bukhari 3705; Muslim 2727', 5),
(306, 3, 'الْحَمْدُ لِلَّهِ', 'Praise be to Allah.', 33, 'al-Bukhari 3705; Muslim 2727', 6),
(307, 3, 'اللَّهُ أَكْبَرُ', 'Allah is the Greatest.', 34, 'al-Bukhari 3705; Muslim 2727', 7),
(308, 3, 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ',
  'O Allah, protect me from Your punishment on the Day You resurrect Your servants.', 3, 'Abu Dawud 5045; al-Tirmidhi 3398', 8),
-- After prayer
(401, 4, 'أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ، اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
  'I seek Allah''s forgiveness (three times). O Allah, You are Peace and from You comes peace. Blessed are You, O Possessor of majesty and honour.', 1, 'Muslim 591', 1),
(402, 4, 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ',
  'None has the right to be worshipped but Allah alone, without partner; His is the dominion and His is the praise, and He is over all things competent. O Allah, none can withhold what You give, none can give what You withhold, and the wealth of the wealthy cannot avail him against You.',
  1, 'al-Bukhari 844; Muslim 593', 2),
(403, 4, 'سُبْحَانَ اللَّهِ', 'Glory be to Allah.', 33, 'Muslim 597', 3),
(404, 4, 'الْحَمْدُ لِلَّهِ', 'Praise be to Allah.', 33, 'Muslim 597', 4),
(405, 4, 'اللَّهُ أَكْبَرُ', 'Allah is the Greatest.', 33, 'Muslim 597', 5),
(406, 4, 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
  'Completing the hundred: none has the right to be worshipped but Allah alone, without partner; His is the dominion and His is the praise, and He is over all things competent.', 1, 'Muslim 597', 6),
(407, 4, 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
  'Ayat al-Kursi after each obligatory prayer.', 1, 'al-Nasa''i, al-Sunan al-Kubra 9928', 7),
-- Travel
(501, 5, 'اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ، وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ، اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَذَا الْبِرَّ وَالتَّقْوَى، وَمِنَ الْعَمَلِ مَا تَرْضَى، اللَّهُمَّ هَوِّنْ عَلَيْنَا سَفَرَنَا هَذَا وَاطْوِ عَنَّا بُعْدَهُ، اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ، وَالْخَلِيفَةُ فِي الْأَهْلِ، اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ وَعْثَاءِ السَّفَرِ، وَكَآبَةِ الْمَنْظَرِ، وَسُوءِ الْمُنْقَلَبِ فِي الْمَالِ وَالْأَهْلِ',
  'Allah is the Greatest (three times). Glory be to the One who has subjected this to us, and we could never have done it ourselves, and to our Lord we will surely return. O Allah, we ask You on this journey for righteousness and piety, and for deeds that please You. O Allah, make this journey easy for us and shorten its distance. O Allah, You are the Companion on the journey and the Guardian of the family. O Allah, I seek refuge in You from the hardship of travel, from sad sights, and from an ill return to wealth and family.',
  1, 'Muslim 1342', 1),
(502, 5, 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
  'On stopping at a place: I seek refuge in the perfect words of Allah from the evil of what He has created.', 1, 'Muslim 2708', 2),
(503, 5, 'آيِبُونَ تَائِبُونَ عَابِدُونَ لِرَبِّنَا حَامِدُونَ',
  'On returning: we return, repenting, worshipping, and praising our Lord.', 1, 'Muslim 1342', 3)
on conflict (id) do nothing;
