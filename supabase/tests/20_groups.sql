-- Family groups: membership, juz' division, preset calls, weekly board, push targets.
-- Run after stubs + migrations.
\set ON_ERROR_STOP 1
begin;

insert into auth.users (id, raw_user_meta_data) values
  ('00000000-0000-0000-0000-0000000000a1', '{"timezone":"UTC"}'),
  ('00000000-0000-0000-0000-0000000000a2', '{"timezone":"UTC"}'),
  ('00000000-0000-0000-0000-0000000000a3', '{"timezone":"UTC"}'),
  ('00000000-0000-0000-0000-0000000000a4', '{"timezone":"UTC"}');

-- name filter
do $$ begin
  assert public._community_text_check('العيلة', 40) = 'ok', 'normal arabic';
  assert public._community_text_check('Family', 40) = 'ok', 'normal english';
  assert public._community_text_check('الزبون', 40) = 'ok', 'short term does not match inside words';
  assert public._community_text_check('يا كَلْب', 40) = 'offensive', 'diacritics stripped';
  assert public._community_text_check('شرموطة', 40) = 'offensive', 'ta marbuta unified';
  assert public._community_text_check('050 123 4567', 40) = 'contact', 'phone';
  assert public._community_text_check('wa.me/123', 40) = 'contact', 'link';
  assert public._community_text_check(repeat('a', 41), 40) = 'too_long', 'too long';
end $$;

create temp table t_ctx (k text primary key, v text);
grant all on t_ctx to authenticated;

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

do $$ begin
  begin
    perform public.create_khatma_group('يا كلب', 'x');
    raise exception 'offensive name should be refused';
  exception when others then assert sqlerrm = 'community:offensive', sqlerrm;
  end;
end $$;

insert into t_ctx select 'group', r ->> 'id' from (select public.create_khatma_group('العيلة', 'أبو أحمد') r) s;
insert into t_ctx select 'code', invite_code from public.khatma_groups;

do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); begin
  assert (select count(*) from public.khatma_parts where group_id = g) = 30, '30 parts';
  assert (select role from public.khatma_members where group_id = g and user_id = auth.uid()) = 'owner', 'creator is owner';
  assert (select max_members from public.khatma_groups where id = g) = 20, 'family size';
end $$;

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a2';
do $$ begin perform public.join_khatma_group(lower((select v from t_ctx where k = 'code')), 'سارة'); end $$;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a3';
do $$ begin perform public.join_khatma_group((select v from t_ctx where k = 'code'), 'عمر'); end $$;

-- a non-member sees and does nothing
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a4';
do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); begin
  assert (select count(*) from public.khatma_groups) = 0, 'non-member sees no group';
  assert (select count(*) from public.khatma_members) = 0, 'non-member sees no members';
  begin
    perform public.get_group_board(g);
    raise exception 'board should be members-only';
  exception when others then assert sqlerrm = 'community:not_member', sqlerrm;
  end;
  begin
    perform public.send_group_call(g, 'salawat');
    raise exception 'calls should be members-only';
  exception when others then assert sqlerrm = 'community:not_member', sqlerrm;
  end;
  begin
    insert into public.group_calls (group_id, kind, expires_at) values (g, 'salawat', now() + interval '1 day');
    raise exception 'direct insert should be denied';
  exception when insufficient_privilege then null;
  end;
  begin
    perform count(*) from public.push_tokens;
    raise exception 'push tokens should be private';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public._group_call_push_targets(1, auth.uid());
    raise exception 'push targets are service-role only';
  exception when insufficient_privilege then null;
  end;
end $$;

-- push tokens
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a2';
do $$ begin perform public.register_push_token('token-sara-phone-1', 'android'); end $$;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a3';
do $$ begin perform public.register_push_token('token-omar-phone-1', 'ios'); end $$;

-- a khatma call with a reason and a dedication name
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';
do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); c bigint; begin
  perform public.register_push_token('token-abu-ahmad-1', 'ios');
  begin
    perform public.send_group_call(g, 'khatma', 'deceased', 'يا حمار');
    raise exception 'offensive dedication refused';
  exception when others then assert sqlerrm = 'community:offensive', sqlerrm;
  end;
  begin
    perform public.send_group_call(g, 'chat');
    raise exception 'unknown kind refused';
  exception when others then assert sqlerrm = 'community:invalid_call', sqlerrm;
  end;
  c := public.send_group_call(g, 'khatma', 'deceased', 'جدي أبو محمد');
  insert into t_ctx values ('khatma_call', c::text);
  assert (select round_reason from public.khatma_groups where id = g) = 'deceased', 'round has its intention';
  assert (select round_dedication from public.khatma_groups where id = g) = 'جدي أبو محمد', 'round dedication';
  begin
    perform public.send_group_call(g, 'khatma', 'general');
    raise exception 'same kind twice within 30 minutes';
  exception when others then assert sqlerrm = 'community:call_too_soon', sqlerrm;
  end;
  -- a general intention never keeps a name
  c := public.send_group_call(g, 'dua', 'general', 'someone');
  assert (select dedication from public.group_calls where id = c) is null, 'general has no name';
  c := public.send_group_call(g, 'salawat');
  insert into t_ctx values ('salawat_call', c::text);
  assert (select reason from public.group_calls where id = c) is null, 'salawat has no reason';
