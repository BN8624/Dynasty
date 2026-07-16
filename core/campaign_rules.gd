# 3세대 캠페인 규칙 엔진 — 가족 생성/행동/딜레마/기억/감정/랭크/승계/유산을 UI 없이 결정론적으로 실행한다.
class_name CampaignRules

# ---------------------------------------------------------------- 밸런스 (가변)

const GEN_MIN_TURNS := 8    # 승계는 이 턴 이전에 발생하지 않는다.
const GEN_MAX_TURNS := 14   # 이 턴에 도달하면 승계가 강제된다.

const EXT_HOUSES := ["house_cardin", "house_velor", "house_ostren"]

const ACTION_IDS := [
	"educate", "arrange_marriage", "appease", "reorganize_estate", "court_favor",
	"declare_heir", "reconcile", "grant_estate", "petition_rank", "settle_debt", "abdicate",
]

const DILEMMA_STRUCTURES := [
	"competing_heirs", "marriage_obligation", "branch_claim", "property_division",
	"regency_overreach", "disloyal_kin", "exile_return", "rescue_house",
	"royal_levy", "recovery_offer", "legal_vs_emotional",
]

const NAME_POOL_M := [
	"aldric", "berin", "corvan", "doran", "edwin", "farren", "gareth", "halden",
	"ivo", "joren", "kester", "lorin", "merek", "noral", "osric", "perrin",
	"quill", "roswald", "seric", "tavan", "ulric", "vance", "wystan", "yorick",
]
const NAME_POOL_F := [
	"adela", "brenna", "cyra", "delia", "elin", "fiora", "gwena", "helena",
	"ilsa", "jonet", "katrin", "lyra", "mirel", "nessa", "odila", "petra",
	"rhona", "sabine", "tilda", "una", "verena", "wilma", "ysolde", "zanna",
]

# ---------------------------------------------------------------- 픽스처

static func new_campaign(seed_value: int) -> CampaignState:
	var s := CampaignState.new()
	s.rng_seed(seed_value)
	s.wealth = 55
	s.debt = 15
	s.legitimacy = 55
	s.influence = 40
	s.cohesion = 50
	s.succession_stability = 40
	s.rank = 1
	s.action_points = 2
	s.turn = 1
	s.global_turn = 1
	s.generation = 1
	s.estates = {
		"estate_hall": {"id": "estate_hall", "owner": "main"},
		"estate_river": {"id": "estate_river", "owner": "main"},
	}
	s.ext_standing = {"house_cardin": 55, "house_velor": 45, "house_ostren": 30}
	s.flags = {
		"heir_declared": false,
		"petition_used": false,
		"obligation_house": "",
		"royal_levy_due": false,
		"levy_refused": false,
		"proud_refusal": false,
		"crisis_counter": 0,
		"continuity_broken": false,
	}
	_generate_founding_family(s)
	s.phase = CampaignState.PHASE_ACTIONS
	s.log_entry(s.current_head_id, "chron.camp_founded", {}, true)
	s.record_history("campaign_fixture")
	return s

static func _pick_name(s: CampaignState, gender: String) -> String:
	var pool: Array = NAME_POOL_M if gender == "m" else NAME_POOL_F
	var start := s.rng_roll(pool.size())
	for i in range(pool.size()):
		var n: String = pool[(start + i) % pool.size()]
		var key := "cname." + n
		if not s.used_names.has(key):
			s.used_names[key] = true
			return key
	# 풀 고갈 시 재사용(세대가 다르므로 허용).
	return "cname." + pool[start]

static func _mk_char(s: CampaignState, gender: String, age_y: int, health: int, ability: int,
		claim: int, loyalty: int, ambition: int, role: String,
		father: String = "", mother: String = "") -> String:
	var id := s.new_id("c")
	s.characters[id] = {
		"id": id, "name_key": _pick_name(s, gender), "gender": gender,
		"age_months": age_y * 12 + s.rng_roll(12), "alive": true, "in_house": true,
		"exiled": false, "disinherited": false, "former_head": false,
		"health": health, "ability": ability, "legal_claim": claim,
		"loyalty": null if loyalty < 0 else loyalty, "ambition": ambition,
		"role": role, "generation_born": s.generation,
		"father_id": father, "mother_id": mother, "spouse_id": "", "branch_id": "",
	}
	return id

static func _generate_founding_family(s: CampaignState) -> void:
	var head := _mk_char(s, "m" if s.rng_roll(2) == 0 else "f", 48 + s.rng_roll(5),
		55 + s.rng_roll(20), 50 + s.rng_roll(25), 90, -1, 40 + s.rng_roll(30), "house_head")
	s.current_head_id = head
	var hg: String = s.chr(head)["gender"]
	var spouse := _mk_char(s, "f" if hg == "m" else "m", 44 + s.rng_roll(5),
		60 + s.rng_roll(20), 45 + s.rng_roll(25), 0, 60 + s.rng_roll(20), 35 + s.rng_roll(25), "spouse")
	s.chr(head)["spouse_id"] = spouse
	s.chr(spouse)["spouse_id"] = head
	s.marriages.append({"a": head, "b": spouse, "house_id": "house_cardin", "generation": 0, "forced": false})
	# 자녀 2~4명 — 나이/능력/야심이 다른 상속 후보군.
	var n_children := 2 + s.rng_roll(3)
	var age := 20 + s.rng_roll(5)
	for i in range(n_children):
		var claim := 55 - i * 12 + s.rng_roll(8)
		var cid := _mk_char(s, "m" if s.rng_roll(2) == 0 else "f", age,
			60 + s.rng_roll(25), 35 + s.rng_roll(30), claim,
			45 + s.rng_roll(30), 35 + s.rng_roll(45), "child", head, spouse)
		age -= 2 + s.rng_roll(3)
		s.set_rel(head, cid, 45 + s.rng_roll(30))
		s.set_rel(spouse, cid, 55 + s.rng_roll(25))
	# 가주의 형제(방계 위험 요인).
	var kin := _mk_char(s, "m" if s.rng_roll(2) == 0 else "f", 44 + s.rng_roll(4),
		55 + s.rng_roll(20), 45 + s.rng_roll(25), 25, 40 + s.rng_roll(25), 55 + s.rng_roll(30), "kin")
	s.flags["founder_collateral_id"] = kin
	s.set_rel(head, kin, 40 + s.rng_roll(25))
	# 형제간 관계.
	var kids := s.children_of(head)
	for i in range(kids.size()):
		for j in range(i + 1, kids.size()):
			s.set_rel(kids[i], kids[j], 35 + s.rng_roll(35))
		s.set_rel(kin, kids[i], 40 + s.rng_roll(25))

# ---------------------------------------------------------------- 행동

static func action_check(s: CampaignState, id: String) -> Dictionary:
	if s.phase != CampaignState.PHASE_ACTIONS:
		return {"ok": false, "reason": "reason.not_action_phase"}
	if s.action_points <= 0:
		return {"ok": false, "reason": "reason.no_action_points"}
	if s.actions_used.has(id):
		return {"ok": false, "reason": "reason.used_this_turn"}
	match id:
		"educate":
			if s.wealth < 5:
				return {"ok": false, "reason": "reason.wealth_5"}
			if action_options(s, id).is_empty():
				return {"ok": false, "reason": "reason.no_valid_target"}
		"arrange_marriage":
			if s.wealth < 6:
				return {"ok": false, "reason": "reason.wealth_6"}
			if action_options(s, id).is_empty():
				return {"ok": false, "reason": "reason.no_valid_target"}
		"appease":
			if s.wealth < 8:
				return {"ok": false, "reason": "reason.wealth_8"}
			if action_options(s, id).is_empty():
				return {"ok": false, "reason": "reason.no_valid_target"}
		"reorganize_estate":
			pass
		"court_favor":
			if s.wealth < 8:
				return {"ok": false, "reason": "reason.wealth_8"}
		"declare_heir":
			if s.flags["heir_declared"]:
				return {"ok": false, "reason": "reason.declaration_used"}
			if s.influence < 10:
				return {"ok": false, "reason": "reason.influence_10"}
			if action_options(s, id).is_empty():
				return {"ok": false, "reason": "reason.no_valid_target"}
		"reconcile":
			if s.influence < 5:
				return {"ok": false, "reason": "reason.influence_5"}
			if action_options(s, id).is_empty():
				return {"ok": false, "reason": "reason.no_valid_target"}
		"grant_estate":
			if s.main_estate_ids().size() < 2:
				return {"ok": false, "reason": "reason.need_spare_estate"}
			if action_options(s, id).is_empty():
				return {"ok": false, "reason": "reason.no_valid_target"}
		"petition_rank":
			if s.rank >= 2:
				return {"ok": false, "reason": "reason.rank_at_top"}
			if s.flags["petition_used"]:
				return {"ok": false, "reason": "reason.petition_used"}
			if s.rank == 1:
				if s.legitimacy < 60 or s.influence < 55 or s.wealth < 40:
					return {"ok": false, "reason": "reason.petition_threshold"}
			else:
				if s.legitimacy < 40 or s.influence < 35 or s.wealth < 25:
					return {"ok": false, "reason": "reason.petition_threshold_low"}
		"settle_debt":
			if s.debt <= 0:
				return {"ok": false, "reason": "reason.no_debt"}
			if s.wealth < 10:
				return {"ok": false, "reason": "reason.wealth_10"}
		"abdicate":
			if s.turn < GEN_MIN_TURNS:
				return {"ok": false, "reason": "reason.too_early_abdicate"}
			if _succession_candidates(s).is_empty():
				return {"ok": false, "reason": "reason.no_valid_target"}
		_:
			return {"ok": false, "reason": "reason.unknown_action"}
	return {"ok": true, "reason": ""}

