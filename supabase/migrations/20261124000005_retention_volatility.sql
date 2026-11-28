-- hifz_retention() reads now(), so it is not IMMUTABLE. Declared immutable, the planner may
-- pre-compute it once for constant arguments (and plpgsql can cache that in a saved plan),
-- returning a stale recall prediction. STABLE is the correct volatility; behaviour is unchanged.
alter function public.hifz_retention(int, timestamptz) stable;
