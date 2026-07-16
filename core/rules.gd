# 규칙 엔진 — 정본(캐논)의 픽스처/액션/이벤트/승계/종결 규칙을 UI 없이 결정론적으로 실행한다.
class_name Rules

const ALDREN := "aldren_arven"
const ROWEN := "rowen_arven"
const EDRIC := "edric_arven"
const MYRA := "myra_arven"
const BERIC := "beric_arven"

const ACTION_IDS := [
	"educate_aldren", "educate_rowen", "appease_beric", "negotiate_marriage",
	"investigate_secret", "reorganize_estate", "reconcile_brothers", "declare_heir",
]

const DEFEAT_PRIORITY := [
	"defeat_estate_lost", "defeat_insolvent", "defeat_legitimacy_collapse",
	"defeat_no_eligible_heir", "defeat_unresolved_civil_war",
]

# ---------------------------------------------------------------- fixture

static func new_game(seed_value: int) -> SimState:
	var s := SimState.new()
	s.seed_value = seed_value
	s.wealth = 60
	s.debt = 20
	s.legitimacy = 55
	s.influence = 35
	s.cohesion = 45
	s.succession_stability = 35
	s.estate_count = 1
	s.formal_heir_id = ALDREN
	s.current_head_id = EDRIC
	s.turn = 1
	s.action_points = 2
	s.characters = {
		EDRIC: _mk_char(EDRIC, 54 * 12, 30, 90, 55, -1, 35, "house_head"),
		MYRA: _mk_char(MYRA, 47 * 12, 70, 70, 60, 75, 45, "spouse"),
		ALDREN: _mk_char(ALDREN, 18 * 12, 55, 75, 40, 70, 45, "heir"),
		ROWEN: _mk_char(ROWEN, 16 * 12, 80, 45, 70, 50, 80, "son"),
		BERIC: _mk_char(BERIC, 49 * 12, 65, 40, 65, 45, 75, "kin"),
	}
	s.relationships = {}
	s.set_rel(EDRIC, ALDREN, 65)
	s.set_rel(EDRIC, ROWEN, 55)
	s.set_rel(MYRA, ALDREN, 80)
	s.set_rel(MYRA, ROWEN, 65)
	s.set_rel(BERIC, ALDREN, 30)
	s.set_rel(BERIC, ROWEN, 75)
	s.set_rel(ALDREN, ROWEN, 45)
	s.flags = {
		"marriage_partner_house_id": "",
		"marriage_completed": false,
		"velor_intervention_risk": false,
		"beric_secret_known": false,
		"heir_declaration_used": false,
		"civil_war_occurred": false,
		"civil_war_active": false,
		"civil_war_resolved": false,
		"losing_claimant_id": "",
		"regency_active": false,
	}
	s.phase = SimState.PHASE_ACTIONS
	s.record_history("fixture")
	return s

static func _mk_char(id: String, age_months: int, health: int, claim: int,
		ability: int, loyalty: int, ambition: int, role: String) -> Dictionary:
	return {
		"id": id, "age_months": age_months, "alive": true, "in_house": true,
		"health": health, "ability": ability, "legal_claim": claim,
		"loyalty": null if loyalty < 0 else loyalty, "ambition": ambition,
		"role": role, "known_secrets": [],
	}

# ---------------------------------------------------------------- actions

# 각 액션의 전제조건 검사. {ok:bool, reason:String(i18n key)} 반환.
static func action_check(s: SimState, id: String) -> Dictionary:
	if s.phase != SimState.PHASE_ACTIONS:
		return {"ok": false, "reason": "reason.not_action_phase"}
	if s.action_points <= 0:
		return {"ok": false, "reason": "reason.no_action_points"}
	if s.actions_used.has(id):
		return {"ok": false, "reason": "reason.used_this_turn"}
	match id:
		"educate_aldren":
			if not s.chr(EDRIC)["alive"]:
				return {"ok": false, "reason": "reason.edric_dead"}
			if s.wealth < 5:
				return {"ok": false, "reason": "reason.wealth_5"}
		"educate_rowen":
			if not s.chr(EDRIC)["alive"]:
				return {"ok": false, "reason": "reason.edric_dead"}
			if s.wealth < 5:
				return {"ok": false, "reason": "reason.wealth_5"}
		"appease_beric":
			if s.wealth < 8:
				return {"ok": false, "reason": "reason.wealth_8"}
		"negotiate_marriage":
			if s.flags["marriage_completed"]:
				return {"ok": false, "reason": "reason.marriage_done"}
			if s.wealth < 5:
				return {"ok": false, "reason": "reason.wealth_5"}
		"investigate_secret":
			if s.flags["beric_secret_known"]:
				return {"ok": false, "reason": "reason.secret_known"}
			if s.wealth < 6:
				return {"ok": false, "reason": "reason.wealth_6"}
		"reorganize_estate":
			pass
		"reconcile_brothers":
			if s.influence < 5:
				return {"ok": false, "reason": "reason.influence_5"}
			if not (s.chr(ALDREN)["alive"] and s.chr(ALDREN)["in_house"]):
				return {"ok": false, "reason": "reason.aldren_unavailable"}
			if not (s.chr(ROWEN)["alive"] and s.chr(ROWEN)["in_house"]):
				return {"ok": false, "reason": "reason.rowen_unavailable"}
		"declare_heir":
			if not s.chr(EDRIC)["alive"]:
				return {"ok": false, "reason": "reason.edric_dead"}
			if s.flags["heir_declaration_used"]:
				return {"ok": false, "reason": "reason.declaration_used"}
			if s.influence < 10:
				return {"ok": false, "reason": "reason.influence_10"}
		_:
			return {"ok": false, "reason": "reason.unknown_action"}
	return {"ok": true, "reason": ""}

