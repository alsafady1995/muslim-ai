# Store setup: ready to apply

Decided on 24 November 2026. Apply these as soon as Apple and Google approve the developer accounts. Nothing here
needs an app release: the app reads products, prices and trials from the store through RevenueCat.

Product IDs (already used by the code): `muslimai_premium_annual`, `muslimai_premium_monthly`.
RevenueCat entitlement: `premium`. Offering: `default`, with `$rc_annual` listed first.

## 0. App name and store listing

The app is called **Asmi3ni / أسمِعني** ("let me hear you", what a hifz teacher says to a student before the
student recites). Two apps named "Muslim AI" already exist on the App Store, so the store name changed.
Bundle and package IDs stay `app.muslimai.mobile`; product IDs stay as below. Users never see these.

| Field | English | Arabic |
|---|---|---|
| App name (30 chars max) | Asmi3ni: AI Quran Coach | أسمِعني: مدرّب حفظ القرآن |
| Home-screen name | Asmi3ni | Asmi3ni (an Arabic home-screen name needs localized `InfoPlist.strings` / `values-ar`, not done yet) |
| Tagline | Recite. It listens. | سمّع حفظك، وهو يصحّح لك |

`asmi3ni.com` was registered on 24 November 2026 (Cloudflare Registrar). The static site in `site/` is published there by
Cloudflare Pages (project connected to this repo, build output `site`, no build command): privacy `https://asmi3ni.com/privacy/`, terms `https://asmi3ni.com/terms/`,
account deletion `https://asmi3ni.com/delete-account/` (use this for Google Play's data-deletion URL). The app
defaults `PRIVACY_URL` and `TERMS_URL` to these.

## 1. Products, prices and the annual-only trial

| Product | Base price (USD storefront) | Free trial | Egypt, Pakistan, Indonesia |
|---|---|---|---|
| `muslimai_premium_annual` | **$29.99 / year** (≈ SAR 109.99) | **7 days**, new subscribers only | ≈ $6.99 in local currency |
| `muslimai_premium_monthly` | **$4.99 / month** (≈ SAR 18.99) | **None** | ≈ $0.99 in local currency |

**App Store Connect**
1. Apps → Asmi3ni → Monetization → Subscriptions → create group **Premium**.
2. Create `muslimai_premium_annual` (duration 1 year) and `muslimai_premium_monthly` (1 month), both in the same group
   so users can switch between them. The annual plan's group level should be 1 (top).
3. Each product → Subscription Prices → set the USD price above; Apple fills the other storefronts. Then edit
   Egypt, Pakistan and Indonesia to the regional tiers.
4. Annual only → Introductory Offers → Free → 1 week → all territories. **Do not add an introductory offer to the
   monthly product.**
5. Each product needs a display name, description and a review screenshot of the paywall before it can be submitted
   with the first build.

**Google Play Console**
1. Monetize → Products → Subscriptions → create `muslimai_premium_annual` with base plan `annual` (auto-renewing,
   1 year) and `muslimai_premium_monthly` with base plan `monthly` (auto-renewing, 1 month).
2. Base plan → Set prices → USD price above → update other countries from the converted prices, then edit Egypt,
   Pakistan and Indonesia.
3. `annual` base plan only → Add offer → offer ID `trial-7d` → eligibility "New customer acquisition" (never had
   this subscription) → phase: Free trial, 7 days. **No offer on `monthly`.**
4. Activate both base plans and the offer.

**RevenueCat**
1. Products → import both products from each store.
2. Entitlements → `premium` → attach all four (2 per store).
3. Offerings → `default` → packages `$rc_annual` (first) and `$rc_monthly`. Make `default` the current offering.

## 2. Billing grace period and account hold

Failed renewals cause a large share of churn. The app already shows an "update your payment" card when the store
reports a billing problem (`billing_issue` / `grace_period` from the RevenueCat webhook), and Premium stays on
during grace.

**App Store Connect:** Apps → Asmi3ni → Monetization → Subscriptions → Billing Grace Period → turn on →
**16 days** → eligible subscribers: all renewals → both production and sandbox.

**Google Play Console:** each base plan → Grace period **7 days** → Account hold **30 days** (the remaining
recovery window). Also turn on "Resubscribe" so users can restart from the Play Store.

**RevenueCat:** no change needed; it sends `BILLING_ISSUE` and keeps the entitlement during grace.

## 3. Win-back offers (after launch)

Only useful once there are lapsed subscribers, so set these up about 2 months after launch.

**App Store Connect:** Subscriptions → `muslimai_premium_annual` → Win-Back Offers → create:
- Offer: pay up front, 1 year at **$14.99** (50% off).
- Eligibility: paid for at least 1 month, lapsed between 1 and 12 months ago; wait 2 weeks between offers.
- Display: let Apple show it in the App Store.

**Google Play Console:** `annual` base plan → Add offer → ID `winback-50` → eligibility "Developer determined" →
phase: single payment of $14.99 for the first year. RevenueCat can target it with an offer tag `winback` for users
whose subscription expired; the paywall shows whatever the offering returns.

## 4. Check after setup

1. Install a TestFlight / internal testing build and open the paywall: annual is pre-selected, shows "7-day free
   trial" and the trial timeline; monthly shows no trial.
2. Buy the annual plan in sandbox → Home shows the trial end date → a notification is scheduled 2 days before it.
3. In Supabase: `select status, period_type, net_revenue_usd from subscriptions order by updated_at desc limit 5;`
   should show the sandbox purchase with `period_type = 'trial'`.

## Sign-in setup (done 24 Nov 2026)

- **Google Cloud project** `Asmi3ni` (id `fleet-source-515713-j2`), OAuth consent screen *In production*, external, links to asmi3ni.com.
  - Web client (used by Supabase and `GOOGLE_WEB_CLIENT_ID`): `163661467299-3qssu423853vuir4cddnlnk6h8pm9r8s.apps.googleusercontent.com`
  - iOS client (`GOOGLE_IOS_CLIENT_ID`, bundle `app.muslimai.mobile`): `163661467299-g5q51lluisb4to8uj2hln4st2u1fp5c0.apps.googleusercontent.com`
  - Still to do: Android client with the Play app-signing and upload-key SHA-1 (after the app exists in Play Console); add its id to Supabase Google "Client IDs".
- **Supabase Auth**: anonymous sign-ins and manual linking on (the onboarding needs them); Apple on with Client IDs `app.muslimai.mobile` (add the Services ID later if web sign-in is wanted); Google on with the web and iOS client ids, nonce check skipped (iOS).
- **GitHub secret `APP_ENV_PROD_JSON`** created with the Supabase URL + publishable key, Google ids, legal URLs. RevenueCat public keys, PostHog key and Sentry DSN are empty: replace the whole secret once those exist (the secret cannot be read back, so paste the full JSON from `app/env/example.json` with real values).