# 대상 선택형 행동의 옵션 목록. 옵션 없는 행동은 [] 반환.
static func action_options(s: CampaignState, id: String) -> Array:
	var out: Array = []
	match id:
		"educate":
			for cid in s.children_of(s.current_head_id):
				if s.alive_in_house(cid) and s.chr(cid)["branch_id"] == "" and s.age_years(cid) >= 6 and s.age_years(cid) <= 25:
					out.append(cid)
		"arrange_marriage":
			var houses: Array = ["house_cardin"]
			if s.rank >= 1:
				houses.append("house_velor")
			if s.rank >= 2:
				houses.append("house_ostren")
			for cid in s.sorted_char_ids():
				var c: Dictionary = s.chr(cid)
				if c["alive"] and c["in_house"] and c["branch_id"] == "" and c["spouse_id"] == "" \
						and s.is_adult(cid) and not c["exiled"]:
					for h in houses:
						out.append(cid + "|" + h)
		"appease":
			for cid in s.sorted_char_ids():
				var c: Dictionary = s.chr(cid)
				if c["alive"] and c["in_house"] and cid != s.current_head_id \
						and c["loyalty"] != null and int(c["loyalty"]) < 65:
					out.append(cid)
		"declare_heir":
			for cid in _succession_candidates(s):
				out.append(cid)
		"reconcile":
			var members: Array = []
			for cid in s.sorted_char_ids():
				if s.alive_in_house(cid) and s.is_adult(cid):
					members.append(cid)
			for i in range(members.size()):
				for j in range(i + 1, members.size()):
					if s.get_rel(members[i], members[j]) < 45 and out.size() < 4:
						out.append(members[i] + "|" + members[j])
		"grant_estate":
			for cid in s.sorted_char_ids():
				var c: Dictionary = s.chr(cid)
				if c["alive"] and c["in_house"] and cid != s.current_head_id \
						and c["branch_id"] == "" and s.is_adult(cid) and not c["disinherited"] \
						and cid != s.formal_heir_id \
						and (int(c["legal_claim"]) >= 20 or not s.claim_of(cid, "succession").is_empty()):
					out.append(cid)
	return out

static func action_catalog(s: CampaignState) -> Array:
	var out: Array = []
	for id in ACTION_IDS:
		var check := action_check(s, id)
		out.append({
			"id": id, "ok": check["ok"], "reason": check["reason"],
			"options": action_options(s, id),
		})
	return out

static func apply_action(s: CampaignState, id: String, option: String = "") -> Dictionary:
	var check := action_check(s, id)
	if not check["ok"]:
		return {"phase": s.phase, "error": check["reason"]}
	var opts := action_options(s, id)
	if not opts.is_empty() and not (option in opts):
		return {"phase": s.phase, "error": "reason.unknown_choice"}
	s.action_points -= 1
	s.actions_used[id] = true
	s.input_log.append("A:%s:%s" % [id, option])
	var head := s.current_head_id
	match id:
		"educate":
			s.wealth -= 5
			s.add_char_stat(option, "ability", 7)
			s.add_char_stat(option, "legal_claim", 2)
			s.add_rel(head, option, 4)
			s.log_entry(head, "chron.camp_educate", {"child": option})
		"arrange_marriage":
			_do_marriage(s, option.get_slice("|", 0), option.get_slice("|", 1), false)
		"appease":
			s.wealth -= 8
			s.add_char_stat(option, "loyalty", 12)
			s.cohesion += 3
			s.log_entry(head, "chron.camp_appease", {"kin": option})
		"reorganize_estate":
			s.wealth += 10
			s.cohesion -= 3
			s.log_entry(head, "chron.camp_reorganize")
		"court_favor":
			s.wealth -= 8
			s.influence += 8
			s.legitimacy += 2
			s.ext_standing["house_ostren"] = int(s.ext_standing["house_ostren"]) + 6
			s.log_entry(head, "chron.camp_court_favor")
		"declare_heir":
			s.influence -= 10
			s.flags["heir_declared"] = true
			s.formal_heir_id = option
			s.add_char_stat(option, "legal_claim", 12)
			s.succession_stability += 6
			# 최강 경쟁자에게 질투를 남긴다.
			var rival := _strongest_rival(s, option)
			if rival != "":
				s.add_char_stat(rival, "loyalty", -6)
				s.add_emotion(rival, "jealousy", option, 35, "chron.camp_declare_heir")
			s.log_entry(head, "chron.camp_declare_heir", {"heir": option}, true)
		"reconcile":
			s.influence -= 5
			var a := option.get_slice("|", 0)
			var b := option.get_slice("|", 1)
			s.add_rel(a, b, 12)
			s.cohesion += 3
			s.log_entry(head, "chron.camp_reconcile", {"a": a, "b": b})
		"grant_estate":
			_found_branch(s, option, "chron.camp_grant_estate")
		"petition_rank":
			s.flags["petition_used"] = true
			if s.rank == 1:
				s.wealth -= 20
				s.influence -= 15
				_change_rank(s, 1, "rank.petition")
			else:
				s.wealth -= 15
				s.influence -= 10
				_change_rank(s, 1, "rank.recovery_petition")
		"settle_debt":
			s.wealth -= 10
			s.debt = maxi(0, s.debt - 15)
			s.log_entry(head, "chron.camp_settle_debt")
		"abdicate":
			s.clamp_all()
			s.record_history("action:abdicate")
			s.log_entry(head, "chron.camp_abdicate", {}, true)
			s.chr(head)["role"] = "abdicated_head"
			if s.formal_heir_id == "":
				s.succession_stability -= 10
			else:
				s.succession_stability += 5
			_run_succession(s, "abdication")
			return {"phase": s.phase}
	s.clamp_all()
	s.record_history("action:" + id + ("" if option == "" else ":" + option))
	return {"phase": s.phase}

static func _strongest_rival(s: CampaignState, exclude: String) -> String:
	var best := ""
	var best_claim := -1
	for cid in _succession_candidates(s):
		if cid == exclude:
			continue
		var cl := int(s.chr(cid)["legal_claim"])
		if cl > best_claim:
			best_claim = cl
			best = cid
	return best

static func _do_marriage(s: CampaignState, cid: String, house: String, forced: bool) -> void:
	var c: Dictionary = s.chr(cid)
	var sp_gender: String = "f" if c["gender"] == "m" else "m"
	var sp := _mk_char(s, sp_gender, maxi(16, s.age_years(cid) - 2 + s.rng_roll(5)),
		60 + s.rng_roll(20), 40 + s.rng_roll(30), 0, 55 + s.rng_roll(20), 35 + s.rng_roll(30),
		"spouse", "", "")
	s.chr(sp)["branch_id"] = c["branch_id"]
	c["spouse_id"] = sp
	s.chr(sp)["spouse_id"] = cid
	s.marriages.append({"a": cid, "b": sp, "house_id": house, "generation": s.generation, "forced": forced})
	s.ext_standing[house] = int(s.ext_standing[house]) + 10
	if not forced:
		s.wealth -= 6
	match house:
		"house_velor":
			s.wealth += 15
			s.influence += 8
			if not forced:
				s.flags["obligation_house"] = "house_velor"
		"house_cardin":
			s.cohesion += 6
			s.succession_stability += 4
		"house_ostren":
			s.legitimacy += 8
			s.influence += 10
			if not forced:
				s.flags["obligation_house"] = "house_ostren"
	if cid == s.current_head_id:
		s.succession_stability += 6
	s.log_entry(cid, "chron.camp_marriage_forced" if forced else "chron.camp_marriage",
		{"spouse": sp, "house": house}, true)