# 액션 옵션(결혼 상대/후계 선언 대상) 목록. 옵션 없는 액션은 [] 반환.
static func action_options(id: String) -> Array:
	match id:
		"negotiate_marriage":
			return ["house_velor", "house_cardin"]
		"declare_heir":
			return [ALDREN, ROWEN]
	return []

# UI 표시용 카탈로그: 비용/효과 설명 키와 활성화 여부.
static func action_catalog(s: SimState) -> Array:
	var out: Array = []
	for id in ACTION_IDS:
		var check := action_check(s, id)
		out.append({
			"id": id,
			"ok": check["ok"],
			"reason": check["reason"],
			"options": action_options(id),
		})
	return out

# 액션 적용. 불법 입력은 상태를 바꾸지 않고 error와 함께 거부한다.
static func apply_action(s: SimState, id: String, option: String = "") -> Dictionary:
	var check := action_check(s, id)
	if not check["ok"]:
		return {"phase": s.phase, "error": check["reason"]}
	var opts := action_options(id)
	if not opts.is_empty() and not (option in opts):
		return {"phase": s.phase, "error": "reason.unknown_choice"}
	s.action_points -= 1
	s.actions_used[id] = true
	match id:
		"educate_aldren":
			s.wealth -= 5
			s.add_char_stat(ALDREN, "ability", 8)
			s.add_char_stat(ALDREN, "legal_claim", 3)
			s.add_rel(EDRIC, ALDREN, 5)
			s.log_entry(EDRIC, "chron.educate_aldren")
		"educate_rowen":
			s.wealth -= 5
			s.add_char_stat(ROWEN, "ability", 6)
			s.add_char_stat(ROWEN, "loyalty", 4)
			s.add_char_stat(ROWEN, "ambition", 3)
			s.add_rel(ALDREN, ROWEN, -3)
			s.log_entry(EDRIC, "chron.educate_rowen")
		"appease_beric":
			s.wealth -= 8
			s.add_char_stat(BERIC, "loyalty", 12)
			s.cohesion += 6
			s.influence -= 2
			s.log_entry(s.current_head_id, "chron.appease_beric")
		"negotiate_marriage":
			s.wealth -= 5
			s.flags["marriage_completed"] = true
			s.flags["marriage_partner_house_id"] = option
			if option == "house_velor":
				s.wealth += 20
				s.influence += 15
				s.legitimacy += 5
				s.flags["velor_intervention_risk"] = true
				s.log_entry(s.current_head_id, "chron.marriage_velor", {}, true)
			else:
				s.influence += 8
				s.cohesion += 8
				s.succession_stability += 5
				s.log_entry(s.current_head_id, "chron.marriage_cardin", {}, true)
		"investigate_secret":
			s.wealth -= 6
			s.flags["beric_secret_known"] = true
			s.add_rel(BERIC, s.current_head_id, -5)
			s.log_entry(s.current_head_id, "chron.investigate_secret", {}, true)
		"reorganize_estate":
			s.wealth += 10
			s.cohesion -= 3
			s.log_entry(s.current_head_id, "chron.reorganize_estate")
		"reconcile_brothers":
			s.influence -= 5
			s.add_rel(ALDREN, ROWEN, 10)
			s.cohesion += 4
			s.add_char_stat(ROWEN, "ambition", -2)
			s.log_entry(s.current_head_id, "chron.reconcile_brothers")
		"declare_heir":
			s.influence -= 10
			s.flags["heir_declaration_used"] = true
			if option == ALDREN:
				s.formal_heir_id = ALDREN
				s.add_char_stat(ALDREN, "legal_claim", 10)
				s.succession_stability += 8
				s.add_char_stat(ROWEN, "loyalty", -8)
				s.add_char_stat(BERIC, "loyalty", -5)
				s.log_entry(EDRIC, "chron.declare_aldren", {}, true)
			else:
				s.formal_heir_id = ROWEN
				s.add_char_stat(ROWEN, "legal_claim", 15)
				s.succession_stability -= 5
				s.add_char_stat(ALDREN, "loyalty", -12)
				s.add_char_stat(MYRA, "loyalty", -10)
				s.add_char_stat(BERIC, "loyalty", 10)
				s.log_entry(EDRIC, "chron.declare_rowen", {}, true)
	s.clamp_all()
	s.record_history("action:" + id + ("" if option == "" else ":" + option))
	if _check_immediate_defeat(s):
		return {"phase": s.phase}
	return {"phase": s.phase}

