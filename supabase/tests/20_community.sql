-- Khatma groups, messages, filter, report / block / remove. Run after stubs + migrations.
\set ON_ERROR_STOP 1
begin;

insert into auth.users (id, raw_user_meta_data) values
  ('00000000-0000-0000-0000-0000000000a1', '{"timezone":"UTC"}'),
  ('00000000-0000-0000-0000-0000000000a2', '{"timezone":"UTC"}'),
  ('00000000-0000-0000-0000-0000000000a3', '{"timezone":"UTC"}'),
  ('00000000-0000-0000-0000-0000000000a4', '{"timezone":"UTC"}');

-- filter
do $$ begin
  assert public._community_text_check('بارك الله فيكم، أكملت الجزء الخامس', 500) = 'ok', 'normal arabic';
  assert public._community_text_check('Great job everyone, keep going!', 500) = 'ok', 'normal english';
  assert public._community_text_check('قرأت سورة الكهف: وكلبهم باسط ذراعيه', 500) = 'ok', 'quran quote with كلب';
  assert public._community_text_check('يلعنهم الله ويلعنهم اللاعنون', 500) = 'ok', 'quran quote with يلعن';
  assert public._community_text_check('الزبون', 500) = 'ok', 'short term does not match inside words';
  assert public._community_text_check('انت يا كَلْب', 500) = 'offensive', 'diacritics stripped';
  assert public._community_text_check('يا حمـــار', 500) = 'offensive', 'tatweel stripped';
  assert public._community_text_check('شرموطة', 500) = 'offensive', 'ta marbuta unified';
  assert public._community_text_check('you are a FUUUCKING idiot', 500) = 'offensive', 'repeats squashed + suffix';
  assert public._community_text_check('sh.i.t', 500) = 'ok', 'dotted letters split (accepted miss)';
  assert public._community_text_check('call me 050 123 4567', 500) = 'contact', 'phone';
  assert public._community_text_check('رقمي ٠٥٠١٢٣٤٥٦٧', 500) = 'contact', 'arabic digits phone';
  assert public._community_text_check('see https://x.co', 500) = 'contact', 'link';
  assert public._community_text_check('add me @someone', 500) = 'contact', 'handle';
  assert public._community_text_check('اكملت الاجزاء 1, 2, 3 و 4', 500) = 'ok', 'juz numbers are fine';
  assert public._community_text_check('   ', 500) = 'empty', 'empty';
  assert public._community_text_check(repeat('a', 501), 500) = 'too_long', 'too long';
end $$;

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

-- terms required
do $$ begin
  begin
    perform public.create_khatma_group('ختمة العائلة', 'أبو أحمد');
    raise exception 'terms should be required';
  exception when others then
    assert sqlerrm = 'community:terms', sqlerrm;
  end;
end $$;
do $$ begin perform public.accept_community_terms(); end $$;

-- offensive group name refused
do $$ begin
  begin
    perform public.create_khatma_group('يا كلب', 'x');
    raise exception 'offensive name should be refused';
  exception when others then
    assert sqlerrm = 'community:offensive', sqlerrm;
  end;
end $$;

create temp table t_ctx (k text primary key, v text);
grant all on t_ctx to authenticated;
insert into t_ctx select 'group', r ->> 'id' from (select public.create_khatma_group('ختمة العائلة', 'أبو أحمد') r) s;
insert into t_ctx select 'code', invite_code from public.khatma_groups;

do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); begin
  assert (select count(*) from public.khatma_parts where group_id = g) = 30, '30 parts';
  assert (select role from public.khatma_members where group_id = g and user_id = auth.uid()) = 'owner', 'creator is owner';
end $$;

-- members join
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a2';
do $$ begin perform public.accept_community_terms(); end $$;
do $$ begin perform public.join_khatma_group(lower((select v from t_ctx where k = 'code')), 'Sara'); end $$;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a3';
do $$ begin perform public.accept_community_terms(); end $$;
do $$ begin perform public.join_khatma_group((select v from t_ctx where k = 'code'), 'Omar'); end $$;

