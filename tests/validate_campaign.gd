# 3세대 캠페인 헤드리스 검증 — 완주/지속성/인과/감정/랭크 경로/딜레마 다양성/결정성/배치를 검사한다.
# 실행: godot --headless --path . --script res://tests/validate_campaign.gd
extends SceneTree

var failures: Array = []
var checks: int = 0

const PROFILES := ["steward", "ambitious", "harmony", "reckless", "phoenix", "random"]
const BATCH_SEEDS_PER_PROFILE := 25
const MAX_STEPS := 6000

func _initialize() -> void:
	test_fixture()
	test_illegal_rejection()
	test_emotion_decay_and_transform()
	var batch := run_batch()
	test_completion(batch)
	test_persistence_and_causality(batch)
	test_rank_paths(batch)
	test_dilemma_variety(batch)
	test_determinism()
	report_batch(batch)
	test_i18n_campaign(batch)
	print("")
	print("=== CAMPAIGN VALIDATION SUMMARY ===")
	print("checks: %d, failures: %d" % [checks, failures.size()])
	for f in failures:
		print("FAIL: " + f)
	if failures.is_empty():
		print("ALL CAMPAIGN VALIDATION PASSED")
	quit(0 if failures.is_empty() else 1)

func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)

# ---------------------------------------------------------------- 불변식

func check_invariants(s: CampaignState, ctx: String) -> void:
	for f in ["legitimacy", "influence", "cohesion", "succession_stability"]:
		var v: int = s.get(f)
		check(v >= 0 and v <= 100, "%s: %s out of range: %d" % [ctx, f, v])
	check(s.debt >= 0, ctx + ": debt negative")
	check(s.rank >= 0 and s.rank <= 2, ctx + ": rank out of band: %d" % s.rank)
	check(s.generation >= 1 and s.generation <= 3, ctx + ": generation out of range: %d" % s.generation)
	check(s.turn >= 1 and s.turn <= CampaignRules.GEN_MAX_TURNS, ctx + ": turn out of range: %d" % s.turn)
	check(s.action_points >= 0 and s.action_points <= 2, ctx + ": AP out of range")
	# 감정 상한: 인물당 3개 이하, 모두 근거(source_key) 보유.
	var per_owner: Dictionary = {}
	for e in s.emotions:
		per_owner[e["owner"]] = int(per_owner.get(e["owner"], 0)) + 1
		check(e["source_key"] != "", ctx + ": emotion without source")
		check(int(e["intensity"]) > 0 and int(e["intensity"]) <= 100, ctx + ": emotion intensity out of range")
	for o in per_owner:
		check(int(per_owner[o]) <= CampaignState.MAX_EMOTIONS_PER_CHAR, ctx + ": emotions unbounded for " + str(o))
	# 활성 기억 상한과 근거.
	var act := 0
	for m in s.memories:
		if m["active"]:
			act += 1
		check(m["origin_key"] != "", ctx + ": memory without origin event")
		check(int(m["generation"]) >= 1, ctx + ": memory without generation")
		check(not (m["people"] as Array).is_empty(), ctx + ": memory without people")
	check(act <= CampaignState.MAX_ACTIVE_MEMORIES, ctx + ": active memories unbounded")
	# 승계는 세대당 정확히 1회, 최소 턴 이후.
	var per_gen: Dictionary = {}
	for r in s.succession_records:
		per_gen[r["generation"]] = int(per_gen.get(r["generation"], 0)) + 1
		check(int(r["turn"]) >= CampaignRules.GEN_MIN_TURNS,
			"%s: succession before min turns (g%d t%d)" % [ctx, r["generation"], r["turn"]])
	for g in per_gen:
		check(int(per_gen[g]) == 1, ctx + ": generation %s has %d successions" % [str(g), per_gen[g]])

# ---------------------------------------------------------------- 픽스처