static func _found_branch(s: CampaignState, cid: String, chron_key: String) -> void:
	var estate_ids := s.main_estate_ids()
	# 본가 저택(estate_hall)은 항상 마지막까지 남긴다.
	var give := ""
	for eid in estate_ids:
		if eid != "estate_hall":
			give = eid
			break
	if give == "":
		give = estate_ids[0]
	var bid := s.new_id("br")
	var origin_mem := ""
	var cl := s.claim_of(cid, "succession")
	if not cl.is_empty():
		origin_mem = cl["origin_memory_id"]
		cl["active"] = false
	s.branches[bid] = {
		"id": bid, "founder_id": cid, "generation": s.generation,
		"estate_id": give, "standing": 55, "origin_memory_id": origin_mem, "alive": true,
	}
	s.estates[give]["owner"] = bid
	var c: Dictionary = s.chr(cid)
	c["branch_id"] = bid
	c["role"] = "branch_head"
	s.add_char_stat(cid, "loyalty", 15)
	s.add_char_stat(cid, "legal_claim", -25)
	# 배우자/자녀도 분가를 따른다.
	var sp := s.spouse_of(cid)
	if sp != "":
		s.chr(sp)["branch_id"] = bid
	for kid in s.children_of(cid):
		s.chr(kid)["branch_id"] = bid
	s.cohesion += 5
	s.succession_stability += 8
	# 찬탈 기억에서 비롯한 분가는 권리 회복으로 기록한다.
	if origin_mem != "":
		var m := s.memory_by_id(origin_mem)
		if not m.is_empty() and m["kind"] == "rights_seized":
			s.resolve_memory(origin_mem, "restored")
			s.add_memory("rights_restored", chron_key, [cid], bid)
	s.log_entry(s.current_head_id, chron_key, {"kin": cid, "estate": give}, true)

static func _change_rank(s: CampaignState, delta: int, reason_key: String) -> void:
	var from := s.rank
	s.rank = clampi(s.rank + delta, 0, 2)
	if s.rank == from:
		return
	s.rank_history.append({
		"generation": s.generation, "turn": s.turn, "from": from, "to": s.rank,
		"reason_key": reason_key,
	})
	s.log_entry(s.current_head_id, "chron.camp_rank_up" if delta > 0 else "chron.camp_rank_down",
		{"rank": CampaignState.RANK_IDS[s.rank], "why": reason_key}, true)

# ---------------------------------------------------------------- 턴 흐름

static func end_action_phase(s: CampaignState) -> Dictionary:
	if s.phase != CampaignState.PHASE_ACTIONS:
		return {"phase": s.phase, "error": "reason.not_action_phase"}
	s.input_log.append("E")
	var dlm := _select_dilemma(s)
	if dlm.is_empty():
		s.log_entry(s.current_head_id, "chron.camp_quiet_turn")
		s.record_history("dilemma:none")
		return _after_dilemma(s)
	s.pending_dilemma = dlm
	s.phase = CampaignState.PHASE_DILEMMA
	s.record_history("dilemma_open:" + dlm["structure"])
	return {"phase": s.phase}

# ---------------------------------------------------------------- 딜레마 엔진

static func _choice(id: String, ok: bool, reason: String, benefit: Array, harm: Array, risk_key: String) -> Dictionary:
	return {
		"id": id, "ok": ok, "reason": reason if not ok else "",
		"benefit": benefit, "harm": harm, "risk_key": risk_key,
	}

static func _structure_cooldown_ok(s: CampaignState, structure: String, crisis: bool) -> bool:
	var count_this_gen := 0
	for d in s.dilemma_history:
		if d["structure"] == structure:
			if not crisis and s.global_turn - int(d["global_turn"]) < 3:
				return false
			if int(d["generation"]) == s.generation:
				count_this_gen += 1
	return crisis or count_this_gen < 2

# 상태 기반 딜레마 후보 생성 → 위기 우선, 나머지는 결정론 RNG로 선택.
static func _select_dilemma(s: CampaignState) -> Dictionary:
	var crisis: Array = []
	var normal: Array = []
	var inherited: Array = []  # 이전 세대 기억에서 비롯한 딜레마 — 우선 노출
	for structure in DILEMMA_STRUCTURES:
		var d := _build_dilemma(s, structure)
		if d.is_empty():
			continue
		if not _structure_cooldown_ok(s, structure, d["crisis"]):
			continue
		if d["crisis"]:
			crisis.append(d)
		elif d["origin_memory_id"] != "" \
				and int(s.memory_by_id(d["origin_memory_id"]).get("generation", s.generation)) < s.generation:
			inherited.append(d)
		else:
			normal.append(d)
	if not crisis.is_empty():
		return crisis[0]
	if not inherited.is_empty():
		return inherited[s.rng_roll(inherited.size())]
	if normal.is_empty():
		return {}
	return normal[s.rng_roll(normal.size())]

static func _mk_dilemma(s: CampaignState, structure: String, participants: Array,
		cause_key: String, cause_params: Dictionary, choices: Array,
		crisis: bool = false, origin_memory_id: String = "") -> Dictionary:
	return {
		"id": s.new_id("dlm"), "structure": structure,
		"title_key": "dlm.%s.title" % structure,
		"desc_key": "dlm.%s.desc" % structure,
		"participants": participants,
		"cause_key": cause_key, "cause_params": cause_params,
		"choices": choices, "crisis": crisis, "origin_memory_id": origin_memory_id,
	}

