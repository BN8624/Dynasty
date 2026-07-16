# 헤드리스 검증 스위트 — 픽스처/불법입력 거부/도달성/100회 배치/결정성/승계 증거/i18n 완전성을 검사한다.
# 실행: godot --headless --path . --script res://tests/validate.gd
extends SceneTree

var failures: Array = []
var checks: int = 0

func _initialize() -> void:
	test_fixture()
	test_illegal_rejection()
	test_reachability_scripts()
	test_batch_runs()
	test_determinism()
	test_i18n()
	print("")
	print("=== VALIDATION SUMMARY ===")
	print("checks: %d, failures: %d" % [checks, failures.size()])
	for f in failures:
		print("FAIL: " + f)
	if failures.is_empty():
		print("ALL VALIDATION PASSED")
	quit(0 if failures.is_empty() else 1)

func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)

# ---------------------------------------------------------------- invariants

func check_invariants(s: SimState, ctx: String) -> void:
	for f in ["legitimacy", "influence", "cohesion", "succession_stability"]:
		var v: int = s.get(f)
		check(v >= 0 and v <= 100, "%s: %s out of range: %d" % [ctx, f, v])
	check(s.debt >= 0, ctx + ": debt negative")
	check(s.estate_count >= 0, ctx + ": estate negative")
	check(s.action_points >= 0 and s.action_points <= 2, ctx + ": AP out of range")
	check(s.turn >= 1 and s.turn <= 12, ctx + ": turn out of range: %d" % s.turn)
	for id in s.characters:
		var c: Dictionary = s.characters[id]
		for cf in ["health", "ability", "legal_claim", "ambition"]:
			check(int(c[cf]) >= 0 and int(c[cf]) <= 100, "%s: %s.%s out of range" % [ctx, id, cf])
		if c["loyalty"] != null:
			check(int(c["loyalty"]) >= 0 and int(c["loyalty"]) <= 100, "%s: %s.loyalty out of range" % [ctx, id])
	for k in s.relationships:
		check(int(s.relationships[k]) >= 0 and int(s.relationships[k]) <= 100, ctx + ": rel out of range " + k)
	if s.phase == SimState.PHASE_OVER:
		check(s.terminal_result_id != "", ctx + ": over without terminal result")
	else:
		check(s.terminal_result_id == "", ctx + ": terminal result set while playing")

# ---------------------------------------------------------------- fixture

func test_fixture() -> void:
	var s := Rules.new_game(1)
	check(s.wealth == 60 and s.debt == 20 and s.legitimacy == 55 and s.influence == 35, "fixture house values")
	check(s.cohesion == 45 and s.succession_stability == 35 and s.estate_count == 1, "fixture house values 2")
	check(s.formal_heir_id == "aldren_arven" and s.current_head_id == "edric_arven", "fixture heir/head")
	check(s.turn == 1 and s.action_points == 2, "fixture turn/ap")
	var e: Dictionary = s.chr("edric_arven")
	check(e["age_months"] == 648 and e["health"] == 30 and e["legal_claim"] == 90 \
		and e["ability"] == 55 and e["loyalty"] == null and e["ambition"] == 35, "fixture edric")
	var r: Dictionary = s.chr("rowen_arven")
	check(r["age_months"] == 192 and r["health"] == 80 and r["legal_claim"] == 45 \
		and r["ability"] == 70 and r["loyalty"] == 50 and r["ambition"] == 80, "fixture rowen")
	check(s.get_rel("edric_arven", "aldren_arven") == 65, "fixture rel EA")
	check(s.get_rel("beric_arven", "rowen_arven") == 75, "fixture rel BR")
	check(s.get_rel("aldren_arven", "rowen_arven") == 45, "fixture rel AR")
	check(s.flags["marriage_partner_house_id"] == "" and not s.flags["marriage_completed"], "fixture flags")
	check_invariants(s, "fixture")

# ---------------------------------------------------------------- illegal input rejection