end $$;

-- push targets (service role): the sender only, once, never to the sender
reset role;
do $$ declare c bigint := (select v::bigint from t_ctx where k = 'salawat_call'); r jsonb; begin
  assert public._group_call_push_targets(c, '00000000-0000-0000-0000-0000000000a2') is null, 'only the sender may push';
  r := public._group_call_push_targets(c, '00000000-0000-0000-0000-0000000000a1');
  assert r ->> 'kind' = 'salawat', 'kind';
  assert r ->> 'sender_name' = 'أبو أحمد', 'sender name';
  assert jsonb_array_length(r -> 'targets') = 2, 'two other members: ' || (r -> 'targets')::text;
  assert not (r -> 'targets') @> '[{"token":"token-abu-ahmad-1"}]', 'not to the sender';
  assert public._group_call_push_targets(c, '00000000-0000-0000-0000-0000000000a1') is null, 'pushed once';
end $$;
set local role authenticated;

-- muting
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a3';
do $$ begin perform public.set_group_muted((select v::uuid from t_ctx where k = 'group'), true); end $$;
reset role;
do $$ declare c bigint := (select v::bigint from t_ctx where k = 'khatma_call'); r jsonb; begin
  r := public._group_call_push_targets(c, '00000000-0000-0000-0000-0000000000a1');
  assert jsonb_array_length(r -> 'targets') = 1, 'muted member skipped';
end $$;
set local role authenticated;

-- responding: counters add up, "done" counts once
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a2';
do $$ declare s bigint := (select v::bigint from t_ctx where k = 'salawat_call'); k bigint := (select v::bigint from t_ctx where k = 'khatma_call'); r jsonb; p jsonb; begin
  p := public.get_my_pending_calls();
  assert jsonb_array_length(p) = 3, 'three pending calls: ' || jsonb_array_length(p);
  assert p -> 0 ->> 'group_name' = 'العيلة', 'pending call carries the group name';
  r := public.respond_group_call(s, 100);
  r := public.respond_group_call(s, 5000);
  assert (r ->> 'mine')::int = 1100, 'capped at 1000 a tap: ' || r::text;
  r := public.respond_group_call(k);
  r := public.respond_group_call(k);
  assert (r ->> 'total')::int = 1 and (r ->> 'responders')::int = 1, 'done once';
  assert jsonb_array_length(public.get_my_pending_calls()) = 1, 'answered calls leave the list';
end $$;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a3';
do $$ declare s bigint := (select v::bigint from t_ctx where k = 'salawat_call'); r jsonb; begin
  r := public.respond_group_call(s, 33);
  assert (r ->> 'total')::int = 1133 and (r ->> 'responders')::int = 2, 'group counter';
  assert (select count(*) from public.get_group_calls((select v::uuid from t_ctx where k = 'group')) x) = 1, 'calls list';
  assert jsonb_array_length(public.get_group_calls((select v::uuid from t_ctx where k = 'group'))) = 3, 'three calls in the group';
end $$;

-- divide juz': owner distributes; a khatma can't be re-dedicated once reading started
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';
do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); n int; begin
  perform public.claim_khatma_juz(g, 1);
  n := public.distribute_khatma_juz(g);
  assert n = 29, 'distributed 29, got ' || n;
  assert (select count(*) from public.khatma_parts where group_id = g and assignee = '00000000-0000-0000-0000-0000000000a2') = 10, 'even split';
  perform public.complete_khatma_juz(g, 1);
end $$;
reset role;
update public.group_calls set created_at = created_at - interval '1 hour';
set local role authenticated;
do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); begin
  begin
    perform public.send_group_call(g, 'khatma', 'sick', 'خالتي');
    raise exception 'khatma in progress';
  exception when others then assert sqlerrm = 'community:khatma_in_progress', sqlerrm;
  end;