# ---------------------------------------------------------------- turn flow

# 액션 단계 종료 → 이벤트 단계 진입. 선택형 이벤트면 event 단계에서 대기.
static func end_action_phase(s: SimState) -> Dictionary:
	if s.phase != SimState.PHASE_ACTIONS:
		return {"phase": s.phase, "error": "reason.not_action_phase"}
	return _run_event_phase(s)

static func _run_event_phase(s: SimState) -> Dictionary:
	match s.turn:
		2:
			return _open_event(s, "debt_demand", _debt_demand_choices(s), [EDRIC, MYRA])
		4:
			if s.get_rel(ALDREN, ROWEN) < 50:
				return _open_event(s, "brothers_conflict", _brothers_conflict_choices(s), [ALDREN, ROWEN, EDRIC])
			s.log_entry("house_arven", "chron.brothers_conflict_avoided")
			s.record_history("event:brothers_conflict_avoided")
			return _after_event(s)
		6:
			return _edric_death(s)
		8:
			return _turn8_event(s)
		10:
			return _turn10_event(s)
		_:
			s.record_history("event:none")
			return _after_event(s)

static func _open_event(s: SimState, event_id: String, choices: Array, participants: Array) -> Dictionary:
	s.phase = SimState.PHASE_EVENT
	s.pending_event = {"event_id": event_id, "choices": choices, "participants": participants}
	s.record_history("event_open:" + event_id)
	return {"phase": s.phase}

# 이벤트 선택지 구성 헬퍼: {id, ok, reason}
static func _choice(id: String, ok: bool, reason: String = "") -> Dictionary:
	return {"id": id, "ok": ok, "reason": reason if not ok else ""}

static func _debt_demand_choices(s: SimState) -> Array:
	return [
		_choice("debt_demand:pay_now", s.wealth >= 15, "reason.wealth_15"),
		_choice("debt_demand:defer", true),
		_choice("debt_demand:velor_support",
			s.flags["marriage_partner_house_id"] == "house_velor", "reason.need_velor_marriage"),
	]

static func _brothers_conflict_choices(s: SimState) -> Array:
	return [
		_choice("brothers_conflict:support_aldren", true),
		_choice("brothers_conflict:support_rowen", true),
		_choice("brothers_conflict:force_reconciliation", s.influence >= 8, "reason.influence_8"),
	]

static func event_choice_check(s: SimState, choice_id: String) -> Dictionary:
	if s.phase != SimState.PHASE_EVENT:
		return {"ok": false, "reason": "reason.not_event_phase"}
	for c in s.pending_event["choices"]:
		if c["id"] == choice_id:
			return {"ok": c["ok"], "reason": c["reason"]}
	return {"ok": false, "reason": "reason.unknown_choice"}

