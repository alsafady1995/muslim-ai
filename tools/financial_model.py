"""Asmi3ni scenario model (docs/strategy/financial-viability.md).

Run:  python3 tools/financial_model.py            -> prints markdown tables
      python3 tools/financial_model.py --csv FILE -> also writes the CSV

Every number below is an assumption you can change. "users" means monthly active
users (MAU), not downloads. All money is USD per year unless the name says monthly.
Sources and reasoning for each value are in the doc, section "Assumptions".
"""
import csv
import sys

# ---------- Prices and what the developer actually receives ----------
STORE_FEE = 0.15              # Apple Small Business Program / Google subscriptions
VAT_DEFAULT = 0.13            # blended VAT in default storefronts (KSA 15%, UAE 5%, JO 16%...) - inference
VAT_LOW = 0.14                # Egypt-like markets - inference
REVENUECAT_FEE = 0.01         # of gross revenue above $2.5k MTR (we apply it to all gross, conservative)

PRICE = {                     # store list prices (BLOCKERS.md, decided)
    "default": {"annual": 29.99, "monthly": 4.99},
    "low":     {"annual": 6.99,  "monthly": 0.99},
}
ANNUAL_SHARE = 0.60                  # share of active payers on annual (MEA monthly share is ~52-55% per RevenueCat; trial on annual pushes it up)

# Two cases. "conservative" is the one the brief asked for; "plan works" shows what has to be true to be a business.
CASES = {
    "conservative": {
        "paying_share": 0.02,          # RevenueCat 2026: freemium D35 download-to-paid median 2.1%
        "default_market_payers": 0.55, # share of payers in $29.99 storefronts (rest: Egypt/Pakistan/Indonesia tier)
        "ai_free_mau_month": 0.01,     # Haiku asks + ASR minutes for an average free MAU; hard cap is $0.15
    },
    "plan works": {
        "paying_share": 0.04,          # teacher-led acquisition + family plan; needs proof
        "default_market_payers": 0.75, # Gulf-first launch
        "ai_free_mau_month": 0.01,
    },
}


def net(price, vat):
    return price / (1 + vat) * (1 - STORE_FEE)


def blended_net_per_payer_year(case):
    d = case["default_market_payers"]
    lo = 1 - d
    annual = d * net(PRICE["default"]["annual"], VAT_DEFAULT) + lo * net(PRICE["low"]["annual"], VAT_LOW)
    monthly12 = 12 * (d * net(PRICE["default"]["monthly"], VAT_DEFAULT) + lo * net(PRICE["low"]["monthly"], VAT_LOW))
    gross_annual = d * PRICE["default"]["annual"] + lo * PRICE["low"]["annual"]
    gross_monthly12 = 12 * (d * PRICE["default"]["monthly"] + lo * PRICE["low"]["monthly"])
    net_year = ANNUAL_SHARE * annual + (1 - ANNUAL_SHARE) * monthly12
    gross_year = ANNUAL_SHARE * gross_annual + (1 - ANNUAL_SHARE) * gross_monthly12
    return net_year, gross_year


# ---------- Behaviour ----------
TIP_SHARE_OF_MAU = 0.004       # users who leave a one-time tip in a year - inference
TIP_AVG_GROSS = 6.0
SUPPORTER_SHARE_OF_MAU = 0.001 # monthly "supporter" tip subscribers - inference
SUPPORTER_MONTHLY = 2.99
SPONSOR_SHARE_OF_MAU = 0.001   # users who gift a year of Premium to a student - inference
SPONSOR_PRICE = 29.99

# ---------- Costs ----------
AI_PER_PAYER_MONTH = 0.35      # Sonnet asks + ASR; hard-capped at 50% of net by the server
FIXED_TOOLS_YEAR = 99 + 15 + 25  # Apple program, domain, Google one-off spread over year 1 - Google fee is one-time


def infra_month(mau):
    """Supabase + ASR + analytics, from published Supabase prices (Nov 2026) and inference for the rest."""
    supabase = 25.0
    compute = 0 if mau <= 5_000 else 5 if mau <= 30_000 else 50 if mau <= 200_000 else 400 + 410  # Small/Medium/XL + replica (XL, replica: inference)
    mau_over = max(0, mau - 100_000) * 0.00325
    egress_gb = mau * 0.02           # 20 MB per MAU per month once Quran text ships offline - inference
    egress = max(0, egress_gb - 250) * 0.09
    fn_calls = mau * 60              # edge function calls per MAU per month - inference
    fn = max(0, fn_calls - 2_000_000) / 1_000_000 * 2
    asr_floor = 5 if mau < 50_000 else 30      # Cloud Run idle + cold starts; per-minute cost sits in AI lines
    analytics = 0 if mau <= 20_000 else 200 if mau <= 200_000 else 1_000  # PostHog/Sentry beyond free tiers - inference
    return supabase + compute + mau_over + egress + fn + asr_floor + analytics