func test_illegal_rejection() -> void:
	var s := Rules.new_game(1)
	var before := s.snapshot_string()
	# 같은 액션을 같은 턴에 두 번
	Rules.apply_action(s, "reorganize_estate")
	var after_one := s.snapshot_string()
	var res := Rules.apply_action(s, "reorganize_estate")
	check(res.has("error"), "repeat action must be rejected")
	check(s.snapshot_string() == after_one, "repeat action must not change state")
	# 전제조건 미충족 (재산 부족)
	var s2 := Rules.new_game(1)
	s2.wealth = 0
	var snap2 := s2.snapshot_string()
	res = Rules.apply_action(s2, "educate_aldren")
	check(res.has("error"), "unaffordable action must be rejected")
	check(s2.snapshot_string() == snap2, "unaffordable action must not change state")
	# 잘못된 페이즈의 이벤트 선택
	var s3 := Rules.new_game(1)
	var snap3 := s3.snapshot_string()
	res = Rules.apply_event_choice(s3, "debt_demand:pay_now")
	check(res.has("error"), "event choice outside event phase must be rejected")
	check(s3.snapshot_string() == snap3, "phase-illegal choice must not change state")
	# 옵션 누락
	res = Rules.apply_action(s3, "negotiate_marriage", "")
	check(res.has("error"), "marriage without option must be rejected")
	check(s3.snapshot_string() == snap3, "optionless marriage must not change state")
	# AP 소진 후 액션
	var s4 := Rules.new_game(1)
	Rules.apply_action(s4, "reorganize_estate")
	Rules.apply_action(s4, "reconcile_brothers")
	var snap4 := s4.snapshot_string()
	res = Rules.apply_action(s4, "appease_beric")
	check(res.has("error"), "action without AP must be rejected")
	check(s4.snapshot_string() == snap4, "AP-less action must not change state")

# ---------------------------------------------------------------- script driver

# 스크립트: {actions:{turn:[[id,option],...]}, choices:{event_id:choice_id}}
# 모든 수는 합법성 검사를 통과해야 하며, 위반 시 실패로 기록한다.
func run_script(seed_value: int, script: Dictionary, name: String) -> SimState:
	var s := Rules.new_game(seed_value)
	var steps := 0
	while s.terminal_result_id == "" and steps < 300:
		steps += 1
		match s.phase:
			SimState.PHASE_ACTIONS:
				var acts: Array = script.get("actions", {}).get(s.turn, [])
				for a in acts:
					if s.terminal_result_id != "":
						break
					var chk := Rules.action_check(s, a[0])
					check(chk["ok"], "%s: illegal scripted action %s on turn %d (%s)" % [name, a[0], s.turn, chk["reason"]])
					if not chk["ok"]:
						return s
					Rules.apply_action(s, a[0], a[1])
					check_invariants(s, "%s action %s" % [name, a[0]])
				if s.terminal_result_id == "":
					Rules.end_action_phase(s)
					check_invariants(s, name + " end_phase")
			SimState.PHASE_EVENT:
				var eid: String = s.pending_event["event_id"]
				var cid: String = script.get("choices", {}).get(eid, "")
				check(cid != "", "%s: no scripted choice for event %s" % [name, eid])
				if cid == "":
					return s
				var chk2 := Rules.event_choice_check(s, cid)
				check(chk2["ok"], "%s: illegal scripted choice %s (%s)" % [name, cid, chk2["reason"]])
				if not chk2["ok"]:
					return s
				Rules.apply_event_choice(s, cid)
				check_invariants(s, name + " choice " + cid)
			SimState.PHASE_SUCCESSION:
				verify_succession_evidence(s, name)
				Rules.continue_after_succession(s)
				check_invariants(s, name + " post-succession")
			_:
				break
	check(s.terminal_result_id != "", name + ": run did not terminate")
	check(s.turn <= 12, name + ": ran past turn 12")
	check(s.phase == SimState.PHASE_OVER, name + ": terminal without OVER phase")
	return s

# ---------------------------------------------------------------- succession evidence