static func _build_dilemma(s: CampaignState, structure: String) -> Dictionary:
	var head := s.current_head_id
	match structure:
		"competing_heirs":
			var cands := _succession_candidates(s)
			if cands.size() < 2:
				return {}
			var a: String = cands[0]
			var b: String = cands[1]
			if int(s.chr(a)["legal_claim"]) < 25 or int(s.chr(b)["legal_claim"]) < 25:
				return {}
			if s.get_rel(a, b) >= 50:
				return {}
			return _mk_dilemma(s, structure, [a, b], "cause.competing_heirs", {"a": a, "b": b}, [
				_choice("competing_heirs:back_elder", true, "", [a], [b], "risk.rivalry_deepens"),
				_choice("competing_heirs:back_second", true, "", [b], [a], "risk.rivalry_deepens"),
				_choice("competing_heirs:demand_peace", s.influence >= 6, "reason.influence_6", [a, b], [], "risk.unresolved_claims"),
			])
		"marriage_obligation":
			var house: String = s.flags["obligation_house"]
			if house == "":
				return {}
			var target := ""
			for cid in s.children_of(head):
				var c: Dictionary = s.chr(cid)
				if c["alive"] and c["in_house"] and c["branch_id"] == "" and c["spouse_id"] == "" and s.is_adult(cid):
					target = cid
					break
			if target == "":
				return {}
			return _mk_dilemma(s, structure, [target], "cause.marriage_obligation", {"house": house, "child": target}, [
				_choice("marriage_obligation:comply", true, "", [head], [target], "risk.lasting_resentment"),
				_choice("marriage_obligation:refuse", true, "", [target], [], "risk.house_grudge"),
				_choice("marriage_obligation:compensate", s.wealth >= 15, "reason.wealth_15", [target], [], "risk.wealth_drain"),
			])
		"branch_claim":
			var cl := _strongest_active_claim(s)
			if cl.is_empty() or int(cl["strength"]) < 40:
				return {}
			var holder: String = cl["holder"]
			return _mk_dilemma(s, structure, [holder], "cause.branch_claim",
				{"holder": holder, "kind": cl["kind"]}, [
				_choice("branch_claim:recognize", true, "", [holder], [s.formal_heir_id if s.formal_heir_id != "" else head], "risk.weakened_line"),
				_choice("branch_claim:buy_off", s.wealth >= 15, "reason.wealth_15", [holder], [], "risk.claim_persists"),
				_choice("branch_claim:reject", true, "", [head], [holder], "risk.branch_feud"),
			], int(cl["strength"]) >= 70, cl["origin_memory_id"])
		"property_division":
			if s.main_estate_ids().size() < 2:
				return {}
			var kids := s.children_of(head)
			var adults: Array = []
			for cid in kids:
				if s.alive_in_house(cid) and s.is_adult(cid) and s.chr(cid)["branch_id"] == "":
					adults.append(cid)
			if adults.size() < 2:
				return {}
			var second: String = adults[1]
			if int(s.chr(second)["legal_claim"]) < 35:
				return {}
			return _mk_dilemma(s, structure, [adults[0], second], "cause.property_division",
				{"elder": adults[0], "second": second}, [
				_choice("property_division:divide", true, "", [second], [], "risk.reduced_seat"),
				_choice("property_division:promise_income", true, "", [second], [], "risk.debt_grows"),
				_choice("property_division:refuse", true, "", [adults[0]], [second], "risk.claims_harden"),
			])
		"regency_overreach":
			if s.regent_id == "" or not s.alive_in_house(s.regent_id) or s.turn < 2:
				return {}
			return _mk_dilemma(s, structure, [s.regent_id], "cause.regency", {"regent": s.regent_id}, [
				_choice("regency_overreach:yield", true, "", [s.regent_id], [head], "risk.regent_power"),
				_choice("regency_overreach:curb", true, "", [head], [s.regent_id], "risk.regent_resentment"),
				_choice("regency_overreach:end_regency", s.age_years(head) >= 15, "reason.head_too_young", [head], [s.regent_id], "risk.young_rule"),
			])
		"disloyal_kin":
			var wk := ""
			for cid in s.sorted_char_ids():
				var c: Dictionary = s.chr(cid)
				if c["alive"] and c["in_house"] and cid != head and not c["former_head"] \
						and c["branch_id"] == "" \
						and not c["disinherited"] and c["loyalty"] != null \
						and (int(c["loyalty"]) <= 25 or s.emotion_intensity(cid, "resentment", head) >= 70):
					wk = cid
					break
			if wk == "":
				return {}
			return _mk_dilemma(s, structure, [wk], "cause.disloyal_kin", {"kin": wk}, [
				_choice("disloyal_kin:disinherit", true, "", [s.formal_heir_id if s.formal_heir_id != "" else head], [wk], "risk.disinherited_line"),
				_choice("disloyal_kin:exile", true, "", [head], [wk], "risk.exiled_return"),
				_choice("disloyal_kin:forgive", true, "", [wk], [], "risk.repeat_betrayal"),
			])
		"exile_return":
			for m in s.active_memories():
				if m["kind"] != "exile" or int(m["generation"]) >= s.generation:
					continue
				var ex: String = m["people"][0]
				if not s.has_chr(ex) or not s.chr(ex)["alive"] or s.chr(ex)["in_house"]:
					continue
				return _mk_dilemma(s, structure, [ex], "cause.exile_return", {"exile": ex}, [
					_choice("exile_return:allow", true, "", [ex], [s.formal_heir_id if s.formal_heir_id != "" else head], "risk.restored_rival"),
					_choice("exile_return:refuse", true, "", [s.formal_heir_id if s.formal_heir_id != "" else head], [ex], "risk.outside_claim"),
					_choice("exile_return:restore_estate", s.main_estate_ids().size() >= 2, "reason.need_spare_estate", [ex], [], "risk.reduced_seat"),
				], false, m["id"])
			return {}
		"rescue_house":
			if s.wealth > 10 and s.debt < 50:
				return {}
			var hx := _best_standing_house(s)
			return _mk_dilemma(s, structure, [head], "cause.rescue_house", {"house": hx}, [
				_choice("rescue_house:accept", true, "", [head], [], "risk.obligation_due"),
				_choice("rescue_house:refuse", true, "", [head], [], "risk.rank_fall"),
				_choice("rescue_house:sell_estate", s.main_estate_ids().size() >= 2, "reason.need_spare_estate", [head], [], "risk.reduced_seat"),
			], true)
		"royal_levy":
			if s.rank < 2 or not s.flags["royal_levy_due"]:
				return {}
			var kin := _adult_kin_for_service(s)
			return _mk_dilemma(s, structure, [head], "cause.royal_levy", {}, [
				_choice("royal_levy:pay", s.wealth >= 18, "reason.wealth_18", [head], [], "risk.wealth_drain"),
				_choice("royal_levy:refuse", true, "", [], [head], "risk.rank_fall"),
				_choice("royal_levy:send_kin", kin != "", "reason.no_valid_target", [head], [kin], "risk.kin_resentment"),
			], true)
		"recovery_offer":
			if s.rank != 0 or s.turn < 2:
				return {}
			var person := ""
			for cid in s.sorted_char_ids():
				var c: Dictionary = s.chr(cid)
				if c["alive"] and c["in_house"] and c["branch_id"] == "" and c["spouse_id"] == "" \
						and s.is_adult(cid) and cid != head:
					person = cid
					break
			return _mk_dilemma(s, structure, [head], "cause.recovery_offer", {"house": "house_cardin"}, [
				_choice("recovery_offer:marry_patron", person != "", "reason.no_valid_target", [head], [person], "risk.lasting_resentment"),
				_choice("recovery_offer:tribute", s.wealth >= 20, "reason.wealth_20", [head], [], "risk.wealth_drain"),
				_choice("recovery_offer:endure", true, "", [], [], "risk.prolonged_decline"),
			])
		"legal_vs_emotional":
			if s.formal_heir_id == "" or not s.alive_in_house(s.formal_heir_id):
				return {}
			var beloved := ""
			for cid in s.children_of(head):
				if cid != s.formal_heir_id and s.alive_in_house(cid) and s.chr(cid)["branch_id"] == "" \
						and s.get_rel(head, cid) >= s.get_rel(head, s.formal_heir_id) + 15:
					beloved = cid
					break
			if beloved == "":
				return {}
			return _mk_dilemma(s, structure, [s.formal_heir_id, beloved], "cause.legal_vs_emotional",
				{"heir": s.formal_heir_id, "beloved": beloved}, [
				_choice("legal_vs_emotional:uphold_law", true, "", [s.formal_heir_id], [beloved], "risk.cold_duty"),
				_choice("legal_vs_emotional:favor_beloved", true, "", [beloved], [s.formal_heir_id], "risk.spurned_heir"),
				_choice("legal_vs_emotional:divide_duty", s.wealth >= 10, "reason.wealth_10", [beloved], [], "risk.wealth_drain"),
			])
	return {}

static func _strongest_active_claim(s: CampaignState) -> Dictionary:
	var best: Dictionary = {}
	for c in s.active_claims():
		if not s.has_chr(c["holder"]) or not s.chr(c["holder"])["alive"]:
			continue
		if best.is_empty() or int(c["strength"]) > int(best["strength"]):
			best = c
	return best

static func _best_standing_house(s: CampaignState) -> String:
	var best := "house_cardin"
	for h in EXT_HOUSES:
		if int(s.ext_standing[h]) > int(s.ext_standing[best]):
			best = h
	return best

static func _adult_kin_for_service(s: CampaignState) -> String:
	for cid in s.sorted_char_ids():
		var c: Dictionary = s.chr(cid)
		if c["alive"] and c["in_house"] and cid != s.current_head_id and s.is_adult(cid) \
				and c["branch_id"] == "" and c["loyalty"] != null:
			return cid
	return ""

static func dilemma_choice_check(s: CampaignState, choice_id: String) -> Dictionary:
	if s.phase != CampaignState.PHASE_DILEMMA:
		return {"ok": false, "reason": "reason.not_event_phase"}
	for c in s.pending_dilemma["choices"]:
		if c["id"] == choice_id:
			return {"ok": c["ok"], "reason": c["reason"]}
	return {"ok": false, "reason": "reason.unknown_choice"}