func test_fixture() -> void:
	var sizes: Dictionary = {}
	for seed_v in range(1, 11):
		var s := CampaignRules.new_campaign(seed_v)
		check_invariants(s, "fixture seed %d" % seed_v)
		check(s.phase == CampaignState.PHASE_ACTIONS, "fixture: wrong phase")
		check(s.generation == 1 and s.turn == 1, "fixture: wrong start")
		check(s.rank == 1, "fixture: wrong start rank")
		var kids := s.children_of(s.current_head_id)
		check(kids.size() >= 2 and kids.size() <= 4, "fixture: children count %d" % kids.size())
		check(s.spouse_of(s.current_head_id) != "", "fixture: head unmarried")
		check(s.main_estate_ids().size() == 2, "fixture: estates wrong")
		sizes[kids.size()] = true
		# 동일 시드 재생성은 동일 스냅숏.
		var s2 := CampaignRules.new_campaign(seed_v)
		check(s.snapshot_string() == s2.snapshot_string(), "fixture: seed %d not deterministic" % seed_v)
	check(sizes.size() >= 2, "fixture: family structure identical across seeds")

# ---------------------------------------------------------------- 불법 입력 거부

func test_illegal_rejection() -> void:
	var s := CampaignRules.new_campaign(42)
	var before := s.snapshot_string()
	var r := CampaignRules.apply_dilemma_choice(s, "competing_heirs:back_elder")
	check(r.has("error"), "illegal: dilemma choice in action phase accepted")
	r = CampaignRules.confirm_succession(s)
	check(r.has("error"), "illegal: confirm_succession in action phase accepted")
	r = CampaignRules.apply_action(s, "no_such_action")
	check(r.has("error"), "illegal: unknown action accepted")
	r = CampaignRules.apply_action(s, "educate", "not_a_child")
	check(r.has("error"), "illegal: invalid option accepted")
	r = CampaignRules.apply_action(s, "abdicate")
	check(r.has("error"), "illegal: abdicate before min turns accepted")
	check(s.snapshot_string() == before, "illegal: rejected input mutated state")
	# AP 소진 후 행동 거부.
	CampaignRules.apply_action(s, "reorganize_estate")
	CampaignRules.apply_action(s, "court_favor")
	r = CampaignRules.apply_action(s, "settle_debt")
	check(r.has("error"), "illegal: action beyond AP accepted")

# ---------------------------------------------------------------- 감정 감쇠/전이

func test_emotion_decay_and_transform() -> void:
	var s := CampaignRules.new_campaign(7)
	var kids := s.children_of(s.current_head_id)
	var a: String = kids[0]
	var b: String = kids[1]
	s.add_emotion(a, "resentment", b, 30, "test.source")
	check(s.emotion_intensity(a, "resentment", b) == 30, "emotion: add failed")
	for i in range(9):
		CampaignRules._upkeep(s)
	check(s.emotion_intensity(a, "resentment", b) == 0, "emotion: no decay after 9 upkeeps")
	# 대상 사망 시 기억 없는 감정은 제거된다.
	s.add_emotion(a, "jealousy", b, 80, "test.source")
	CampaignRules._on_death(s, b)
	check(s.emotion_intensity(a, "jealousy", b) == 0, "emotion: not removed on target death")
	# 기억 기반 감정은 기억 관련 생존자에게 절반 강도로 전이된다.
	var c: String = s.current_head_id
	var mem := s.add_memory("betrayal", "test.origin", [b, c])
	s.add_emotion(a, "resentment", b, 60, "test.source", mem)
	CampaignRules._on_death(s, b)
	check(s.emotion_intensity(a, "resentment", c) == 30, "emotion: memory-based transform failed")

# ---------------------------------------------------------------- 봇 드라이버