static func apply_event_choice(s: SimState, choice_id: String) -> Dictionary:
	var check := event_choice_check(s, choice_id)
	if not check["ok"]:
		return {"phase": s.phase, "error": check["reason"]}
	var event_id: String = s.pending_event["event_id"]
	s.pending_event = {}
	s.phase = SimState.PHASE_ACTIONS  # transient; will be set again below
	match choice_id:
		# --- 12.1 debt_demand ---
		"debt_demand:pay_now":
			s.wealth -= 15
			s.debt = maxi(0, s.debt - 15)
			s.legitimacy += 3
			s.log_entry(s.current_head_id, "chron.debt_pay_now", {}, true)
		"debt_demand:defer":
			s.debt += 10
			s.influence -= 5
			s.log_entry(s.current_head_id, "chron.debt_defer", {}, true)
		"debt_demand:velor_support":
			s.debt = maxi(0, s.debt - 10)
			s.flags["velor_intervention_risk"] = true
			s.succession_stability -= 3
			s.log_entry(s.current_head_id, "chron.debt_velor", {}, true)
		# --- 12.2 brothers_conflict ---
		"brothers_conflict:support_aldren":
			s.add_char_stat(ALDREN, "legal_claim", 5)
			s.add_char_stat(ROWEN, "loyalty", -8)
			s.add_char_stat(BERIC, "loyalty", -5)
			s.log_entry(EDRIC, "chron.conflict_support_aldren", {}, true)
		"brothers_conflict:support_rowen":
			s.add_char_stat(ROWEN, "ability", 5)
			s.add_char_stat(ALDREN, "loyalty", -8)
			s.add_char_stat(MYRA, "loyalty", -5)
			s.log_entry(EDRIC, "chron.conflict_support_rowen", {}, true)
		"brothers_conflict:force_reconciliation":
			s.influence -= 8
			s.add_rel(ALDREN, ROWEN, 8)
			s.cohesion += 3
			s.log_entry(EDRIC, "chron.conflict_force_reconciliation", {}, true)
		# --- 15.1 decisive_civil_conflict ---
		"decisive_civil_conflict:buy_settlement":
			s.wealth -= 20
			s.cohesion += 15
			s.legitimacy += 5
			s.flags["civil_war_active"] = false
			s.flags["civil_war_resolved"] = true
			s.add_char_stat(s.flags["losing_claimant_id"], "loyalty", 10)
			s.log_entry(s.current_head_id, "chron.civil_buy_settlement", {}, true)
		"decisive_civil_conflict:power_share":
			s.influence -= 10
			s.cohesion += 10
			s.succession_stability += 8
			s.add_char_stat(s.flags["losing_claimant_id"], "ambition", 8)
			s.flags["civil_war_active"] = false
			s.flags["civil_war_resolved"] = true
			s.log_entry(s.current_head_id, "chron.civil_power_share", {}, true)
		"decisive_civil_conflict:refuse":
			s.cohesion -= 10
			s.legitimacy -= 10
			var head := s.chr(s.current_head_id)
			var loser := s.chr(s.flags["losing_claimant_id"])
			if int(head["ability"]) + int(head["legal_claim"]) >= int(loser["ability"]) + int(loser["legal_claim"]):
				s.flags["civil_war_active"] = false
				s.flags["civil_war_resolved"] = true
				s.add_char_stat(s.flags["losing_claimant_id"], "loyalty", -20)
				s.log_entry(s.current_head_id, "chron.civil_refuse_won", {}, true)
			else:
				s.estate_count = 0
				s.log_entry(s.current_head_id, "chron.civil_refuse_lost", {}, true)
		# --- 15.2 velor_estate_claim ---
		"velor_estate_claim:recognize":
			s.wealth += 10
			s.influence += 5
			s.legitimacy -= 10
			s.succession_stability -= 5
			s.log_entry(s.current_head_id, "chron.velor_recognize", {}, true)
		"velor_estate_claim:compensate":
			s.wealth -= 20
			s.legitimacy += 5
			s.flags["velor_intervention_risk"] = false
			s.log_entry(s.current_head_id, "chron.velor_compensate", {}, true)
		"velor_estate_claim:reject":
			s.influence -= 10
			s.flags["velor_intervention_risk"] = true
			s.log_entry(s.current_head_id, "chron.velor_reject", {}, true)
		# --- 15.3 beric_regency_demand ---
		"beric_regency_demand:accept":
			s.flags["regency_active"] = true
			s.succession_stability += 10
			s.add_char_stat(BERIC, "loyalty", 10)
			s.influence -= 5
			s.log_entry(BERIC, "chron.regency_accept", {}, true)
		"beric_regency_demand:reject":
			s.cohesion -= 10
			s.add_char_stat(BERIC, "loyalty", -15)
			s.legitimacy += 5
			s.log_entry(s.current_head_id, "chron.regency_reject", {}, true)
		"beric_regency_demand:use_secret":
			s.flags["regency_active"] = false
			s.add_char_stat(BERIC, "loyalty", -10)
			s.influence -= 5
			s.cohesion -= 5
			s.log_entry(s.current_head_id, "chron.regency_secret", {}, true)
		# --- 15.4 losing_brother_demand ---
		"losing_brother_demand:share_income":
			s.wealth -= 10
			s.add_char_stat(s.flags["losing_claimant_id"], "loyalty", 15)
			s.cohesion += 5
			s.log_entry(s.current_head_id, "chron.brother_share_income", {}, true)
		"losing_brother_demand:court_office":
			s.influence -= 8
			s.add_char_stat(s.flags["losing_claimant_id"], "loyalty", 10)
			s.add_char_stat(s.flags["losing_claimant_id"], "ambition", 5)
			s.log_entry(s.current_head_id, "chron.brother_court_office", {}, true)
		"losing_brother_demand:refuse":
			s.legitimacy += 3
			s.add_char_stat(s.flags["losing_claimant_id"], "loyalty", -15)
			s.succession_stability -= 8
			s.log_entry(s.current_head_id, "chron.brother_refuse", {}, true)
		# --- 16.2 velor_pressure ---
		"velor_pressure:concede_revenue":
			s.wealth -= 15
			s.flags["velor_intervention_risk"] = false
			s.succession_stability += 5
			s.log_entry(s.current_head_id, "chron.pressure_concede", {}, true)
		"velor_pressure:resist":
			s.influence -= 10
			s.legitimacy += 5
			s.flags["velor_intervention_risk"] = false
			s.log_entry(s.current_head_id, "chron.pressure_resist", {}, true)
		"velor_pressure:fail_to_answer":
			s.estate_count = 0
			s.log_entry(s.current_head_id, "chron.pressure_fail", {}, true)
		_:
			assert(false, "unhandled choice: " + choice_id)
	s.clamp_all()
	s.record_history("choice:" + choice_id)
	if _check_immediate_defeat(s):
		return {"phase": s.phase}
	return _after_event(s)