def people_year(mau):
    """Paid help besides the founder (support, moderation, part-time dev). Jordan rates - inference."""
    if mau <= 10_000:
        return 0
    if mau <= 100_000:
        return 12 * 1_000          # part-time support/moderation
    if mau <= 300_000:
        return 12 * 3_000          # + part-time developer
    if mau <= 1_000_000:
        return 12 * 10_000         # ~3 people: engineer, support/moderation lead, teacher/community ops
    return 12 * 18_000             # ~5 people


FOUNDER_PAY_YEAR = 12 * 2_500      # modest founder salary in Amman/Riyadh terms - inference


def scenario(mau, case):
    net_payer, gross_payer = blended_net_per_payer_year(case)
    payers = mau * case["paying_share"]
    subs_net = payers * net_payer
    subs_gross = payers * gross_payer

    tip_net = mau * TIP_SHARE_OF_MAU * net(TIP_AVG_GROSS, VAT_DEFAULT)
    supporter_net = mau * SUPPORTER_SHARE_OF_MAU * 12 * net(SUPPORTER_MONTHLY, VAT_DEFAULT)
    sponsor_net = mau * SPONSOR_SHARE_OF_MAU * net(SPONSOR_PRICE, VAT_DEFAULT)
    support_gross = mau * (TIP_SHARE_OF_MAU * TIP_AVG_GROSS + SUPPORTER_SHARE_OF_MAU * 12 * SUPPORTER_MONTHLY
                           + SPONSOR_SHARE_OF_MAU * SPONSOR_PRICE)
    support_net = tip_net + supporter_net + sponsor_net

    revenue = subs_net + support_net
    rc = REVENUECAT_FEE * (subs_gross + support_gross) if (subs_gross + support_gross) / 12 > 2_500 else 0

    sponsored_seats = mau * SPONSOR_SHARE_OF_MAU
    ai = 12 * (AI_PER_PAYER_MONTH * (payers + sponsored_seats) + case["ai_free_mau_month"] * (mau - payers - sponsored_seats))
    infra = 12 * infra_month(mau)
    tools = FIXED_TOOLS_YEAR
    people = people_year(mau)
    op_cost = rc + ai + infra + tools + people
    before_founder = revenue - op_cost
    after_founder = before_founder - FOUNDER_PAY_YEAR
    return {
        "MAU": mau,
        "Paying subscribers": round(payers),
        "Subscription revenue (net)": round(subs_net),
        "Tips + supporters + sponsor-a-student (net)": round(support_net),
        "Total net revenue": round(revenue),
        "AI (Claude + ASR + embeddings)": round(ai),
        "Infrastructure (Supabase, ASR floor, analytics)": round(infra),
        "RevenueCat": round(rc),
        "Store accounts + domain": round(tools),
        "Paid help (not founder)": round(people),
        "Total operating cost": round(op_cost),
        "Profit before founder pay": round(before_founder),
        "Profit after founder pay ($30k/yr)": round(after_founder),
    }


def breakeven_mau(target, case):
    """First MAU (in steps of 1,000, up to 3M) where profit before founder pay reaches target. Costs step up with
    team size, so profit is not monotonic; None means never in range."""
    for mau in range(1_000, 3_000_001, 1_000):
        if scenario(mau, case)["Profit before founder pay"] >= target:
            return mau
    return None


def main():
    out = []
    for name, case in CASES.items():
        rows = [scenario(m, case) for m in (1_000, 10_000, 100_000, 1_000_000)]
        keys = list(rows[0].keys())
        net_payer, gross_payer = blended_net_per_payer_year(case)
        print(f"\n### Case: {name}\n")
        print(f"Blended net per paying subscriber per year: ${net_payer:.2f} (gross ${gross_payer:.2f}); "
              f"net per $29.99 annual in a default storefront: ${net(29.99, VAT_DEFAULT):.2f}\n")
        print("| Line (USD per year) | " + " | ".join(f"{r['MAU']:,} MAU" for r in rows) + " |")
        print("|---|" + "---:|" * len(rows))
        for k in keys[1:]:
            print(f"| {k} | " + " | ".join(f"{r[k]:,}" for r in rows) + " |")
        be0, be1 = breakeven_mau(0, case), breakeven_mau(FOUNDER_PAY_YEAR, case)
        fmt = lambda v: f"~{v:,} MAU" if v else "not reached below 3M MAU"
        print(f"\nFirst break-even before founder pay: {fmt(be0)}. Founder paid $30k/yr: {fmt(be1)}.")
        for k in keys[1:]:
            out.append([name, k] + [r[k] for r in rows])
    if "--csv" in sys.argv:
        path = sys.argv[sys.argv.index("--csv") + 1]
        with open(path, "w", newline="") as f:
            w = csv.writer(f)
            w.writerow(["Case", "Line (USD per year)", "1000 MAU", "10000 MAU", "100000 MAU", "1000000 MAU"])
            w.writerows(out)


if __name__ == "__main__":
    main()