end $$;

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a2';
do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); j int; begin
  select juz into j from public.khatma_parts where group_id = g and assignee = '00000000-0000-0000-0000-0000000000a3' limit 1;
  begin
    perform public.complete_khatma_juz(g, j);
    raise exception 'cannot finish someone else''s juz';
  exception when others then assert sqlerrm = 'community:juz_taken', sqlerrm;
  end;
end $$;

-- everyone else finishes; the khatma completes, a khatma_done call is posted and the next round starts
reset role;
update public.khatma_parts set done_by = assignee, done_at = now()
where group_id = (select v::uuid from t_ctx where k = 'group') and round = 1 and juz not in (1, 30);
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a3';
do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); r jsonb; d bigint; begin
  r := public.complete_khatma_juz(g, 30);
  assert (r ->> 'khatma_completed')::boolean, 'khatma done: ' || r::text;
  d := (r ->> 'call_id')::bigint;
  assert (select kind from public.group_calls where id = d) = 'khatma_done', 'khatma_done posted';
  assert (select dedication from public.group_calls where id = d) = 'جدي أبو محمد', 'carries the dedication';
  assert (select round from public.khatma_groups where id = g) = 2, 'next round';
  assert (select round_reason from public.khatma_groups where id = g) is null, 'intention cleared';
  assert (select count(*) from public.khatma_parts where group_id = g and round = 2 and done_at is null) = 30, 'fresh 30';
  insert into t_ctx values ('done_call', d::text);
  begin
    perform public.respond_group_call(d);
    raise exception 'khatma_done is not answerable';
  exception when others then assert sqlerrm = 'community:invalid_call', sqlerrm;
  end;
end $$;
reset role;
do $$ declare d bigint := (select v::bigint from t_ctx where k = 'done_call'); r jsonb; begin
  assert public._group_call_push_targets(d, '00000000-0000-0000-0000-0000000000a4') is null, 'non-member cannot announce';
  r := public._group_call_push_targets(d, '00000000-0000-0000-0000-0000000000a3');
  assert jsonb_array_length(r -> 'targets') = 2, 'announced to the others (muted caller excluded anyway)';
end $$;

-- weekly board: XP this week ranks, last week's champion
insert into public.daily_activity (user_id, activity_date, ayahs_read, adhkar_completed, ayahs_memorized, reviews_done, xp_earned) values
  ('00000000-0000-0000-0000-0000000000a2', public._user_today('00000000-0000-0000-0000-0000000000a2'), 40, 2, 3, 5, 120),
  ('00000000-0000-0000-0000-0000000000a1', public._user_today('00000000-0000-0000-0000-0000000000a1'), 10, 1, 0, 0, 30),
  ('00000000-0000-0000-0000-0000000000a3', public._user_week_start('00000000-0000-0000-0000-0000000000a3') - 2, 99, 0, 0, 0, 500);
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';
do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); b jsonb; begin
  b := public.get_group_board(g);
  assert jsonb_array_length(b -> 'rows') = 3, 'all members';
  assert b -> 'rows' -> 0 ->> 'display_name' = 'سارة', 'top this week: ' || (b -> 'rows')::text;
  assert (b -> 'rows' -> 0 ->> 'hifz_week')::int = 8, 'hifz = memorized + reviews';
  assert (b -> 'rows' -> 0 ->> 'calls_week')::int = 2, 'answered calls';
  assert (b -> 'rows' -> 2 ->> 'xp_week')::int = 0, 'last week does not count this week';
  assert b -> 'last_week_champion' ->> 'display_name' = 'عمر', 'last week champion: ' || coalesce((b -> 'last_week_champion')::text, 'null');
  assert (b ->> 'resets_at') is not null, 'reset time';
end $$;

-- leaving / removing
do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); begin
  perform public.remove_khatma_member(g, '00000000-0000-0000-0000-0000000000a3', true);
  assert (select count(*) from public.khatma_members where group_id = g) = 2, 'removed';
end $$;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a3';
do $$ begin
  begin
    perform public.join_khatma_group((select v from t_ctx where k = 'code'), 'عمر');
    raise exception 'banned member cannot rejoin';
  exception when others then assert sqlerrm = 'community:invalid_code', sqlerrm;
  end;
end $$;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';
do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); begin
  perform public.leave_khatma_group(g);
end $$;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a2';
do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); begin
  assert (select role from public.khatma_members where group_id = g and user_id = auth.uid()) = 'owner', 'ownership passed on';
  perform public.leave_khatma_group(g);
end $$;
reset role;
do $$ begin
  assert (select count(*) from public.khatma_groups) = 0, 'empty group deleted';
end $$;

rollback;
\echo 'GROUP TESTS PASSED'