class Bot:
	var profile: String
	var rng_state: int

	func _init(p: String, seed_v: int) -> void:
		profile = p
		rng_state = (seed_v * 48271 + PROFILES_INDEX[p] * 7919 + 12345) & 0x7FFFFFFF
		if rng_state == 0:
			rng_state = 1

	const PROFILES_INDEX := {
		"steward": 0, "ambitious": 1, "harmony": 2, "reckless": 3, "phoenix": 4, "random": 5,
	}

	func roll(n: int) -> int:
		rng_state = (rng_state * 48271) % 2147483647
		return rng_state % n if n > 0 else 0

	# 전략별 선호 패턴(전방 일치). 딜레마는 "d:<choice_id>", 행동은 "a:<action_id>".
	func prefs(s: CampaignState) -> Array:
		match profile:
			"steward":
				return ["a:settle_debt", "a:declare_heir", "a:appease", "a:educate", "a:reconcile",
					"d:rescue_house:sell_estate", "d:royal_levy:pay", "d:marriage_obligation:compensate",
					"d:branch_claim:buy_off", "d:competing_heirs:demand_peace", "d:disloyal_kin:forgive",
					"d:property_division:promise_income", "d:legal_vs_emotional:uphold_law",
					"d:exile_return:allow", "d:recovery_offer:tribute", "d:regency_overreach:yield",
					"d:rescue_house:accept"]
			"ambitious":
				return ["a:petition_rank", "a:court_favor", "a:reorganize_estate", "a:declare_heir",
					"a:arrange_marriage", "d:royal_levy:pay", "d:branch_claim:reject",
					"d:competing_heirs:back_elder", "d:marriage_obligation:comply",
					"d:legal_vs_emotional:uphold_law", "d:disloyal_kin:disinherit",
					"d:regency_overreach:curb", "d:rescue_house:accept", "d:recovery_offer:tribute",
					"d:property_division:refuse", "d:exile_return:refuse"]
			"harmony":
				return ["a:reconcile", "a:appease", "a:grant_estate", "a:educate", "a:declare_heir",
					"d:competing_heirs:demand_peace", "d:branch_claim:recognize",
					"d:property_division:divide", "d:disloyal_kin:forgive", "d:exile_return:allow",
					"d:marriage_obligation:compensate", "d:legal_vs_emotional:divide_duty",
					"d:regency_overreach:yield", "d:rescue_house:accept", "d:royal_levy:send_kin",
					"d:recovery_offer:endure"]
			"reckless":
				return ["a:reorganize_estate", "a:court_favor", "d:rescue_house:refuse",
					"d:royal_levy:refuse", "d:branch_claim:reject", "d:marriage_obligation:refuse",
					"d:disloyal_kin:exile", "d:competing_heirs:back_second",
					"d:legal_vs_emotional:favor_beloved", "d:property_division:refuse",
					"d:regency_overreach:curb", "d:exile_return:refuse", "d:recovery_offer:endure"]
			"phoenix":
				# 1단계: 재산을 소진해 몰락을 유도 → 2단계: 최하 랭크에서 합법 회복 → 3단계: 안정 운영.
				var fell := s.rank == 0
				for r in s.rank_history:
					if int(r["to"]) == 0:
						fell = true
				if s.rank == 0:
					return ["d:recovery_offer:marry_patron", "d:recovery_offer:tribute",
						"a:petition_rank", "a:reorganize_estate", "a:settle_debt",
						"d:rescue_house:accept", "d:branch_claim:buy_off",
						"d:competing_heirs:demand_peace", "d:disloyal_kin:forgive"]
				if not fell:
					return ["a:court_favor", "a:appease", "a:educate", "d:rescue_house:refuse",
						"d:royal_levy:refuse", "d:branch_claim:reject",
						"d:marriage_obligation:refuse", "d:recovery_offer:endure"]
				return ["a:settle_debt", "a:reorganize_estate", "a:declare_heir", "a:court_favor",
					"d:rescue_house:accept", "d:royal_levy:pay", "d:branch_claim:buy_off",
					"d:competing_heirs:demand_peace", "d:disloyal_kin:forgive", "d:exile_return:allow"]
		return []

	func pick(s: CampaignState, legal: Array) -> Dictionary:
		if profile != "random":
			for pref in prefs(s):
				var matches: Array = []
				for inp in legal:
					var tag := ""
					match inp["type"]:
						"action":
							tag = "a:" + inp["id"]
						"dilemma":
							tag = "d:" + inp["id"]
						"end_turn":
							tag = "e"
						"confirm_succession":
							tag = "s"
					if tag.begins_with(pref) or tag == pref:
						matches.append(inp)
				if not matches.is_empty():
					return matches[roll(matches.size())]
			# 선호 미충족: 확률적으로 턴 종료 또는 임의 합법 입력.
			for inp in legal:
				if inp["type"] == "confirm_succession":
					return inp
			if roll(100) < 55:
				for inp in legal:
					if inp["type"] == "end_turn":
						return inp
		return legal[roll(legal.size())]