# 증거의 부분합 = 총점, 그리고 입력 스냅샷으로 정본 공식을 재계산해 일치를 검증.
func verify_succession_evidence(s: SimState, ctx: String) -> void:
	var ev: Dictionary = s.succession_evidence
	check(not ev.is_empty(), ctx + ": missing succession evidence")
	if ev.is_empty():
		return
	for cid in ev["candidates"]:
		var total := 0
		for p in ev["candidates"][cid]["parts"]:
			total += int(p["value"])
		check(total == int(ev["candidates"][cid]["total"]),
			"%s: evidence parts sum mismatch for %s" % [ctx, cid])
	var inp: Dictionary = ev["inputs"]
	var a_score: int = 40 + int(floor(int(inp["aldren_claim"]) * 0.30)) + int(floor(int(inp["aldren_ability"]) * 0.10))
	if inp["myra_loyalty"] != null and int(inp["myra_loyalty"]) >= 60:
		a_score += 10
	if inp["formal_heir_id"] == "aldren_arven":
		a_score += 15
	if int(inp["brothers_rel"]) >= 50:
		a_score += 5
	var r_score: int = 20 + int(floor(int(inp["rowen_claim"]) * 0.30)) + int(floor(int(inp["rowen_ability"]) * 0.20))
	if inp["beric_loyalty"] != null and int(inp["beric_loyalty"]) >= 60:
		r_score += 15
	if inp["formal_heir_id"] == "rowen_arven":
		r_score += 20
	if int(inp["rowen_ambition"]) >= 75:
		r_score += 5
	var bl: int = int(inp["beric_loyalty"])
	if bl < 50 and not inp["beric_secret_known"]:
		r_score += 10
	elif bl < 50 and inp["beric_secret_known"]:
		r_score += 5
	check(a_score == int(ev["candidates"]["aldren_arven"]["total"]),
		"%s: aldren score recomputation mismatch (%d vs %d)" % [ctx, a_score, ev["candidates"]["aldren_arven"]["total"]])
	check(r_score == int(ev["candidates"]["rowen_arven"]["total"]),
		"%s: rowen score recomputation mismatch (%d vs %d)" % [ctx, r_score, ev["candidates"]["rowen_arven"]["total"]])
	# 결과 분기 재검증
	var diff: int = absi(a_score - r_score)
	var coh: int = int(inp["cohesion"])
	var expected := ""
	if diff <= 5 and coh < 35:
		expected = "succession_civil_war"
	if expected == "":
		var winner_a: bool = a_score > r_score or (a_score == r_score)  # tie: formal heir else aldren
		if a_score == r_score and inp["formal_heir_id"] == "rowen_arven":
			winner_a = false
		if winner_a:
			if a_score - r_score >= 15 and int(inp["aldren_claim"]) >= 65 and coh >= 40:
				expected = "stable_aldren"
			else:
				expected = "unstable_aldren"
		else:
			if inp["formal_heir_id"] == "rowen_arven" and coh >= 50 \
					and inp["aldren_loyalty"] != null and int(inp["aldren_loyalty"]) >= 45:
				expected = "agreed_rowen"
			else:
				expected = "contested_rowen"
	check(expected == s.succession_outcome_id,
		"%s: outcome mismatch — expected %s, got %s" % [ctx, expected, s.succession_outcome_id])

# ---------------------------------------------------------------- reachability

const A := "aldren_arven"
const R := "rowen_arven"

