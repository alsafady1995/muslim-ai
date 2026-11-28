// Notification text for family-group calls. Every call is a preset, so the server renders it in
// each member's language; the only user text is the sender's name in the group, the group name and
// an optional short dedication name, all filtered in Postgres.

export type CallKind =
  | "khatma"
  | "salawat"
  | "istighfar"
  | "adhkar_morning"
  | "adhkar_evening"
  | "dua"
  | "khatma_done";

export interface CallPush {
  kind: CallKind;
  reason: string | null;
  dedication: string | null;
  sender_name: string | null;
  group_name: string;
}

type Lang = "ar" | "en";

const REASON: Record<Lang, Record<string, (name: string | null) => string>> = {
  ar: {
    general: () => "بنية عامة",
    deceased: (n) => n ? `لروح ${n}` : "لروح من فقدنا",
    sick: (n) => n ? `لشفاء ${n}` : "لشفاء مرضانا",
    exam: (n) => n ? `بالتوفيق لـ${n}` : "بالتوفيق في الامتحانات",
    travel: (n) => n ? `بالسلامة لـ${n}` : "بالسلامة للمسافرين",
    newborn: (n) => n ? `بالبركة في المولود ${n}` : "بالبركة في المولود",
    hardship: (n) => n ? `لتفريج كرب ${n}` : "لتفريج الكرب",
    rizq: (n) => n ? `بالرزق لـ${n}` : "بسعة الرزق",
  },
  en: {
    general: () => "with a general intention",
    deceased: (n) => n ? `for the soul of ${n}` : "for those we have lost",
    sick: (n) => n ? `for ${n}'s recovery` : "for the sick",
    exam: (n) => n ? `for ${n}'s success` : "for success in exams",
    travel: (n) => n ? `for ${n}'s safe travel` : "for safe travels",
    newborn: (n) => n ? `for blessings on baby ${n}` : "for blessings on the newborn",
    hardship: (n) => n ? `to ease ${n}'s hardship` : "to ease hardship",
    rizq: (n) => n ? `for ${n}'s provision` : "for provision",
  },
};

export function langFor(locale: string | null | undefined): Lang {
  return locale === "ar" ? "ar" : locale ? "en" : "ar";
}

export function reasonText(lang: Lang, reason: string | null, dedication: string | null): string {
  const f = REASON[lang][reason ?? "general"] ?? REASON[lang].general;
  return f(dedication?.trim() || null);
}

/** Title and body of the push for one member's language. */
export function callNotification(
  c: CallPush,
  locale: string | null | undefined,
): { title: string; body: string } {
  const lang = langFor(locale);
  const who = c.sender_name?.trim() || (lang === "ar" ? "أحد أفراد المجموعة" : "Someone in your group");
  const title = c.group_name;
  const reason = reasonText(lang, c.reason, c.dedication);
  if (lang === "ar") {
    switch (c.kind) {
      case "khatma":
        return { title, body: `${who}: يلا نختم ختمة ${reason} 📖 احجز جزءك` };
      case "salawat":
        return { title, body: `${who}: صلّوا على النبي ﷺ` };
      case "istighfar":
        return { title, body: `${who}: يلا نستغفر الله سوا` };
      case "adhkar_morning":
        return { title, body: `${who}: لا تنسوا أذكار الصباح ☀️` };
      case "adhkar_evening":
        return { title, body: `${who}: لا تنسوا أذكار المساء 🌙` };
      case "dua":
        return { title, body: `${who}: ادعوا ${reason} 🤲` };
      case "khatma_done":
        return { title, body: `تمّت الختمة ${reason}. تقبّل الله منكم 🤍` };
    }
  }
  switch (c.kind) {
    case "khatma":
      return { title, body: `${who}: let's complete a khatma ${reason} 📖 Pick your juz'` };
    case "salawat":
      return { title, body: `${who}: send salawat on the Prophet ﷺ` };
    case "istighfar":
      return { title, body: `${who}: let's say istighfar together` };
    case "adhkar_morning":
      return { title, body: `${who}: don't forget your morning adhkar ☀️` };
    case "adhkar_evening":
      return { title, body: `${who}: don't forget your evening adhkar 🌙` };
    case "dua":
      return { title, body: `${who}: please make dua ${reason} 🤲` };
    case "khatma_done":
      return { title, body: `The khatma ${reason} is complete. May Allah accept it 🤍` };
  }
  return { title, body: "" };
}