# 한 캠페인을 완주시키고 결과를 반환한다.
func run_campaign(seed_v: int, profile: String, do_invariants: bool = true) -> Dictionary:
	var s := CampaignRules.new_campaign(seed_v)
	var bot := Bot.new(profile, seed_v)
	var steps := 0
	var errors := 0
	while s.phase != CampaignState.PHASE_LEGACY and steps < MAX_STEPS:
		steps += 1
		var legal := CampaignRules.legal_inputs(s)
		if legal.is_empty():
			break
		var inp: Dictionary = bot.pick(s, legal)
		var r: Dictionary = {}
		match inp["type"]:
			"action":
				r = CampaignRules.apply_action(s, inp["id"], inp["option"])
			"end_turn":
				r = CampaignRules.end_action_phase(s)
			"dilemma":
				r = CampaignRules.apply_dilemma_choice(s, inp["id"])
			"confirm_succession":
				r = CampaignRules.confirm_succession(s)
		if r.has("error"):
			errors += 1
		if do_invariants and steps % 7 == 0:
			check_invariants(s, "run %s/%d step %d" % [profile, seed_v, steps])
	return {
		"seed": seed_v, "profile": profile, "state": s, "steps": steps, "errors": errors,
		"complete": s.phase == CampaignState.PHASE_LEGACY,
	}

func run_batch() -> Array:
	var out: Array = []
	for p in PROFILES:
		for seed_v in range(1, BATCH_SEEDS_PER_PROFILE + 1):
			out.append(run_campaign(seed_v, p))
	return out

# ---------------------------------------------------------------- 완주

func test_completion(batch: Array) -> void:
	for run in batch:
		var ctx := "completion %s/%d" % [run["profile"], run["seed"]]
		var s: CampaignState = run["state"]
		check(run["complete"], ctx + ": did not reach legacy (phase=%s steps=%d)" % [s.phase, run["steps"]])
		check(run["errors"] == 0, ctx + ": legal input rejected %d times" % run["errors"])
		if not run["complete"]:
			continue
		check(s.generation == 3, ctx + ": generation is %d, fourth generation opened" % s.generation)
		check(s.succession_records.size() == 3, ctx + ": %d successions" % s.succession_records.size())
		var gens: Array = []
		for r in s.succession_records:
			gens.append(int(r["generation"]))
		check(gens == [1, 2, 3], ctx + ": succession generations " + str(gens))
		check(s.next_successor_id != "", ctx + ": no next successor recorded")
		check(not s.legacy_result.is_empty(), ctx + ": no legacy result")
		check(s.pending_dilemma.is_empty(), ctx + ": unresolved mandatory input at end")
		check(CampaignRules.legal_inputs(s).is_empty(), ctx + ": inputs still legal after legacy")
		check_invariants(s, ctx)

# ---------------------------------------------------------------- 지속성/인과