func test_reachability_scripts() -> void:
	var reached_outcomes := {}
	var reached_terminals := {}
	var scripts := [
		{
			"name": "S1_stable_aldren_stable_victory",
			"expect_outcome": "stable_aldren",
			"expect_terminal": "victory_stable_succession",
			"actions": {
				1: [["negotiate_marriage", "house_cardin"], ["appease_beric", ""]],
				2: [["educate_aldren", ""], ["appease_beric", ""]],
				3: [["appease_beric", ""], ["educate_aldren", ""]],
				4: [["declare_heir", A], ["reorganize_estate", ""]],
				5: [["reorganize_estate", ""], ["educate_aldren", ""]],
				7: [["appease_beric", ""], ["reorganize_estate", ""]],
				9: [["reorganize_estate", ""], ["appease_beric", ""]],
				11: [["reorganize_estate", ""], ["appease_beric", ""]],
				12: [["reorganize_estate", ""]],
			},
			"choices": {
				"debt_demand": "debt_demand:pay_now",
				"brothers_conflict": "brothers_conflict:force_reconciliation",
				"losing_brother_demand": "losing_brother_demand:share_income",
			},
		},
		{
			"name": "S2_civil_war_blood_bought",
			"expect_outcome": "succession_civil_war",
			"expect_terminal": "victory_blood_bought",
			"actions": {
				1: [["declare_heir", R], ["reorganize_estate", ""]],
				2: [["reorganize_estate", ""], ["educate_rowen", ""]],
				3: [["reorganize_estate", ""], ["educate_rowen", ""]],
				4: [["reorganize_estate", ""], ["educate_rowen", ""]],
				5: [["educate_rowen", ""]],
				7: [["reorganize_estate", ""]],
				9: [["reorganize_estate", ""]],
			},
			"choices": {
				"debt_demand": "debt_demand:pay_now",
				"brothers_conflict": "brothers_conflict:support_aldren",
				"decisive_civil_conflict": "decisive_civil_conflict:buy_settlement",
			},
		},
		{
			"name": "S3_agreed_rowen",
			"expect_outcome": "agreed_rowen",
			"expect_terminal": "victory_fragile_survival",
			"actions": {
				1: [["declare_heir", R], ["appease_beric", ""]],
				2: [["educate_rowen", ""]],
			},
			"choices": {
				"debt_demand": "debt_demand:pay_now",
				"brothers_conflict": "brothers_conflict:force_reconciliation",
				"losing_brother_demand": "losing_brother_demand:share_income",
			},
		},
		{
			"name": "S4_contested_rowen",
			"expect_outcome": "contested_rowen",
			"expect_terminal": "victory_fragile_survival",
			"actions": {
				1: [["declare_heir", R], ["educate_rowen", ""]],
				2: [["educate_rowen", ""]],
			},
			"choices": {
				"debt_demand": "debt_demand:defer",
				"brothers_conflict": "brothers_conflict:support_rowen",
				"beric_regency_demand": "beric_regency_demand:accept",
				"losing_brother_demand": "losing_brother_demand:court_office",
			},
		},
		{
			"name": "S5_unstable_aldren_fragile",
			"expect_outcome": "unstable_aldren",
			"expect_terminal": "victory_fragile_survival",
			"actions": {
				1: [["reorganize_estate", ""]],
				3: [["reorganize_estate", ""]],
			},
			"choices": {
				"debt_demand": "debt_demand:pay_now",
				"brothers_conflict": "brothers_conflict:support_aldren",
				"losing_brother_demand": "losing_brother_demand:court_office",
			},
		},
		{
			"name": "S6_defeat_estate_lost",
			"expect_outcome": "stable_aldren",
			"expect_terminal": "defeat_estate_lost",
			"actions": {
				1: [["negotiate_marriage", "house_velor"]],
			},
			"choices": {
				"debt_demand": "debt_demand:pay_now",
				"brothers_conflict": "brothers_conflict:force_reconciliation",
				"losing_brother_demand": "losing_brother_demand:court_office",
				"velor_estate_claim": "velor_estate_claim:reject",
				"velor_pressure": "velor_pressure:fail_to_answer",
			},
		},
		{
			# 밸런스 개정 0.4.1(defeat_insolvent: wealth <= -10)의 합법 도달성 회귀 증거.
			"name": "S9_defeat_insolvent",
			"expect_outcome": "stable_aldren",
			"expect_terminal": "defeat_insolvent",
			"actions": {
				1: [["educate_aldren", ""], ["appease_beric", ""]],
				2: [["educate_aldren", ""], ["appease_beric", ""]],
				3: [["educate_aldren", ""], ["appease_beric", ""]],
				4: [["educate_aldren", ""], ["appease_beric", ""]],
				5: [["appease_beric", ""], ["declare_heir", A]],
			},
			"choices": {
				"debt_demand": "debt_demand:defer",
				"brothers_conflict": "brothers_conflict:support_aldren",
				"losing_brother_demand": "losing_brother_demand:share_income",
			},
		},
		{
			"name": "S7_defeat_no_eligible_heir",
			"expect_outcome": "unstable_aldren",
			"expect_terminal": "defeat_no_eligible_heir",
			"actions": {
				1: [["declare_heir", A], ["reorganize_estate", ""]],
				3: [["reorganize_estate", ""]],
			},
			"choices": {
				"debt_demand": "debt_demand:pay_now",
				"brothers_conflict": "brothers_conflict:support_aldren",
				"losing_brother_demand": "losing_brother_demand:refuse",
			},
		},
	]
	for sc in scripts:
		var s := run_script(1, sc, sc["name"])
		print("%s -> outcome=%s terminal=%s (wealth=%d leg=%d coh=%d ss=%d)" % [
			sc["name"], s.succession_outcome_id, s.terminal_result_id,
			s.wealth, s.legitimacy, s.cohesion, s.succession_stability])
		if sc["expect_outcome"] != "":
			check(s.succession_outcome_id == sc["expect_outcome"],
				"%s: expected outcome %s, got %s" % [sc["name"], sc["expect_outcome"], s.succession_outcome_id])
		if sc["expect_terminal"] != "":
			check(s.terminal_result_id == sc["expect_terminal"],
				"%s: expected terminal %s, got %s" % [sc["name"], sc["expect_terminal"], s.terminal_result_id])
		reached_outcomes[s.succession_outcome_id] = true
		reached_terminals[s.terminal_result_id] = true
		render_chronicle_both_locales(s, sc["name"])
	# 정본 21.1 도달성 요구
	check(reached_outcomes.has("stable_aldren"), "reachability: stable_aldren")
	check(reached_outcomes.has("unstable_aldren"), "reachability: unstable_aldren")
	check(reached_outcomes.has("agreed_rowen") or reached_outcomes.has("contested_rowen"),
		"reachability: agreed_rowen or contested_rowen")
	check(reached_outcomes.has("succession_civil_war"), "reachability: succession_civil_war")
	var victories := 0
	var defeats := 0
	for t in reached_terminals:
		if String(t).begins_with("victory_"):
			victories += 1
		elif String(t).begins_with("defeat_"):
			defeats += 1
	check(victories >= 2, "reachability: at least two victory results (got %d)" % victories)
	check(defeats >= 3, "reachability: at least three defeat results (got %d) — %s" % [defeats, str(reached_terminals.keys())])