-- a non-member sees nothing
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a4';
do $$ begin
  assert (select count(*) from public.khatma_groups) = 0, 'non-member sees no group';
  assert (select count(*) from public.khatma_members) = 0, 'non-member sees no members';
  assert (select count(*) from public.khatma_messages) = 0, 'non-member sees no messages';
  begin
    perform public.get_khatma_leaderboard((select v::uuid from t_ctx where k = 'group'));
    raise exception 'leaderboard should be members-only';
  exception when others then assert sqlerrm = 'community:not_member', sqlerrm;
  end;
  begin
    insert into public.khatma_messages (group_id, user_id, body) values ((select v::uuid from t_ctx where k = 'group'), auth.uid(), 'x');
    raise exception 'direct insert should be denied';
  exception when insufficient_privilege then null;
  end;
end $$;

-- divide juz': owner distributes, members claim / finish
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';
do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); n int; begin
  assert (select count(*) from public.khatma_members) = 3, 'member sees all members';
  perform public.claim_khatma_juz(g, 1);
  n := public.distribute_khatma_juz(g);
  assert n = 29, 'distributed 29, got ' || n;
  assert (select count(*) from public.khatma_parts where group_id = g and round = 1 and assignee is null) = 0, 'all assigned';
  assert (select count(*) from public.khatma_parts where group_id = g and assignee = '00000000-0000-0000-0000-0000000000a2') = 10, 'even split';
end $$;

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a2';
do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); j int; r jsonb; begin
  select juz into j from public.khatma_parts where group_id = g and assignee = '00000000-0000-0000-0000-0000000000a3' limit 1;
  begin
    perform public.complete_khatma_juz(g, j);
    raise exception 'cannot finish someone else''s juz';
  exception when others then assert sqlerrm = 'community:juz_taken', sqlerrm;
  end;
  select juz into j from public.khatma_parts where group_id = g and assignee = auth.uid() limit 1;
  r := public.complete_khatma_juz(g, j);
  assert not (r ->> 'khatma_completed')::boolean, 'not done yet';
  perform public.uncomplete_khatma_juz(g, j);
  r := public.complete_khatma_juz(g, j);
end $$;

-- the rest finish; the khatma completes and the next round starts
reset role;
update public.khatma_parts set done_by = assignee, done_at = now()
where group_id = (select v::uuid from t_ctx where k = 'group') and done_at is null and juz <> 30;
set local role authenticated;
do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); r jsonb; who uuid; begin
  select assignee into who from public.khatma_parts where group_id = g and round = 1 and juz = 30;
  perform set_config('request.jwt.claim.sub', who::text, true);
  r := public.complete_khatma_juz(g, 30);
  assert (r ->> 'khatma_completed')::boolean, 'khatma complete ' || r::text;
  assert (select round from public.khatma_groups where id = g) = 2, 'next round';
  assert (select khatmas_completed from public.khatma_groups where id = g) = 1, 'counted';
  assert (select count(*) from public.khatma_parts where group_id = g and round = 2 and assignee is null) = 30, 'fresh round';
  assert exists (select 1 from public.khatma_messages where group_id = g and kind = 'system' and body = 'khatma_done'), 'celebration';
  assert jsonb_array_length(public.get_khatma_leaderboard(g)) = 3, 'leaderboard rows';
  assert (public.get_khatma_leaderboard(g) -> 0 ->> 'juz_total')::int >= 10, 'leaderboard counts';
end $$;

-- messages, cheers, filter, rate limit
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a3';
do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); begin
  perform public.post_khatma_message(g, 'ما شاء الله، ختمة مباركة');
  perform public.send_khatma_cheer(g, 'barakallah', '00000000-0000-0000-0000-0000000000a2');
  begin
    perform public.post_khatma_message(g, 'يا حمار');
    raise exception 'offensive message should be refused';
  exception when others then assert sqlerrm = 'community:offensive', sqlerrm;
  end;
  begin
    perform public.send_khatma_cheer(g, 'free text');
    raise exception 'unknown cheer';
  exception when others then assert sqlerrm = 'community:invalid_cheer', sqlerrm;
  end;
  perform public.post_khatma_message(g, 'رسالة ' || i) from generate_series(1, 4) i;
  begin
    perform public.post_khatma_message(g, 'رسالة أخرى');
    raise exception 'rate limit';
  exception when others then assert sqlerrm = 'community:slow_down', sqlerrm;
  end;
end $$;

-- report: reporter stops seeing it; a second report hides it for everyone
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a2';
do $$ declare m bigint; before int; begin
  select id into m from public.khatma_messages where body = 'رسالة 1';
  perform public.report_content('spam', m);
  assert not exists (select 1 from public.khatma_messages where id = m), 'reporter no longer sees it';
  begin
    perform count(*) from public.content_reports;
    raise exception 'reports should not be readable by clients';
  exception when insufficient_privilege then null;
  end;