static func apply_dilemma_choice(s: CampaignState, choice_id: String) -> Dictionary:
	var check := dilemma_choice_check(s, choice_id)
	if not check["ok"]:
		return {"phase": s.phase, "error": check["reason"]}
	var dlm: Dictionary = s.pending_dilemma
	var chosen: Dictionary = {}
	for c in dlm["choices"]:
		if c["id"] == choice_id:
			chosen = c
	s.pending_dilemma = {}
	s.input_log.append("D:" + choice_id)
	var head := s.current_head_id
	var p: Array = dlm["participants"]
	match choice_id:
		# --- competing_heirs ---
		"competing_heirs:back_elder":
			s.add_char_stat(p[0], "legal_claim", 8)
			s.add_char_stat(p[1], "loyalty", -8)
			s.add_emotion(p[1], "resentment", p[0], 40, "dlm.competing_heirs.title")
			s.log_entry(head, "chron.camp_back_heir", {"child": p[0]}, true)
		"competing_heirs:back_second":
			s.add_char_stat(p[1], "legal_claim", 8)
			s.add_char_stat(p[1], "ability", 4)
			s.add_char_stat(p[0], "loyalty", -8)
			s.add_emotion(p[0], "jealousy", p[1], 40, "dlm.competing_heirs.title")
			s.log_entry(head, "chron.camp_back_heir", {"child": p[1]}, true)
		"competing_heirs:demand_peace":
			s.influence -= 6
			s.add_rel(p[0], p[1], 12)
			s.cohesion += 4
			s.log_entry(head, "chron.camp_demand_peace", {"a": p[0], "b": p[1]})
		# --- marriage_obligation ---
		"marriage_obligation:comply":
			var house: String = s.flags["obligation_house"]
			s.flags["obligation_house"] = ""
			_do_marriage(s, p[0], house, true)
			var mem := s.add_memory("forced_marriage", "chron.camp_marriage_forced", [p[0]])
			s.add_emotion(p[0], "resentment", head, 50, "chron.camp_marriage_forced", mem)
			s.wealth += 12
		"marriage_obligation:refuse":
			var house2: String = s.flags["obligation_house"]
			s.flags["obligation_house"] = ""
			s.ext_standing[house2] = int(s.ext_standing[house2]) - 18
			s.succession_stability -= 5
			s.log_entry(head, "chron.camp_obligation_refused", {"house": house2}, true)
		"marriage_obligation:compensate":
			var house3: String = s.flags["obligation_house"]
			s.flags["obligation_house"] = ""
			s.wealth -= 15
			s.ext_standing[house3] = int(s.ext_standing[house3]) + 4
			s.log_entry(head, "chron.camp_obligation_paid", {"house": house3})
		# --- branch_claim ---
		"branch_claim:recognize":
			var cl := _strongest_active_claim(s)
			if not cl.is_empty():
				cl["active"] = false
				var holder: String = cl["holder"]
				if cl["kind"] == "estate" and s.main_estate_ids().size() >= 2:
					_transfer_estate_to_holder(s, holder)
				else:
					s.add_char_stat(holder, "legal_claim", 15)
				s.legitimacy -= 6
				s.add_char_stat(holder, "loyalty", 15)
				var om: String = cl["origin_memory_id"]
				if om != "":
					var m := s.memory_by_id(om)
					if not m.is_empty() and m["kind"] == "rights_seized" and m["active"]:
						s.resolve_memory(om, "restored")
						s.add_memory("rights_restored", "chron.camp_claim_recognized", [holder])
				s.log_entry(head, "chron.camp_claim_recognized", {"holder": holder}, true)
		"branch_claim:buy_off":
			var cl2 := _strongest_active_claim(s)
			if not cl2.is_empty():
				s.wealth -= 15
				cl2["strength"] = int(cl2["strength"]) - 35
				if int(cl2["strength"]) <= 0:
					cl2["active"] = false
				s.log_entry(head, "chron.camp_claim_bought", {"holder": cl2["holder"]})
		"branch_claim:reject":
			var cl3 := _strongest_active_claim(s)
			if not cl3.is_empty():
				cl3["strength"] = clampi(int(cl3["strength"]) + 15, 0, 100)
				var holder3: String = cl3["holder"]
				s.add_emotion(holder3, "resentment", head, 45, "chron.camp_claim_rejected", cl3["origin_memory_id"])
				s.cohesion -= 5
				s.log_entry(head, "chron.camp_claim_rejected", {"holder": holder3}, true)
		# --- property_division ---
		"property_division:divide":
			_found_branch(s, p[1], "chron.camp_division_branch")
		"property_division:promise_income":
			s.debt += 10
			s.add_char_stat(p[1], "loyalty", 8)
			s.succession_stability += 3
			s.log_entry(head, "chron.camp_promise_income", {"kin": p[1]})
		"property_division:refuse":
			s.add_char_stat(p[1], "loyalty", -10)
			s.add_emotion(p[1], "resentment", p[0], 40, "chron.camp_division_refused")
			var cl4 := s.claim_of(p[1], "succession")
			if cl4.is_empty():
				s.add_claim(p[1], "succession", "main", 40)
			else:
				cl4["strength"] = clampi(int(cl4["strength"]) + 15, 0, 100)
			s.log_entry(head, "chron.camp_division_refused", {"kin": p[1]}, true)
		# --- regency_overreach ---
		"regency_overreach:yield":
			s.influence -= 8
			s.succession_stability += 8
			s.add_char_stat(s.regent_id, "loyalty", 10)
			s.log_entry(s.regent_id, "chron.camp_regent_yield", {}, true)
		"regency_overreach:curb":
			s.cohesion -= 6
			s.add_char_stat(s.regent_id, "loyalty", -12)
			s.add_emotion(s.regent_id, "resentment", head, 35, "chron.camp_regent_curbed")
			s.log_entry(head, "chron.camp_regent_curbed")
		"regency_overreach:end_regency":
			var rg := s.regent_id
			s.regent_id = ""
			if s.has_chr(rg):
				s.chr(rg)["role"] = "kin"
			s.succession_stability -= 6
			s.legitimacy += 6
			s.log_entry(head, "chron.camp_regency_ended", {"regent": rg}, true)
		# --- disloyal_kin ---
		"disloyal_kin:disinherit":
			var wk: String = p[0]
			s.chr(wk)["disinherited"] = true
			s.add_char_stat(wk, "legal_claim", -40)
			var mem2 := s.add_memory("disinheritance", "chron.camp_disinherit", [wk])
			s.add_emotion(wk, "resentment", head, 60, "chron.camp_disinherit", mem2)
			s.succession_stability += 6
			s.cohesion -= 8
			if s.formal_heir_id == wk:
				s.formal_heir_id = ""
			s.log_entry(head, "chron.camp_disinherit", {"kin": wk}, true)
		"disloyal_kin:exile":
			var wk2: String = p[0]
			s.chr(wk2)["in_house"] = false
			s.chr(wk2)["exiled"] = true
			s.chr(wk2)["role"] = "exile"
			var mem3 := s.add_memory("exile", "chron.camp_exile", [wk2])
			s.cohesion -= 10
			s.succession_stability += 8
			if s.formal_heir_id == wk2:
				s.formal_heir_id = ""
			for cid in s.sorted_char_ids():
				if cid != wk2 and cid != head and s.alive_in_house(cid) and s.chr(cid)["loyalty"] != null:
					s.add_emotion(cid, "fear", head, 30, "chron.camp_exile", mem3)
					break
			s.log_entry(head, "chron.camp_exile", {"kin": wk2}, true)
		"disloyal_kin:forgive":
			s.add_char_stat(p[0], "loyalty", 12)
			s.cohesion += 5
			s.log_entry(head, "chron.camp_forgive", {"kin": p[0]})
		# --- exile_return ---
		"exile_return:allow":
			var ex: String = p[0]
			s.chr(ex)["in_house"] = true
			s.chr(ex)["exiled"] = false
			s.chr(ex)["role"] = "kin"
			s.add_char_stat(ex, "legal_claim", 20)
			s.resolve_memory(dlm["origin_memory_id"], "returned")
			s.add_memory("rights_restored", "chron.camp_exile_returned", [ex])
			s.cohesion += 6
			s.succession_stability -= 6
			s.log_entry(ex, "chron.camp_exile_returned", {}, true)
		"exile_return:refuse":
			var ex2: String = p[0]
			s.add_emotion(ex2, "resentment", head, 50, "chron.camp_exile_refused", dlm["origin_memory_id"])
			if s.claim_of(ex2, "succession").is_empty():
				s.add_claim(ex2, "succession", "main", 30, dlm["origin_memory_id"])
			s.log_entry(head, "chron.camp_exile_refused", {"kin": ex2}, true)
		"exile_return:restore_estate":
			var ex3: String = p[0]
			s.chr(ex3)["in_house"] = true
			s.chr(ex3)["exiled"] = false
			s.resolve_memory(dlm["origin_memory_id"], "restored")
			_found_branch(s, ex3, "chron.camp_exile_restored")
			s.add_memory("rights_restored", "chron.camp_exile_restored", [ex3])
			s.succession_stability += 4
		# --- rescue_house ---
		"rescue_house:accept":
			var hx: String = dlm["cause_params"]["house"]
			s.wealth += 30
			s.debt = maxi(0, s.debt - 20)
			s.flags["obligation_house"] = hx
			s.ext_standing[hx] = int(s.ext_standing[hx]) + 10
			s.add_memory("house_rescue", "chron.camp_rescued", [head])
			s.flags["proud_refusal"] = false
			s.flags["crisis_counter"] = 0
			s.log_entry(head, "chron.camp_rescued", {"house": hx}, true)
		"rescue_house:refuse":
			s.legitimacy += 6
			s.flags["proud_refusal"] = true
			s.log_entry(head, "chron.camp_rescue_refused", {}, true)
		"rescue_house:sell_estate":
			var eids := s.main_estate_ids()
			var sell := ""
			for eid in eids:
				if eid != "estate_hall":
					sell = eid
					break
			if sell == "":
				sell = eids[0]
			s.estates[sell]["owner"] = "sold"
			s.wealth += 25
			s.legitimacy -= 4
			s.log_entry(head, "chron.camp_estate_sold", {"estate": sell}, true)
		# --- royal_levy ---
		"royal_levy:pay":
			s.flags["royal_levy_due"] = false
			s.wealth -= 18
			s.ext_standing["house_ostren"] = int(s.ext_standing["house_ostren"]) + 8
			s.legitimacy += 4
			s.log_entry(head, "chron.camp_levy_paid")
		"royal_levy:refuse":
			s.flags["royal_levy_due"] = false
			s.flags["levy_refused"] = true
			s.ext_standing["house_ostren"] = int(s.ext_standing["house_ostren"]) - 20
			s.legitimacy -= 8
			s.log_entry(head, "chron.camp_levy_refused", {}, true)
		"royal_levy:send_kin":
			s.flags["royal_levy_due"] = false
			var kin := _adult_kin_for_service(s)
			if kin != "":
				s.add_char_stat(kin, "loyalty", -8)
			s.influence += 6
			s.ext_standing["house_ostren"] = int(s.ext_standing["house_ostren"]) + 4
			s.log_entry(head, "chron.camp_levy_kin", {"kin": kin})
		# --- recovery_offer ---
		"recovery_offer:marry_patron":
			var person := ""
			for cid in s.sorted_char_ids():
				var c: Dictionary = s.chr(cid)
				if c["alive"] and c["in_house"] and c["branch_id"] == "" and c["spouse_id"] == "" \
						and s.is_adult(cid) and cid != head:
					person = cid
					break
			if person != "":
				_do_marriage(s, person, "house_cardin", true)
				var mem4 := s.add_memory("forced_marriage", "chron.camp_marriage_forced", [person])
				s.add_emotion(person, "resentment", head, 45, "chron.camp_marriage_forced", mem4)
			_change_rank(s, 1, "rank.marriage_recovery")
		"recovery_offer:tribute":
			s.wealth -= 20
			s.legitimacy += 4
			_change_rank(s, 1, "rank.tribute_recovery")
		"recovery_offer:endure":
			s.cohesion += 4
			s.log_entry(head, "chron.camp_endure_decline")
		# --- legal_vs_emotional ---
		"legal_vs_emotional:uphold_law":
			s.add_char_stat(p[0], "legal_claim", 6)
			s.succession_stability += 6
			s.add_emotion(p[1], "jealousy", p[0], 35, "dlm.legal_vs_emotional.title")
			s.log_entry(head, "chron.camp_uphold_law", {"heir": p[0]})
		"legal_vs_emotional:favor_beloved":
			s.formal_heir_id = p[1]
			s.add_char_stat(p[1], "legal_claim", 10)
			s.add_char_stat(p[0], "loyalty", -15)
			s.add_emotion(p[0], "resentment", p[1], 50, "chron.camp_favor_beloved")
			s.succession_stability -= 12
			s.log_entry(head, "chron.camp_favor_beloved", {"beloved": p[1]}, true)
		"legal_vs_emotional:divide_duty":
			s.wealth -= 10
			s.add_char_stat(p[1], "loyalty", 8)
			s.add_char_stat(p[0], "loyalty", 4)
			s.log_entry(head, "chron.camp_divide_duty")
		_:
			assert(false, "unhandled dilemma choice: " + choice_id)
	s.dilemma_history.append({
		"generation": s.generation, "turn": s.turn, "global_turn": s.global_turn,
		"structure": dlm["structure"], "id": dlm["id"], "choice": choice_id,
		"beneficiaries": chosen["benefit"], "victims": chosen["harm"],
		"origin_memory_id": dlm["origin_memory_id"],
	})
	s.clamp_all()
	s.record_history("choice:" + choice_id)
	return _after_dilemma(s)