# ---------------------------------------------------------------- batch runs

# 정책 기반 합법 플레이어. 프로필별 가중치로 액션/선택을 고른다.
func policy_run(seed_value: int, collect_log: Array = []) -> SimState:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var profile: int = seed_value % 6
	var s := Rules.new_game(seed_value)
	var steps := 0
	while s.terminal_result_id == "" and steps < 300:
		steps += 1
		match s.phase:
			SimState.PHASE_ACTIONS:
				var n: int = rng.randi_range(0, 2)
				for i in range(n):
					if s.terminal_result_id != "" or s.action_points <= 0:
						break
					var legal: Array = []
					for entry in Rules.action_catalog(s):
						if entry["ok"]:
							legal.append(entry)
					if legal.is_empty():
						break
					var pick: Dictionary = legal[weighted_index(rng, legal, profile)]
					var opt := ""
					if not (pick["options"] as Array).is_empty():
						var opts: Array = pick["options"]
						opt = opts[rng.randi_range(0, opts.size() - 1)]
					var res := Rules.apply_action(s, pick["id"], opt)
					check(not res.has("error"), "batch %d: legal action rejected: %s" % [seed_value, pick["id"]])
					collect_log.append(["action", pick["id"], opt])
					check_invariants(s, "batch %d action" % seed_value)
				if s.terminal_result_id == "":
					Rules.end_action_phase(s)
					collect_log.append(["end_phase", "", ""])
					check_invariants(s, "batch %d end_phase" % seed_value)
			SimState.PHASE_EVENT:
				var ok_choices: Array = []
				for c in s.pending_event["choices"]:
					if c["ok"]:
						ok_choices.append(c["id"])
				check(not ok_choices.is_empty(), "batch %d: event %s has no legal choice" % [seed_value, s.pending_event["event_id"]])
				if ok_choices.is_empty():
					break
				var cid: String = ok_choices[rng.randi_range(0, ok_choices.size() - 1)]
				var res2 := Rules.apply_event_choice(s, cid)
				check(not res2.has("error"), "batch %d: legal choice rejected: %s" % [seed_value, cid])
				collect_log.append(["choice", cid, ""])
				check_invariants(s, "batch %d choice" % seed_value)
			SimState.PHASE_SUCCESSION:
				verify_succession_evidence(s, "batch %d" % seed_value)
				Rules.continue_after_succession(s)
				collect_log.append(["confirm_succession", "", ""])
				check_invariants(s, "batch %d post-succession" % seed_value)
			_:
				break
	return s