# 이벤트 이후 파이프라인: 업킵 → 종결 검사 → 턴 진행 (정본 10.4/10.5).
static func _after_event(s: SimState) -> Dictionary:
	# END_OF_TURN_UPKEEP
	for id in s.characters:
		if s.characters[id]["alive"]:
			s.characters[id]["age_months"] = int(s.characters[id]["age_months"]) + 6
	if s.debt > 0 and s.turn % 2 == 0:
		s.debt += 2
	s.clamp_all()
	s.record_history("upkeep")
	if _check_immediate_defeat(s):
		return {"phase": s.phase}
	# TERMINAL_CHECK — final victory only on turn 12 after upkeep
	if s.turn >= 12:
		_final_judgment(s)
		return {"phase": s.phase}
	# ADVANCE_TURN
	s.turn += 1
	s.action_points = 2
	s.actions_used = {}
	s.phase = SimState.PHASE_ACTIONS
	s.record_history("turn_start")
	return {"phase": s.phase}

# ---------------------------------------------------------------- turn 6

static func _edric_death(s: SimState) -> Dictionary:
	s.chr(EDRIC)["alive"] = false
	s.chr(EDRIC)["role"] = "deceased_head"
	s.log_entry(EDRIC, "chron.edric_death", {}, true)
	_run_succession(s)
	s.phase = SimState.PHASE_SUCCESSION
	s.record_history("succession:" + s.succession_outcome_id)
	return {"phase": s.phase}

# 승계 화면에서 확인 후 턴 6 잔여 파이프라인 계속.
static func continue_after_succession(s: SimState) -> Dictionary:
	if s.phase != SimState.PHASE_SUCCESSION:
		return {"phase": s.phase, "error": "reason.not_event_phase"}
	s.phase = SimState.PHASE_ACTIONS  # transient
	if _check_immediate_defeat(s):
		return {"phase": s.phase}
	return _after_event(s)

# ---------------------------------------------------------------- succession (canon 13/14)