static func _transfer_estate_to_holder(s: CampaignState, holder: String) -> void:
	var eids := s.main_estate_ids()
	var give := ""
	for eid in eids:
		if eid != "estate_hall":
			give = eid
			break
	if give == "":
		return
	var bid: String = s.chr(holder)["branch_id"]
	if bid == "":
		_found_branch(s, holder, "chron.camp_claim_recognized")
	else:
		s.estates[give]["owner"] = bid

# ---------------------------------------------------------------- 업킵/승계 판정

static func _after_dilemma(s: CampaignState) -> Dictionary:
	_upkeep(s)
	var cause := _succession_trigger(s)
	if cause != "":
		return _trigger_succession(s, cause)
	# 턴 진행
	s.turn += 1
	s.global_turn += 1
	s.action_points = 2
	s.actions_used = {}
	s.phase = CampaignState.PHASE_ACTIONS
	s.record_history("turn_start")
	return {"phase": s.phase}

static func _upkeep(s: CampaignState) -> void:
	var head := s.current_head_id
	# 나이 증가
	for id in s.sorted_char_ids():
		var c: Dictionary = s.chr(id)
		if c["alive"]:
			c["age_months"] = int(c["age_months"]) + 6
	# 성장/노화
	for id in s.sorted_char_ids():
		var c: Dictionary = s.chr(id)
		if not c["alive"]:
			continue
		var ay := s.age_years(id)
		if ay >= 6 and ay <= 20 and s.rng_pct() < 40:
			c["ability"] = clampi(int(c["ability"]) + 1, 0, 100)
		if ay >= 50:
			c["health"] = clampi(int(c["health"]) - (1 + (1 if s.rng_pct() < 30 else 0)), 0, 100)
		if ay >= 62:
			c["health"] = clampi(int(c["health"]) - 1, 0, 100)
	# 출생
	var sp := s.spouse_of(head)
	if sp != "" and s.chr(sp)["in_house"] and s.age_years(sp) >= 16 and s.age_years(sp) <= 45 \
			and s.children_of(head).size() < 4 and s.rng_pct() < 22:
		var baby := _mk_char(s, "m" if s.rng_roll(2) == 0 else "f", 0,
			70 + s.rng_roll(20), 20 + s.rng_roll(20), 30 - s.children_of(head).size() * 5,
			60, 30 + s.rng_roll(30), "child", head, sp)
		s.set_rel(head, baby, 60)
		s.log_entry(head, "chron.camp_birth", {"child": baby}, true)
	# 부채 이자
	if s.debt > 0 and s.global_turn % 2 == 0:
		s.debt += 2
	# 랭크별 수입/의무 — 랭크가 실제 압력을 바꾼다.
	match s.rank:
		0:
			s.wealth -= 2
		1:
			s.wealth += 2
		2:
			s.wealth += 4
			if s.turn % 4 == 0:
				s.flags["royal_levy_due"] = true
	# 왕실 징발 거부 → 강등
	if s.flags["levy_refused"]:
		s.flags["levy_refused"] = false
		_change_rank(s, -1, "rank.royal_disfavor")
	# 구조 거절 후 위기 지속 → 강등
	if s.flags["proud_refusal"]:
		if s.wealth <= 5 or s.debt >= 55:
			s.flags["crisis_counter"] = int(s.flags["crisis_counter"]) + 1
			if int(s.flags["crisis_counter"]) >= 2:
				s.flags["proud_refusal"] = false
				s.flags["crisis_counter"] = 0
				_change_rank(s, -1, "rank.insolvency")
		else:
			s.flags["proud_refusal"] = false
			s.flags["crisis_counter"] = 0
	# 일반 몰락 규칙
	if s.debt >= 65 and s.legitimacy <= 30 and s.rank > 0:
		_change_rank(s, -1, "rank.collapse")
		s.debt = maxi(0, s.debt - 25)
		s.legitimacy += 5
	# 감정 감쇠와 영향
	var to_remove: Array = []
	for e in s.emotions:
		if int(e["intensity"]) >= 60 and s.has_chr(e["owner"]) and s.chr(e["owner"])["alive"]:
			match e["kind"]:
				"resentment":
					s.add_char_stat(e["owner"], "loyalty", -2)
				"affection":
					s.add_char_stat(e["owner"], "loyalty", 1)
				"jealousy":
					s.add_rel(e["owner"], e["target"], -1)
				"fear":
					s.add_char_stat(e["owner"], "ambition", -1)
		e["intensity"] = int(e["intensity"]) - 4
		if int(e["intensity"]) <= 0:
			to_remove.append(e)
	for e in to_remove:
		s.emotions.erase(e)
	# 강한 권리 주장 방치 → 강탈
	for cl in s.active_claims():
		if int(cl["strength"]) >= 85 and s.has_chr(cl["holder"]) and s.chr(cl["holder"])["alive"]:
			cl["active"] = false
			var holder: String = cl["holder"]
			var eids := s.main_estate_ids()
			if eids.size() >= 2:
				_transfer_estate_to_holder(s, holder)
			else:
				s.wealth -= 15
			s.add_memory("betrayal", "chron.camp_claim_seized", [holder])
			s.legitimacy -= 8
			s.log_entry(holder, "chron.camp_claim_seized", {}, true)
			break
	# 외부 가문 관계는 중립으로 회귀
	for h in EXT_HOUSES:
		var v := int(s.ext_standing[h])
		s.ext_standing[h] = v + (1 if v < 50 else (-1 if v > 50 else 0))
	# 비가주 사망 판정(고령)
	for id in s.sorted_char_ids():
		var c: Dictionary = s.chr(id)
		if not c["alive"] or id == head:
			continue
		var ay := s.age_years(id)
		if (ay >= 62 and s.rng_pct() < (ay - 60) * 5) or int(c["health"]) <= 3:
			_on_death(s, id)
	s.clamp_all()
	s.record_history("upkeep")