# 프로필별 액션 선호 가중치 인덱스.
func weighted_index(rng: RandomNumberGenerator, legal: Array, profile: int) -> int:
	var weights: Array = []
	for entry in legal:
		var id: String = entry["id"]
		var w := 1.0
		match profile:
			0: # 장남파: 알드렌 육성/공표/회유
				if id in ["educate_aldren", "declare_heir", "appease_beric", "reconcile_brothers"]:
					w = 4.0
			1: # 차남파: 로웬 육성/공표
				if id in ["educate_rowen", "declare_heir", "investigate_secret"]:
					w = 4.0
			2: # 축재파: 영지 재편과 결혼
				if id in ["reorganize_estate", "negotiate_marriage"]:
					w = 4.0
			3: # 화합파: 화해와 회유
				if id in ["reconcile_brothers", "appease_beric", "negotiate_marriage"]:
					w = 4.0
			4: # 낭비파: 지출 액션 선호
				if id in ["educate_aldren", "educate_rowen", "appease_beric", "investigate_secret"]:
					w = 4.0
			5: # 혼돈파: 균등
				w = 1.0
		weights.append(w)
	var total := 0.0
	for w in weights:
		total += w
	var roll := rng.randf() * total
	var acc := 0.0
	for i in range(weights.size()):
		acc += weights[i]
		if roll <= acc:
			return i
	return weights.size() - 1

func test_batch_runs() -> void:
	var dist := {}
	var outcome_dist := {}
	var min_wealth := 999
	for seed_value in range(1, 121):
		var s := policy_run(seed_value)
		check(s.terminal_result_id != "", "batch %d: no terminal result" % seed_value)
		check(s.turn <= 12, "batch %d: exceeded turn 12" % seed_value)
		check(s.phase == SimState.PHASE_OVER, "batch %d: not in OVER phase" % seed_value)
		dist[s.terminal_result_id] = int(dist.get(s.terminal_result_id, 0)) + 1
		if s.succession_outcome_id != "":
			outcome_dist[s.succession_outcome_id] = int(outcome_dist.get(s.succession_outcome_id, 0)) + 1
		min_wealth = mini(min_wealth, s.wealth)
		render_chronicle_both_locales(s, "batch %d" % seed_value)
	print("")
	print("=== 120-run outcome distribution ===")
	var keys: Array = dist.keys()
	keys.sort()
	for k in keys:
		print("  %s: %d" % [k, dist[k]])
	print("  succession outcomes: " + str(outcome_dist))
	print("  min final wealth: %d" % min_wealth)

# ---------------------------------------------------------------- determinism

func test_determinism() -> void:
	for seed_value in [3, 7, 11, 20, 42, 77, 101, 113]:
		var log1: Array = []
		var s1 := policy_run(seed_value, log1)
		var log2: Array = []
		var s2 := policy_run(seed_value, log2)
		check(s1.digest() == s2.digest(), "determinism: same seed %d produced different digest" % seed_value)
		check(str(log1) == str(log2), "determinism: same seed %d produced different input log" % seed_value)
		# 기록된 입력 로그를 스크립트로 재생 → 동일 이력
		var s3 := replay_log(seed_value, log1)
		check(s3 != null and s1.digest() == s3.digest(),
			"determinism: replay of seed %d diverged from original" % seed_value)
		check(str(s1.history) == str(s3.history),
			"determinism: replay of seed %d state history mismatch" % seed_value)