func test_persistence_and_causality(batch: Array) -> void:
	var causal_runs := 0
	var complete_runs := 0
	for run in batch:
		if not run["complete"]:
			continue
		complete_runs += 1
		var s: CampaignState = run["state"]
		var ctx := "persist %s/%d" % [run["profile"], run["seed"]]
		# 1세대 기억이 캠페인 종료까지 보존된다.
		var gen1_mem := false
		for m in s.memories:
			if int(m["generation"]) == 1:
				gen1_mem = true
		check(gen1_mem, ctx + ": no generation-1 memory persisted")
		# 혈통: 3세대 승계자는 가계 기록을 가진다.
		var ns: String = s.next_successor_id
		if ns != "" and s.has_chr(ns):
			var c: Dictionary = s.chr(ns)
			check(c["father_id"] != "" or c["mother_id"] != "" or int(c["generation_born"]) == 1,
				ctx + ": successor has no lineage record")
		# 결혼 기록 보존.
		check(s.marriages.size() >= 1, ctx + ": marriages lost")
		# 세대 간 인과: 이전 세대 기억이 원인인 딜레마.
		for d in s.dilemma_history:
			if d["origin_memory_id"] == "":
				continue
			var m := s.memory_by_id(d["origin_memory_id"])
			if not m.is_empty() and int(m["generation"]) < int(d["generation"]):
				causal_runs += 1
				break
	check(complete_runs > 0, "persist: no complete runs")
	# 상당수 캠페인에서 1세대 결정이 후대 딜레마의 원인이 되어야 한다.
	check(causal_runs * 100 >= complete_runs * 40,
		"persist: cross-generation causality only in %d/%d runs" % [causal_runs, complete_runs])
	print("  cross-generation causal dilemmas: %d/%d runs" % [causal_runs, complete_runs])

# ---------------------------------------------------------------- 랭크 경로

func test_rank_paths(batch: Array) -> void:
	var rise := 0
	var fall := 0
	var recovery := 0
	for run in batch:
		if not run["complete"]:
			continue
		var s: CampaignState = run["state"]
		var fell_to_bottom := false
		for r in s.rank_history:
			if int(r["to"]) > int(r["from"]) and int(r["to"]) == 2:
				rise += 1
			if int(r["to"]) < int(r["from"]):
				fall += 1
			if int(r["to"]) == 0:
				fell_to_bottom = true
			if fell_to_bottom and int(r["to"]) >= 1 and int(r["from"]) == 0:
				recovery += 1
	check(rise > 0, "rank: no legal rise path exercised")
	check(fall > 0, "rank: no legal fall path exercised")
	check(recovery > 0, "rank: no legal recovery path exercised")
	print("  rank paths: rise=%d fall=%d recovery=%d (occurrences)" % [rise, fall, recovery])

# ---------------------------------------------------------------- 딜레마 다양성

func test_dilemma_variety(batch: Array) -> void:
	var structures: Dictionary = {}
	var beneficiary_roles: Dictionary = {}
	var later_gen_new_structure := 0
	var complete_runs := 0
	var histories: Dictionary = {}
	for run in batch:
		if not run["complete"]:
			continue
		complete_runs += 1
		var s: CampaignState = run["state"]
		var gen1_structs: Dictionary = {}
		var later_structs: Dictionary = {}
		for d in s.dilemma_history:
			structures[d["structure"]] = int(structures.get(d["structure"], 0)) + 1
			for b in d["beneficiaries"]:
				if s.has_chr(b):
					beneficiary_roles[s.chr(b)["role"]] = true
			if int(d["generation"]) == 1:
				gen1_structs[d["structure"]] = true
			else:
				later_structs[d["structure"]] = true
		for st in later_structs:
			if not gen1_structs.has(st):
				later_gen_new_structure += 1
				break
		histories[str(run["state"].input_log)] = true
	check(structures.size() >= 6,
		"variety: only %d distinct dilemma structures seen" % structures.size())
	check(later_gen_new_structure * 100 >= complete_runs * 50,
		"variety: later generations repeat gen-1 structures (%d/%d)" % [later_gen_new_structure, complete_runs])
	# 전략이 실제로 서로 다른 입력 이력을 만든다.
	check(histories.size() * 100 >= complete_runs * 90,
		"variety: input histories not varied (%d distinct / %d runs)" % [histories.size(), complete_runs])
	print("  dilemma structures used: " + str(structures))