static func _on_death(s: CampaignState, id: String) -> void:
	var c: Dictionary = s.chr(id)
	c["alive"] = false
	c["role"] = "deceased_" + str(c["role"])
	var branch_id: String = c["branch_id"]
	if branch_id != "" and s.branches.has(branch_id):
		var has_living_member := false
		for other_id in s.sorted_char_ids():
			var other: Dictionary = s.chr(other_id)
			if other["branch_id"] == branch_id and other["alive"]:
				has_living_member = true
				break
		s.branches[branch_id]["alive"] = has_living_member
	s.log_entry(id, "chron.camp_death", {}, true)
	if s.regent_id == id:
		s.regent_id = ""
	if s.formal_heir_id == id:
		s.formal_heir_id = ""
	# 감정 정리: 소유자 사망 → 제거, 대상 사망 → 기억 기반이면 살아있는 관련자에게 절반 강도로 전이.
	var to_remove: Array = []
	for e in s.emotions:
		if e["owner"] == id:
			to_remove.append(e)
		elif e["target"] == id:
			var moved := false
			if e["origin_memory_id"] != "":
				var m := s.memory_by_id(e["origin_memory_id"])
				if not m.is_empty() and m["active"]:
					for pid in m["people"]:
						if pid != e["owner"] and s.has_chr(pid) and s.chr(pid)["alive"]:
							e["target"] = pid
							e["intensity"] = int(e["intensity"]) / 2
							moved = true
							break
			if not moved:
				to_remove.append(e)
	for e in to_remove:
		s.emotions.erase(e)

# 승계 사유 판정. ""이면 계속 진행.
static func _succession_trigger(s: CampaignState) -> String:
	if s.turn < GEN_MIN_TURNS:
		return ""
	var head := s.current_head_id
	var c: Dictionary = s.chr(head)
	if not c["alive"]:
		return "health"
	if int(c["health"]) <= 5:
		return "health"
	var ay := s.age_years(head)
	if ay >= 56:
		var chance := (ay - 55) * 7
		if int(c["health"]) < 30:
			chance += 30 - int(c["health"])
		if s.rng_pct() < chance:
			return "age"
	if s.legitimacy <= 5:
		return "forced_removal"
	if s.turn >= GEN_MAX_TURNS:
		return "max_turns"
	return ""

static func _trigger_succession(s: CampaignState, cause: String) -> Dictionary:
	var head := s.current_head_id
	match cause:
		"age", "health":
			if s.chr(head)["alive"]:
				_on_death(s, head)
		"forced_removal":
			s.chr(head)["role"] = "deposed_head"
			s.log_entry(head, "chron.camp_deposed", {}, true)
		"max_turns":
			s.chr(head)["role"] = "abdicated_head"
			s.log_entry(head, "chron.camp_council_forces_transfer", {}, true)
	_run_succession(s, cause)
	return {"phase": s.phase}

# ---------------------------------------------------------------- 승계

static func _succession_candidates(s: CampaignState) -> Array:
	var out: Array = []
	for id in s.sorted_char_ids():
		var c: Dictionary = s.chr(id)
		if c["alive"] and c["in_house"] and id != s.current_head_id \
				and not c["disinherited"] and not c["exiled"] and c["branch_id"] == "" \
				and not c["former_head"] \
				and int(c["legal_claim"]) >= 10:
			out.append(id)
	# 직계 우선, 청구권 내림차순 정렬.
	out.sort_custom(func(a, b):
		var ad: bool = s.chr(a)["father_id"] == s.current_head_id or s.chr(a)["mother_id"] == s.current_head_id
		var bd: bool = s.chr(b)["father_id"] == s.current_head_id or s.chr(b)["mother_id"] == s.current_head_id
		if ad != bd:
			return ad
		var ac: int = int(s.chr(a)["legal_claim"])
		var bc: int = int(s.chr(b)["legal_claim"])
		return ac > bc if ac != bc else a < b)
	return out

static func _run_succession(s: CampaignState, cause: String) -> void:
	var old_head := s.current_head_id
	if s.chr(old_head)["alive"]:
		s.chr(old_head)["former_head"] = true
	var cands := _succession_candidates(s)
	if cands.is_empty():
		# 대가 끊김 — 먼 사촌이 가계를 잇는다(유산 평가에 불리).
		var parent_id: String = s.flags["founder_collateral_id"]
		var parent: Dictionary = s.chr(parent_id)
		var father_id := parent_id if parent["gender"] == "m" else ""
		var mother_id := parent_id if parent["gender"] == "f" else ""
		var cousin := _mk_char(s, "m" if s.rng_roll(2) == 0 else "f", 28 + s.rng_roll(8),
			60 + s.rng_roll(20), 45 + s.rng_roll(20), 30, 50, 50 + s.rng_roll(20), "kin",
			father_id, mother_id)
		s.flags["continuity_broken"] = true
		s.log_entry(cousin, "chron.camp_distant_cousin", {}, true)
		cands = [cousin]
	var ev: Dictionary = {"cause": cause, "candidates": {}, "inputs": {}, "changes": []}
	ev["inputs"] = {
		"cohesion": s.cohesion, "stability": s.succession_stability,
		"formal_heir_id": s.formal_heir_id, "cause": cause,
	}
	var scores: Dictionary = {}
	for cid in cands:
		var c: Dictionary = s.chr(cid)
		var parts: Array = []
		var score := 0
		var direct: bool = c["father_id"] == old_head or c["mother_id"] == old_head
		if direct:
			score += 25
			parts.append({"key": "score.direct_line", "value": 25})
		var v := int(floor(int(c["legal_claim"]) * 0.35))
		score += v
		parts.append({"key": "score.legal_claim", "value": v})
		v = int(floor(int(c["ability"]) * 0.20))
		score += v
		parts.append({"key": "score.ability", "value": v})
		if s.formal_heir_id == cid:
			score += 20
			parts.append({"key": "score.formal_heir", "value": 20})
		if s.is_adult(cid):
			score += 10
			parts.append({"key": "score.adult", "value": 10})
		elif s.age_years(cid) < 8:
			score -= 8
			parts.append({"key": "score.infant", "value": -8})
		var support := 0
		for oid in s.sorted_char_ids():
			var o: Dictionary = s.chr(oid)
			if oid != cid and o["alive"] and o["in_house"] and o["loyalty"] != null \
					and int(o["loyalty"]) >= 60 and s.get_rel(oid, cid) >= 50:
				support += 3
		support = mini(support, 12)
		if support > 0:
			score += support
			parts.append({"key": "score.kin_support", "value": support})
		var resent := 0
		for e in s.emotions:
			if e["kind"] == "resentment" and e["target"] == cid:
				resent += int(e["intensity"]) / 20
		if resent > 0:
			score -= resent
			parts.append({"key": "score.resentment", "value": -resent})
		scores[cid] = score
		ev["candidates"][cid] = {"total": score, "parts": parts}
	# 승자 결정(동률: 공식 후계 → 연장자 → id).
	var ordered := cands.duplicate()
	ordered.sort_custom(func(a, b):
		if scores[a] != scores[b]:
			return int(scores[a]) > int(scores[b])
		if s.formal_heir_id == a:
			return true
		if s.formal_heir_id == b:
			return false
		var am: int = int(s.chr(a)["age_months"])
		var bm: int = int(s.chr(b)["age_months"])
		return am > bm if am != bm else a < b)
	var winner: String = ordered[0]
	var runner: String = ordered[1] if ordered.size() > 1 else ""
	var diff: int = int(scores[winner]) - (int(scores[runner]) if runner != "" else 999)
	# 결과 분류
	var outcome := ""
	if runner == "":
		outcome = "camp_uncontested"
		s.succession_stability += 8
		ev["changes"].append({"key": "change.stability", "value": 8})
	elif diff <= 5 and s.cohesion < 35:
		outcome = "camp_disputed"
		s.legitimacy -= 10
		s.cohesion -= 12
		s.wealth -= 10
		ev["changes"].append({"key": "change.legitimacy", "value": -10})
		ev["changes"].append({"key": "change.cohesion", "value": -12})
		ev["changes"].append({"key": "change.wealth", "value": -10})
	elif not s.is_adult(winner):
		outcome = "camp_regency"
		s.succession_stability -= 5
		ev["changes"].append({"key": "change.stability", "value": -5})
	elif s.formal_heir_id == winner and s.succession_stability >= 50:
		outcome = "camp_stable"
		s.legitimacy += 8
		s.succession_stability += 10
		ev["changes"].append({"key": "change.legitimacy", "value": 8})
		ev["changes"].append({"key": "change.stability", "value": 10})
	else:
		outcome = "camp_uneasy"
		s.succession_stability -= 5
		ev["changes"].append({"key": "change.stability", "value": -5})
	# 패자 처리 — 다음 세대 갈등의 씨앗.
	if runner != "":
		s.chr(runner)["role"] = "claimant"
		var mem := s.add_memory("rights_seized", "chron.camp_succ_" + outcome, [runner, winner])
		s.add_emotion(runner, "resentment", winner, 55 if outcome == "camp_disputed" else 40,
			"chron.camp_succ_" + outcome, mem)
		if s.claim_of(runner, "succession").is_empty():
			s.add_claim(runner, "succession", "main",
				55 if outcome == "camp_disputed" else 40, mem)
	# 섭정
	if not s.is_adult(winner):
		var regent := ""
		var best := -1
		for oid in s.sorted_char_ids():
			var o: Dictionary = s.chr(oid)
			if oid != winner and o["alive"] and o["in_house"] and s.is_adult(oid) and o["loyalty"] != null:
				var w := int(o["ability"]) + int(o["loyalty"])
				if w > best:
					best = w
					regent = oid
		if regent != "":
			s.regent_id = regent
			s.chr(regent)["role"] = "regent"
			s.log_entry(regent, "chron.camp_regency_begins", {"ward": winner}, true)
	else:
		s.regent_id = ""
	ev["outcome_id"] = outcome
	ev["winner"] = winner
	ev["runner"] = runner
	s.clamp_all()
	s.succession_records.append({
		"generation": s.generation, "turn": s.turn, "cause": cause, "outcome": outcome,
		"old_head": old_head, "new_head": winner, "evidence": ev,
	})
	s.log_entry(winner, "chron.camp_succ_" + outcome, {"cause_key": "succcause." + cause}, true)
	if s.generation >= 3:
		s.next_successor_id = winner
	else:
		s.current_head_id = winner
		s.chr(winner)["role"] = "house_head"
		s.chr(winner)["loyalty"] = null
		if s.has_chr(old_head) and s.chr(old_head)["alive"]:
			s.chr(old_head)["loyalty"] = 50
	s.formal_heir_id = ""
	s.phase = CampaignState.PHASE_SUCCESSION
	s.record_history("succession:g%d:%s:%s" % [s.generation, cause, outcome])