# 기록된 입력 로그를 그대로 재생한다.
func replay_log(seed_value: int, steps_log: Array) -> SimState:
	var s := Rules.new_game(seed_value)
	for step in steps_log:
		if s.terminal_result_id != "":
			break
		match step[0]:
			"action":
				var res := Rules.apply_action(s, step[1], step[2])
				check(not res.has("error"), "replay: action rejected: " + str(step))
			"end_phase":
				Rules.end_action_phase(s)
			"choice":
				var res2 := Rules.apply_event_choice(s, step[1])
				check(not res2.has("error"), "replay: choice rejected: " + str(step))
			"confirm_succession":
				Rules.continue_after_succession(s)
	return s

# ---------------------------------------------------------------- i18n

var _tables := {}

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

func render_chronicle_both_locales(s: SimState, ctx: String) -> void:
	for e in s.chronicle:
		t_key_exists(e["key"])
		t_key_exists("season." + e["season"])

func test_i18n() -> void:
	var en := load_locale("en")
	var ko := load_locale("ko")
	for k in en:
		check(ko.has(k), "i18n[ko]: missing key " + str(k))
	for k in ko:
		check(en.has(k), "i18n[en]: missing key " + str(k))
	# 규칙이 참조하는 키 계열 전수 검사
	for id in Rules.ACTION_IDS:
		t_key_exists("action.%s.title" % id)
		t_key_exists("action.%s.desc" % id)
		for opt in Rules.action_options(id):
			t_key_exists("option.%s.%s.title" % [id, opt])
			t_key_exists("option.%s.%s.desc" % [id, opt])
	var all_choices := [
		"debt_demand:pay_now", "debt_demand:defer", "debt_demand:velor_support",
		"brothers_conflict:support_aldren", "brothers_conflict:support_rowen", "brothers_conflict:force_reconciliation",
		"decisive_civil_conflict:buy_settlement", "decisive_civil_conflict:power_share", "decisive_civil_conflict:refuse",
		"velor_estate_claim:recognize", "velor_estate_claim:compensate", "velor_estate_claim:reject",
		"beric_regency_demand:accept", "beric_regency_demand:reject", "beric_regency_demand:use_secret",
		"losing_brother_demand:share_income", "losing_brother_demand:court_office", "losing_brother_demand:refuse",
		"velor_pressure:concede_revenue", "velor_pressure:resist", "velor_pressure:fail_to_answer",
	]
	for c in all_choices:
		t_key_exists("choice.%s.title" % c)
		t_key_exists("choice.%s.desc" % c)
	for eid in ["debt_demand", "brothers_conflict", "decisive_civil_conflict",
			"velor_estate_claim", "beric_regency_demand", "losing_brother_demand", "velor_pressure"]:
		t_key_exists("event.%s.title" % eid)
		t_key_exists("event.%s.desc" % eid)
		t_key_exists("event.%s.stakes" % eid)
	for oid in ["stable_aldren", "unstable_aldren", "agreed_rowen", "contested_rowen", "succession_civil_war"]:
		t_key_exists("outcome." + oid)
		t_key_exists("chron.succession_" + oid)
	for rid in ["victory_stable_succession", "victory_fragile_survival", "victory_blood_bought",
			"defeat_no_eligible_heir", "defeat_estate_lost", "defeat_insolvent",
			"defeat_legitimacy_collapse", "defeat_unresolved_civil_war"]:
		t_key_exists("result.%s.title" % rid)
		t_key_exists("result.%s.desc" % rid)
		t_key_exists("chron.terminal_" + rid)
	for rk in ["not_action_phase", "no_action_points", "used_this_turn", "edric_dead",
			"wealth_5", "wealth_6", "wealth_8", "wealth_15", "wealth_20",
			"influence_5", "influence_8", "influence_10", "marriage_done", "secret_known",
			"declaration_used", "aldren_unavailable", "rowen_unavailable", "unknown_action",
			"need_velor_marriage", "need_secret", "not_event_phase", "unknown_choice"]:
		t_key_exists("reason." + rk)
	for ck in ["edric_arven", "myra_arven", "aldren_arven", "rowen_arven", "beric_arven",
			"house_arven", "house_velor", "house_cardin"]:
		t_key_exists("name." + ck)