# ---------------------------------------------------------------- 결정성

func test_determinism() -> void:
	for p in ["steward", "reckless", "random"]:
		for seed_v in [3, 11, 19]:
			var a := run_campaign(seed_v, p, false)
			var b := run_campaign(seed_v, p, false)
			var sa: CampaignState = a["state"]
			var sb: CampaignState = b["state"]
			var ctx := "determinism %s/%d" % [p, seed_v]
			check(sa.digest() == sb.digest(), ctx + ": digest mismatch")
			check(str(sa.input_log) == str(sb.input_log), ctx + ": input log mismatch")
			check(sa.chronicle.size() == sb.chronicle.size(), ctx + ": chronicle mismatch")
			check(str(sa.legacy_result) == str(sb.legacy_result), ctx + ": legacy mismatch")
			check(str(sa.rank_history) == str(sb.rank_history), ctx + ": rank history mismatch")
			check(str(sa.succession_records.map(func(r): return "%s:%s" % [r["cause"], r["outcome"]])) \
				== str(sb.succession_records.map(func(r): return "%s:%s" % [r["cause"], r["outcome"]])),
				ctx + ": succession evidence mismatch")
			# 기록된 입력을 그대로 재생하면 동일 상태에 도달한다.
			var sr := replay_inputs(seed_v, sa.input_log)
			check(sr != null and sr.digest() == sa.digest(), ctx + ": input replay digest mismatch")

func replay_inputs(seed_v: int, log: PackedStringArray) -> CampaignState:
	var s := CampaignRules.new_campaign(seed_v)
	for raw in log:
		var r: Dictionary = {}
		if raw == "E":
			r = CampaignRules.end_action_phase(s)
		elif raw == "S":
			r = CampaignRules.confirm_succession(s)
		elif raw.begins_with("A:"):
			var rest := raw.substr(2)
			var idx := rest.find(":")
			r = CampaignRules.apply_action(s, rest.substr(0, idx), rest.substr(idx + 1))
		elif raw.begins_with("D:"):
			r = CampaignRules.apply_dilemma_choice(s, raw.substr(2))
		if r.has("error"):
			check(false, "replay: input rejected: " + raw)
			return null
	return s

# ---------------------------------------------------------------- i18n 완전성

var _tables: Dictionary = {}

func load_locale(loc: String) -> Dictionary:
	if _tables.has(loc):
		return _tables[loc]
	var f := FileAccess.open("res://i18n/%s.json" % loc, FileAccess.READ)
	check(f != null, "i18n: missing file " + loc)
	if f == null:
		return {}
	var data: Variant = JSON.parse_string(f.get_as_text())
	check(data is Dictionary, "i18n: invalid json " + loc)
	_tables[loc] = data if data is Dictionary else {}
	return _tables[loc]

func t_key_exists(key: String) -> void:
	for loc in ["en", "ko"]:
		var tab := load_locale(loc)
		check(tab.has(key) and String(tab[key]).strip_edges() != "", "i18n[%s]: missing key %s" % [loc, key])