static func _run_succession(s: SimState) -> void:
	var ev: Dictionary = {"candidates": {}, "beric": {}, "tiebreaker_used": false, "changes": []}
	# 검증용 입력 스냅샷 — 점수는 반드시 이 값들만으로 재계산 가능해야 한다.
	ev["inputs"] = {
		"aldren_claim": int(s.chr(ALDREN)["legal_claim"]),
		"aldren_ability": int(s.chr(ALDREN)["ability"]),
		"rowen_claim": int(s.chr(ROWEN)["legal_claim"]),
		"rowen_ability": int(s.chr(ROWEN)["ability"]),
		"rowen_ambition": int(s.chr(ROWEN)["ambition"]),
		"myra_loyalty": s.chr(MYRA)["loyalty"],
		"beric_loyalty": s.chr(BERIC)["loyalty"],
		"aldren_loyalty": s.chr(ALDREN)["loyalty"],
		"brothers_rel": s.get_rel(ALDREN, ROWEN),
		"formal_heir_id": s.formal_heir_id,
		"cohesion": s.cohesion,
		"beric_secret_known": s.flags["beric_secret_known"],
	}
	# 13.1 Aldren
	var a := s.chr(ALDREN)
	var a_parts: Array = [{"key": "score.base", "value": 40}]
	var a_score := 40
	var v := int(floor(int(a["legal_claim"]) * 0.30))
	a_score += v
	a_parts.append({"key": "score.legal_claim", "value": v})
	v = int(floor(int(a["ability"]) * 0.10))
	a_score += v
	a_parts.append({"key": "score.ability", "value": v})
	if s.chr(MYRA)["loyalty"] != null and int(s.chr(MYRA)["loyalty"]) >= 60:
		a_score += 10
		a_parts.append({"key": "score.myra_support", "value": 10})
	if s.formal_heir_id == ALDREN:
		a_score += 15
		a_parts.append({"key": "score.formal_heir", "value": 15})
	if s.get_rel(ALDREN, ROWEN) >= 50:
		a_score += 5
		a_parts.append({"key": "score.brother_bond", "value": 5})
	# 13.2 Rowen
	var r := s.chr(ROWEN)
	var r_parts: Array = [{"key": "score.base", "value": 20}]
	var r_score := 20
	v = int(floor(int(r["legal_claim"]) * 0.30))
	r_score += v
	r_parts.append({"key": "score.legal_claim", "value": v})
	v = int(floor(int(r["ability"]) * 0.20))
	r_score += v
	r_parts.append({"key": "score.ability", "value": v})
	if s.chr(BERIC)["loyalty"] != null and int(s.chr(BERIC)["loyalty"]) >= 60:
		r_score += 15
		r_parts.append({"key": "score.beric_support", "value": 15})
	if s.formal_heir_id == ROWEN:
		r_score += 20
		r_parts.append({"key": "score.formal_heir", "value": 20})
	if int(r["ambition"]) >= 75:
		r_score += 5
		r_parts.append({"key": "score.ambition", "value": 5})
	# 13.3 Beric modifier — exactly one branch
	var beric_loyalty := int(s.chr(BERIC)["loyalty"])
	var beric_branch := "none"
	if beric_loyalty >= 70:
		s.succession_stability += 5
		beric_branch = "loyal"
		ev["changes"].append({"key": "change.stability", "value": 5})
	elif beric_loyalty < 50 and not s.flags["beric_secret_known"]:
		r_score += 10
		s.succession_stability -= 10
		beric_branch = "hostile_hidden"
		r_parts.append({"key": "score.beric_scheme", "value": 10})
		ev["changes"].append({"key": "change.stability", "value": -10})
	elif beric_loyalty < 50 and s.flags["beric_secret_known"]:
		r_score += 5
		s.succession_stability -= 5
		beric_branch = "hostile_checked"
		r_parts.append({"key": "score.beric_scheme", "value": 5})
		ev["changes"].append({"key": "change.stability", "value": -5})
	ev["beric"] = {"branch": beric_branch, "loyalty": beric_loyalty, "secret_known": s.flags["beric_secret_known"]}
	ev["candidates"][ALDREN] = {"total": a_score, "parts": a_parts}
	ev["candidates"][ROWEN] = {"total": r_score, "parts": r_parts}
	s.clamp_all()
	# 13.4 tie-breaker
	var winner := ""
	if a_score > r_score:
		winner = ALDREN
	elif r_score > a_score:
		winner = ROWEN
	else:
		ev["tiebreaker_used"] = true
		if s.formal_heir_id == ALDREN or s.formal_heir_id == ROWEN:
			winner = s.formal_heir_id
		else:
			winner = ALDREN
	var loser: String = ROWEN if winner == ALDREN else ALDREN
	# 14.1 civil war first
	var cohesion_at_succession := s.cohesion
	ev["civil_war_check"] = {"diff": absi(a_score - r_score), "cohesion": cohesion_at_succession}
	if absi(a_score - r_score) <= 5 and cohesion_at_succession < 35:
		s.succession_outcome_id = "succession_civil_war"
		s.flags["civil_war_occurred"] = true
		s.flags["civil_war_active"] = true
		s.flags["civil_war_resolved"] = false
		s.wealth -= 20
		s.influence -= 10
		s.current_head_id = winner
		s.flags["losing_claimant_id"] = loser
		s.chr(winner)["role"] = "provisional_head"
		s.chr(loser)["role"] = "claimant"
		ev["changes"].append({"key": "change.wealth", "value": -20})
		ev["changes"].append({"key": "change.influence", "value": -10})
	elif winner == ALDREN and a_score - r_score >= 15 and int(a["legal_claim"]) >= 65 and cohesion_at_succession >= 40:
		s.succession_outcome_id = "stable_aldren"
		s.current_head_id = ALDREN
		s.flags["losing_claimant_id"] = ROWEN
		s.legitimacy += 10
		s.succession_stability += 15
		s.add_char_stat(ROWEN, "loyalty", -5)
		ev["changes"].append({"key": "change.legitimacy", "value": 10})
		ev["changes"].append({"key": "change.stability", "value": 15})
		ev["changes"].append({"key": "change.rowen_loyalty", "value": -5})
		_common_succession_updates(s)
	elif winner == ALDREN:
		s.succession_outcome_id = "unstable_aldren"
		s.current_head_id = ALDREN
		s.flags["losing_claimant_id"] = ROWEN
		s.succession_stability -= 5
		s.add_char_stat(ROWEN, "ambition", 10)
		s.add_char_stat(BERIC, "loyalty", -10)
		ev["changes"].append({"key": "change.stability", "value": -5})
		ev["changes"].append({"key": "change.rowen_ambition", "value": 10})
		ev["changes"].append({"key": "change.beric_loyalty", "value": -10})
		_common_succession_updates(s)
	elif winner == ROWEN and s.formal_heir_id == ROWEN and cohesion_at_succession >= 50 \
			and s.chr(ALDREN)["loyalty"] != null and int(s.chr(ALDREN)["loyalty"]) >= 45:
		s.succession_outcome_id = "agreed_rowen"
		s.current_head_id = ROWEN
		s.flags["losing_claimant_id"] = ALDREN
		s.legitimacy -= 5
		ev["changes"].append({"key": "change.legitimacy", "value": -5})
		_common_succession_updates(s)
	else:
		s.succession_outcome_id = "contested_rowen"
		s.current_head_id = ROWEN
		s.flags["losing_claimant_id"] = ALDREN
		s.legitimacy -= 15
		s.cohesion -= 15
		ev["changes"].append({"key": "change.legitimacy", "value": -15})
		ev["changes"].append({"key": "change.cohesion", "value": -15})
		_common_succession_updates(s)
	s.clamp_all()
	ev["outcome_id"] = s.succession_outcome_id
	ev["winner"] = s.current_head_id
	ev["loser"] = s.flags["losing_claimant_id"]
	s.succession_evidence = ev
	s.log_entry(s.current_head_id, "chron.succession_" + s.succession_outcome_id, {}, true)