static func confirm_succession(s: CampaignState) -> Dictionary:
	if s.phase != CampaignState.PHASE_SUCCESSION:
		return {"phase": s.phase, "error": "reason.not_event_phase"}
	s.input_log.append("S")
	if s.generation >= 3:
		_evaluate_legacy(s)
		return {"phase": s.phase}
	_begin_next_generation(s)
	return {"phase": s.phase}

static func _begin_next_generation(s: CampaignState) -> void:
	s.generation += 1
	s.turn = 1
	s.global_turn += 1
	s.action_points = 2
	s.actions_used = {}
	s.pending_dilemma = {}
	s.flags["heir_declared"] = false
	s.flags["petition_used"] = false
	s.flags["royal_levy_due"] = false
	s.cohesion += 5
	s.clamp_all()
	s.log_entry(s.current_head_id, "chron.camp_new_generation", {"generation": s.generation}, true)
	s.record_history("generation_start:g%d" % s.generation)
	s.phase = CampaignState.PHASE_ACTIONS

# ---------------------------------------------------------------- 유산 평가

static func _evaluate_legacy(s: CampaignState) -> void:
	var contributors: Array = []
	var score := 0
	var add := func(key: String, value: int) -> void:
		if value != 0:
			contributors.append({"key": key, "value": value})
	# 최종 랭크
	add.call("legacy.final_rank", s.rank * 15)
	score += s.rank * 15
	# 혈통 연속성
	var blood := 0
	if s.next_successor_id != "" and not s.flags["continuity_broken"]:
		blood = 15 if _is_descendant_of_founder(s, s.next_successor_id) else 6
	add.call("legacy.bloodline", blood)
	score += blood
	# 승계 안정
	var succ := 0
	for r in s.succession_records:
		match r["outcome"]:
			"camp_stable", "camp_uncontested":
				succ += 8
			"camp_regency", "camp_uneasy":
				succ += 4
			"camp_disputed":
				succ -= 6
	add.call("legacy.successions", succ)
	score += succ
	# 생존 분가
	var br := mini(s.living_branches().size() * 5, 10)
	add.call("legacy.branches", br)
	score += br
	# 재산
	var est := mini(s.main_estate_ids().size() * 5, 15)
	add.call("legacy.estates", est)
	score += est
	# 혼인 — 강제 결혼은 감점.
	var mar := 0
	for m in s.marriages:
		if int(m["generation"]) >= 1:
			mar += -2 if m["forced"] else 3
	mar = clampi(mar, -6, 9)
	add.call("legacy.marriages", mar)
	score += mar
	# 결속
	var coh := 8 if s.cohesion >= 60 else (-6 if s.cohesion <= 25 else 0)
	add.call("legacy.cohesion", coh)
	score += coh
	# 부 — 상한이 낮아 부만으로 최고 유산이 될 수 없다.
	var wl := 6 if s.wealth >= 60 else (3 if s.wealth >= 30 else 0)
	add.call("legacy.wealth", wl)
	score += wl
	# 배신/미해결 추방·폐적
	var betrayals := 0
	var unresolved := 0
	var restored := 0
	for m in s.memories:
		match m["kind"]:
			"betrayal":
				betrayals -= 8
			"exile", "disinheritance":
				if m["active"]:
					unresolved -= 5
			"rights_restored":
				restored += 6
	add.call("legacy.betrayals", betrayals)
	score += betrayals
	add.call("legacy.unresolved_wounds", unresolved)
	score += unresolved
	restored = mini(restored, 12)
	add.call("legacy.rights_restored", restored)
	score += restored
	# 몰락 후 회복
	var fell := false
	for r in s.rank_history:
		if int(r["to"]) < 1:
			fell = true
	var recov := 12 if fell and s.rank >= 1 else 0
	add.call("legacy.recovery", recov)
	score += recov
	# 결과 등급
	var result_id := ""
	if score >= 80:
		result_id = "legacy_renowned_house"
	elif score >= 55:
		result_id = "legacy_firm_dynasty"
	elif score >= 30:
		result_id = "legacy_enduring_line"
	elif score >= 10:
		result_id = "legacy_diminished_house"
	else:
		result_id = "legacy_broken_dynasty"
	contributors.sort_custom(func(a, b): return int(a["value"]) > int(b["value"]))
	s.legacy_result = {
		"result_id": result_id, "score": score,
		"contributors": contributors,
		"next_successor_id": s.next_successor_id,
	}
	s.phase = CampaignState.PHASE_LEGACY
	s.log_entry(s.next_successor_id, "chron.camp_legacy_" + result_id, {}, true)
	s.record_history("legacy:" + result_id)

static func _is_descendant_of_founder(s: CampaignState, id: String) -> bool:
	# 초대 가주(c1)로부터의 직계 여부 — 부모 사슬을 너비 우선으로 추적한다.
	var frontier: Array = [id]
	var guard := 0
	while not frontier.is_empty() and guard < 32:
		guard += 1
		var cur: String = frontier.pop_front()
		if cur == "c1":
			return true
		if cur == "" or not s.has_chr(cur):
			continue
		frontier.append(s.chr(cur)["father_id"])
		frontier.append(s.chr(cur)["mother_id"])
	return false

# ---------------------------------------------------------------- 합법 입력 열거(검증/봇용)

static func legal_inputs(s: CampaignState) -> Array:
	var out: Array = []
	match s.phase:
		CampaignState.PHASE_ACTIONS:
			for entry in action_catalog(s):
				if not entry["ok"]:
					continue
				var opts: Array = entry["options"]
				if opts.is_empty():
					out.append({"type": "action", "id": entry["id"], "option": ""})
				else:
					for o in opts:
						out.append({"type": "action", "id": entry["id"], "option": o})
			out.append({"type": "end_turn"})
		CampaignState.PHASE_DILEMMA:
			for c in s.pending_dilemma["choices"]:
				if c["ok"]:
					out.append({"type": "dilemma", "id": c["id"]})
		CampaignState.PHASE_SUCCESSION:
			out.append({"type": "confirm_succession"})
	return out

# ---------------------------------------------------------------- UI 보조

static func upcoming_events(s: CampaignState) -> Array:
	var out: Array = []
	if s.turn < GEN_MIN_TURNS:
		out.append({"turn": GEN_MIN_TURNS, "key": "upcoming.camp_min_turns", "certain": true})
	else:
		out.append({"turn": s.turn, "key": "upcoming.camp_succession_window", "certain": false})
	if s.turn <= GEN_MAX_TURNS:
		out.append({"turn": GEN_MAX_TURNS, "key": "upcoming.camp_max_turns", "certain": true})
	if s.rank == 2 and s.flags["royal_levy_due"]:
		out.append({"turn": s.turn, "key": "upcoming.camp_royal_levy", "certain": true})
	return out