# 캠페인 규칙이 참조하는 키 계열 + 배치에서 실제 사용된 키를 EN/KO 양쪽에서 전수 검사한다.
func test_i18n_campaign(batch: Array) -> void:
	for id in CampaignRules.ACTION_IDS:
		t_key_exists("action.%s.title" % id)
		t_key_exists("action.%s.desc" % id)
	for st in CampaignRules.DILEMMA_STRUCTURES:
		t_key_exists("dlm.%s.title" % st)
		t_key_exists("dlm.%s.desc" % st)
	for r in CampaignState.RANK_IDS:
		t_key_exists(r)
	for k in ["age", "health", "abdication", "forced_removal", "max_turns"]:
		t_key_exists("succcause." + k)
	for k in ["betrayal", "exile", "disinheritance", "forced_marriage", "house_rescue",
			"rights_seized", "rights_restored"]:
		t_key_exists("memkind." + k)
		t_key_exists("memeffect." + k)
	for k in ["resentment", "affection", "jealousy", "fear"]:
		t_key_exists("emotion." + k)
	for k in ["camp_min_turns", "camp_succession_window", "camp_max_turns", "camp_royal_levy"]:
		t_key_exists("upcoming." + k)
	for k in ["rivalry_deepens", "unresolved_claims", "lasting_resentment", "house_grudge",
			"wealth_drain", "weakened_line", "claim_persists", "branch_feud", "reduced_seat",
			"debt_grows", "claims_harden", "regent_power", "regent_resentment", "young_rule",
			"disinherited_line", "exiled_return", "repeat_betrayal", "restored_rival",
			"outside_claim", "obligation_due", "rank_fall", "kin_resentment",
			"prolonged_decline", "spurned_heir", "cold_duty"]:
		t_key_exists("risk." + k)
	for k in ["no_valid_target", "wealth_10", "wealth_18", "influence_6", "need_spare_estate",
			"rank_at_top", "petition_used", "petition_threshold", "petition_threshold_low",
			"no_debt", "too_early_abdicate", "head_too_young"]:
		t_key_exists("reason." + k)
	# 배치에서 실제 발생한 키.
	var used: Dictionary = {}
	for run in batch:
		var s: CampaignState = run["state"]
		for e in s.chronicle:
			used[e["key"]] = true
		for d in s.dilemma_history:
			used["choice.%s.title" % d["choice"]] = true
			used["choice.%s.desc" % d["choice"]] = true
		for r in s.succession_records:
			used["outcome." + str(r["outcome"])] = true
			var ev: Dictionary = r["evidence"]
			for cid in ev["candidates"]:
				for p in ev["candidates"][cid]["parts"]:
					used[p["key"]] = true
			for ch in ev["changes"]:
				used[ch["key"]] = true
		if not s.legacy_result.is_empty():
			used["legresult.%s.title" % s.legacy_result["result_id"]] = true
			used["legresult.%s.desc" % s.legacy_result["result_id"]] = true
			for c in s.legacy_result["contributors"]:
				used[c["key"]] = true
		for cid in s.sorted_char_ids():
			used[s.chr(cid)["name_key"]] = true
		for m in s.memories:
			used[m["effect_key"]] = true
	for k in used:
		t_key_exists(str(k))
	print("  i18n keys exercised by batch: %d" % used.size())

# ---------------------------------------------------------------- 배치 보고

func report_batch(batch: Array) -> void:
	var complete := 0
	var incomplete := 0
	var causes: Dictionary = {}
	var outcomes: Dictionary = {}
	var final_ranks: Dictionary = {}
	var legacies: Dictionary = {}
	for run in batch:
		if not run["complete"]:
			incomplete += 1
			continue
		complete += 1
		var s: CampaignState = run["state"]
		for r in s.succession_records:
			causes[r["cause"]] = int(causes.get(r["cause"], 0)) + 1
			outcomes[r["outcome"]] = int(outcomes.get(r["outcome"], 0)) + 1
		final_ranks[s.rank] = int(final_ranks.get(s.rank, 0)) + 1
		legacies[s.legacy_result["result_id"]] = int(legacies.get(s.legacy_result["result_id"], 0)) + 1
	print("")
	print("=== CAMPAIGN BATCH REPORT ===")
	print("  campaigns: %d complete, %d incomplete (profiles: %s x %d seeds)" \
		% [complete, incomplete, str(PROFILES), BATCH_SEEDS_PER_PROFILE])
	print("  succession causes: " + str(causes))
	print("  succession outcomes: " + str(outcomes))
	print("  final rank distribution: " + str(final_ranks))
	print("  legacy results: " + str(legacies))
	check(incomplete == 0, "batch: %d incomplete campaigns" % incomplete)
	check(causes.size() >= 3, "batch: succession causes not varied: " + str(causes))
	check(legacies.size() >= 2, "batch: legacy results not varied: " + str(legacies))