# 정본 14.6 — 내전 외 승계 공통 갱신.
static func _common_succession_updates(s: SimState) -> void:
	s.chr(s.current_head_id)["role"] = "house_head"
	s.chr(s.flags["losing_claimant_id"])["role"] = "claimant"
	s.formal_heir_id = ""

# ---------------------------------------------------------------- turn 8 (canon 15)

static func _turn8_event(s: SimState) -> Dictionary:
	var losing: String = s.flags["losing_claimant_id"]
	if s.flags["civil_war_active"] and not s.flags["civil_war_resolved"]:
		return _open_event(s, "decisive_civil_conflict", [
			_choice("decisive_civil_conflict:buy_settlement", s.wealth >= 20, "reason.wealth_20"),
			_choice("decisive_civil_conflict:power_share", s.influence >= 10, "reason.influence_10"),
			_choice("decisive_civil_conflict:refuse", true),
		], [s.current_head_id, losing, BERIC])
	if s.flags["velor_intervention_risk"] and s.flags["marriage_partner_house_id"] == "house_velor" \
			and s.succession_stability < 40:
		return _open_event(s, "velor_estate_claim", [
			_choice("velor_estate_claim:recognize", true),
			_choice("velor_estate_claim:compensate", s.wealth >= 20, "reason.wealth_20"),
			_choice("velor_estate_claim:reject", true),
		], [s.current_head_id])
	if int(s.chr(s.current_head_id)["age_months"]) < 240 \
			and s.chr(BERIC)["loyalty"] != null and int(s.chr(BERIC)["loyalty"]) < 60:
		return _open_event(s, "beric_regency_demand", [
			_choice("beric_regency_demand:accept", true),
			_choice("beric_regency_demand:reject", true),
			_choice("beric_regency_demand:use_secret", s.flags["beric_secret_known"], "reason.need_secret"),
		], [BERIC, s.current_head_id])
	if losing != "" and s.chr(losing)["alive"] and s.chr(losing)["in_house"] \
			and s.chr(losing)["loyalty"] != null and int(s.chr(losing)["loyalty"]) < 45:
		return _open_event(s, "losing_brother_demand", [
			_choice("losing_brother_demand:share_income", true),
			_choice("losing_brother_demand:court_office", true),
			_choice("losing_brother_demand:refuse", true),
		], [losing, s.current_head_id])
	if s.flags["marriage_partner_house_id"] == "house_cardin":
		s.cohesion += 8
		s.succession_stability += 8
		s.influence -= 3
		s.clamp_all()
		s.log_entry("house_cardin", "chron.cardin_mediation", {}, true)
		s.record_history("event:cardin_mediation")
		if _check_immediate_defeat(s):
			return {"phase": s.phase}
		return _after_event(s)
	s.legitimacy += 3
	s.succession_stability += 5
	s.clamp_all()
	s.log_entry(s.current_head_id, "chron.quiet_consolidation")
	s.record_history("event:quiet_consolidation")
	if _check_immediate_defeat(s):
		return {"phase": s.phase}
	return _after_event(s)

# ---------------------------------------------------------------- turn 10 (canon 16)