end $$;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';
do $$ declare m bigint; begin
  select id into m from public.khatma_messages where body = 'رسالة 1';
  assert m is not null, 'others still see it after one report';
  perform public.report_content('spam', m);
end $$;
reset role;
do $$ begin
  assert (select hidden_reason from public.khatma_messages where body = 'رسالة 1') = 'reports', 'hidden after 2 reports';
end $$;
set local role authenticated;

-- block: blocked user's messages disappear for the blocker only
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a2';
do $$ begin
  perform public.block_user('00000000-0000-0000-0000-0000000000a3');
  assert not exists (select 1 from public.khatma_messages where user_id = '00000000-0000-0000-0000-0000000000a3'), 'blocked hidden';
  assert jsonb_array_length(public.get_my_blocks()) = 1, 'block listed';
  begin
    perform public.block_user('00000000-0000-0000-0000-0000000000a4');
    raise exception 'can only block people in a shared group';
  exception when others then assert sqlerrm = 'community:not_found', sqlerrm;
  end;
end $$;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';
do $$ begin
  assert exists (select 1 from public.khatma_messages where user_id = '00000000-0000-0000-0000-0000000000a3'), 'others still see';
end $$;

-- owner deletes a message and removes + bans a member
do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); m bigint; begin
  select id into m from public.khatma_messages where body = 'رسالة 2';
  perform public.delete_khatma_message(m);
  assert not exists (select 1 from public.khatma_messages where id = m), 'owner deleted';
  perform public.claim_khatma_juz(g, 5);
  perform public.assign_khatma_juz(g, 6, '00000000-0000-0000-0000-0000000000a3');
  perform public.remove_khatma_member(g, '00000000-0000-0000-0000-0000000000a3', true);
  assert (select count(*) from public.khatma_members) = 2, 'removed';
  assert (select assignee from public.khatma_parts where group_id = g and round = 2 and juz = 6) is null, 'their juz released';
end $$;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a3';
do $$ begin
  begin
    perform public.join_khatma_group((select v from t_ctx where k = 'code'), 'Omar');
    raise exception 'banned member cannot rejoin';
  exception when others then assert sqlerrm = 'community:invalid_code', sqlerrm;
  end;
end $$;

-- a non-owner cannot moderate
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a2';
do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); begin
  begin
    perform public.remove_khatma_member(g, '00000000-0000-0000-0000-0000000000a1');
    raise exception 'members cannot remove';
  exception when others then assert sqlerrm = 'community:not_owner', sqlerrm;
  end;
end $$;

-- owner leaves: ownership passes on; last member leaves: group is deleted
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';
do $$ begin perform public.leave_khatma_group((select v::uuid from t_ctx where k = 'group')); end $$;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a2';
do $$ declare g uuid := (select v::uuid from t_ctx where k = 'group'); begin
  assert (select role from public.khatma_members where group_id = g and user_id = auth.uid()) = 'owner', 'ownership transferred';
  assert jsonb_array_length(public.get_my_khatma_groups()) = 1, 'my groups';
  perform public.leave_khatma_group(g);
end $$;
reset role;
do $$ begin
  assert not exists (select 1 from public.khatma_groups), 'empty group deleted';
end $$;

-- moderator ban stops posting everywhere
do $$ declare r bigint; begin
  insert into public.content_reports (reporter_id, reported_user_id, reason) values
    ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000a3', 'harassment') returning id into r;
  perform public.moderate_report(r, 'ban_user');
  assert (select community_banned_at from public.profiles where id = '00000000-0000-0000-0000-0000000000a3') is not null, 'banned';
  assert (select status from public.content_reports where id = r) = 'actioned', 'actioned';
end $$;
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a3';
do $$ begin
  begin
    perform public.create_khatma_group('مجموعة', 'Omar');
    raise exception 'banned user cannot create';
  exception when others then assert sqlerrm = 'community:banned', sqlerrm;
  end;
  begin
    perform public.moderate_report(1, 'dismiss');
    raise exception 'clients cannot moderate';
  exception when insufficient_privilege then null;
  end;
end $$;

rollback;
\echo 'COMMUNITY TESTS PASSED'