static func _turn10_event(s: SimState) -> Dictionary:
	var losing: String = s.flags["losing_claimant_id"]
	if losing != "" and s.chr(losing)["in_house"] \
			and s.chr(losing)["loyalty"] != null and int(s.chr(losing)["loyalty"]) <= 20:
		s.chr(losing)["in_house"] = false
		s.cohesion -= 10
		s.succession_stability -= 10
		s.clamp_all()
		s.log_entry(losing, "chron.claimant_departure", {}, true)
		s.record_history("event:claimant_departure")
		if _check_immediate_defeat(s):
			return {"phase": s.phase}
		return _after_event(s)
	if s.flags["velor_intervention_risk"]:
		return _open_event(s, "velor_pressure", [
			_choice("velor_pressure:concede_revenue", true),
			_choice("velor_pressure:resist", s.influence >= 10, "reason.influence_10"),
			_choice("velor_pressure:fail_to_answer", true),
		], [s.current_head_id])
	if s.cohesion < 30:
		s.wealth -= 10
		s.legitimacy -= 10
		s.succession_stability -= 10
		s.clamp_all()
		s.log_entry("house_arven", "chron.kin_revolt", {}, true)
		s.record_history("event:kin_revolt")
		if _check_immediate_defeat(s):
			return {"phase": s.phase}
		return _after_event(s)
	if int(s.chr(s.current_head_id)["ability"]) < 55 or s.debt >= 40:
		s.wealth -= 10
		s.debt += 5
		s.legitimacy -= 5
		s.clamp_all()
		s.log_entry("house_arven", "chron.tax_resistance", {}, true)
		s.record_history("event:tax_resistance")
		if _check_immediate_defeat(s):
			return {"phase": s.phase}
		return _after_event(s)
	s.wealth += 15
	s.legitimacy += 5
	s.succession_stability += 5
	s.clamp_all()
	s.log_entry(s.current_head_id, "chron.estate_success", {}, true)
	s.record_history("event:estate_success")
	return _after_event(s)

# ---------------------------------------------------------------- terminal (canon 17)

# 즉시 패배 검사. 패배 시 true를 반환하고 상태를 종결한다.
static func _check_immediate_defeat(s: SimState) -> bool:
	if s.terminal_result_id != "":
		return true
	var result := ""
	if s.estate_count <= 0:
		result = "defeat_estate_lost"
	elif s.wealth <= -10:
		# 정본 0.4.1 밸런스 개정: -30 → -10 (합법 도달 불가 증명에 따른 최소 변경)
		result = "defeat_insolvent"
	elif s.legitimacy <= 0:
		result = "defeat_legitimacy_collapse"
	elif s.turn >= 6 and s.eligible_next_heir_id() == "":
		result = "defeat_no_eligible_heir"
	elif s.turn == 12 and s.flags["civil_war_active"]:
		result = ""  # only checked at final judgment per canon ordering
	if result != "":
		_terminate(s, result)
		return true
	return false

static func _final_judgment(s: SimState) -> void:
	if s.terminal_result_id != "":
		return
	# defeat checks in canon priority
	var result := ""
	if s.estate_count <= 0:
		result = "defeat_estate_lost"
	elif s.wealth <= -10:
		result = "defeat_insolvent"
	elif s.legitimacy <= 0:
		result = "defeat_legitimacy_collapse"
	elif s.eligible_next_heir_id() == "":
		result = "defeat_no_eligible_heir"
	elif s.flags["civil_war_active"]:
		result = "defeat_unresolved_civil_war"
	if result != "":
		_terminate(s, result)
		return
	# 17.3 basic victory
	var basic: bool = s.chr(s.current_head_id)["alive"] and s.estate_count >= 1 \
		and s.eligible_next_heir_id() != "" and s.legitimacy >= 1 and s.wealth > -20 \
		and not s.flags["civil_war_active"]
	if not basic:
		# 방어 코드: 파산 임계 -10에서는 basic 실패가 항상 위 패배 검사에 걸리므로 도달 불가.
		_terminate(s, "defeat_insolvent")
		return
	if s.flags["civil_war_occurred"] and s.flags["civil_war_resolved"]:
		_terminate(s, "victory_blood_bought")
	elif s.legitimacy >= 65 and s.cohesion >= 60 and s.succession_stability >= 65 and s.wealth >= 40:
		_terminate(s, "victory_stable_succession")
	else:
		_terminate(s, "victory_fragile_survival")

static func _terminate(s: SimState, result_id: String) -> void:
	s.terminal_result_id = result_id
	s.phase = SimState.PHASE_OVER
	s.pending_event = {}
	s.log_entry("house_arven", "chron.terminal_" + result_id, {}, true)
	s.record_history("terminal:" + result_id)

# ---------------------------------------------------------------- UI helpers

# 집무실에 표시할 '알려진 다가올 사건' 목록.
static func upcoming_events(s: SimState) -> Array:
	var out: Array = []
	if s.turn <= 2:
		out.append({"turn": 2, "key": "upcoming.debt_demand", "certain": true})
	if s.turn <= 4 and s.get_rel(ALDREN, ROWEN) < 50:
		out.append({"turn": 4, "key": "upcoming.brothers_conflict", "certain": false})
	if s.turn <= 6 and s.chr(EDRIC)["alive"]:
		out.append({"turn": 6, "key": "upcoming.edric_death", "certain": true})
	if s.turn > 6 and s.turn <= 8:
		out.append({"turn": 8, "key": "upcoming.post_succession", "certain": true})
	if s.turn > 8 and s.turn <= 10:
		out.append({"turn": 10, "key": "upcoming.regime_test", "certain": true})
	if s.turn <= 12:
		out.append({"turn": 12, "key": "upcoming.final_judgment", "certain": true})
	return out
