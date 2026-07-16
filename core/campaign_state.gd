# 3세대 캠페인 정본 상태 — UI와 독립된 단일 진실 상태(가문/인물/분가/권리/기억/감정/연대기)를 보관한다.
class_name CampaignState
extends RefCounted

const PHASE_ACTIONS := "actions"
const PHASE_DILEMMA := "dilemma"
const PHASE_SUCCESSION := "succession"
const PHASE_LEGACY := "legacy"

const RANK_IDS := ["rank_minor_landed", "rank_established_regional", "rank_major_noble"]

# --- 가문 자원 (첫 플레이어블과 동일 의미역) ---
var wealth: int = 0
var debt: int = 0
var legitimacy: int = 0
var influence: int = 0
var cohesion: int = 0
var succession_stability: int = 0
var action_points: int = 0
var rank: int = 1                    # 0=하위, 1=시작, 2=상위
var rank_history: Array = []         # [{generation, turn, from, to, reason_key}]

# --- 진행 ---
var seed_value: int = 0
var rng_state: int = 0
var generation: int = 1              # 1..3
var turn: int = 1                    # 세대 내 턴
var global_turn: int = 1
var phase: String = PHASE_ACTIONS
var actions_used: Dictionary = {}
var pending_dilemma: Dictionary = {}
var current_head_id: String = ""
var formal_heir_id: String = ""
var regent_id: String = ""
var next_successor_id: String = ""   # 3차 승계에서 기록, 플레이 불가
var legacy_result: Dictionary = {}

# --- 인물/구조 ---
var characters: Dictionary = {}      # id -> dict
var relationships: Dictionary = {}   # "a|b" -> 0..100
var branches: Dictionary = {}        # id -> {id, founder_id, generation, estate_id, standing, origin_memory_id, alive}
var estates: Dictionary = {}         # id -> {id, owner}  owner: "main" | branch_id
var marriages: Array = []            # [{a, b, house_id, generation, forced}]
var ext_standing: Dictionary = {}    # 외부 가문 id -> 0..100
var claims: Array = []               # [{id, holder, kind, target, strength, origin_memory_id, active}]
var memories: Array = []             # [{id, kind, origin_key, generation, turn, people, branch_id, effect_key, active, resolved_by}]
var emotions: Array = []             # [{id, owner, kind, target, intensity, source_key, origin_memory_id}]
var flags: Dictionary = {}
var succession_records: Array = []   # [{generation, cause, outcome, old_head, new_head, evidence}]
var dilemma_history: Array = []      # [{generation, turn, structure, id, choice, beneficiaries, victims}]
var chronicle: Array = []            # [{turn, generation, year, season, actor, key, params, major}]
var history: PackedStringArray = PackedStringArray()
var input_log: PackedStringArray = PackedStringArray()
var next_serial: int = 1
var used_names: Dictionary = {}      # name_key -> true

const BOUNDED_HOUSE_FIELDS := ["legitimacy", "influence", "cohesion", "succession_stability"]
const BOUNDED_CHAR_FIELDS := ["health", "ability", "legal_claim", "ambition"]

# ---------------------------------------------------------------- RNG (결정론)

func rng_seed(v: int) -> void:
	seed_value = v
	rng_state = (v * 6364136223846793005 + 1442695040888963407) & 0x7FFFFFFFFFFFFFFF
	if rng_state == 0:
		rng_state = 88172645463325252

func rng_next() -> int:
	var x := rng_state
	x ^= (x << 13) & 0x7FFFFFFFFFFFFFFF
	x ^= x >> 7
	x ^= (x << 17) & 0x7FFFFFFFFFFFFFFF
	rng_state = x
	return x & 0x7FFFFFFFFFFF

func rng_roll(n: int) -> int:
	return 0 if n <= 0 else rng_next() % n

func rng_pct() -> int:
	return rng_roll(100)

# ---------------------------------------------------------------- 식별자/인물

func new_id(prefix: String) -> String:
	var id := "%s%d" % [prefix, next_serial]
	next_serial += 1
	return id

func chr(id: String) -> Dictionary:
	return characters[id]

func has_chr(id: String) -> bool:
	return characters.has(id)

func add_char_stat(id: String, field: String, delta: int) -> void:
	var c: Dictionary = characters[id]
	if c[field] == null:
		return
	c[field] = int(c[field]) + delta
	if field in BOUNDED_CHAR_FIELDS or field == "loyalty":
		c[field] = clampi(int(c[field]), 0, 100)

func age_years(id: String) -> int:
	return int(characters[id]["age_months"]) / 12

func is_adult(id: String) -> bool:
	return age_years(id) >= 16

func alive_in_house(id: String) -> bool:
	if not characters.has(id):
		return false
	var c: Dictionary = characters[id]
	return c["alive"] and c["in_house"]

# 정렬된 id 목록 — 결정론적 순회용.
func sorted_char_ids() -> Array:
	var ids: Array = characters.keys()
	ids.sort()
	return ids

func children_of(parent_id: String) -> Array:
	var out: Array = []
	for id in sorted_char_ids():
		var c: Dictionary = characters[id]
		if c["father_id"] == parent_id or c["mother_id"] == parent_id:
			out.append(id)
	# 연장자 우선 정렬(나이 내림차순, 동률은 id).
	out.sort_custom(func(a, b):
		var am: int = int(characters[a]["age_months"])
		var bm: int = int(characters[b]["age_months"])
		return am > bm if am != bm else a < b)
	return out

func spouse_of(id: String) -> String:
	var sid: String = characters[id]["spouse_id"]
	if sid != "" and characters.has(sid) and characters[sid]["alive"]:
		return sid
	return ""

# ---------------------------------------------------------------- 관계

static func rel_key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a

func get_rel(a: String, b: String) -> int:
	return int(relationships.get(rel_key(a, b), 50))

func set_rel(a: String, b: String, value: int) -> void:
	relationships[rel_key(a, b)] = clampi(value, 0, 100)

func add_rel(a: String, b: String, delta: int) -> void:
	set_rel(a, b, get_rel(a, b) + delta)

# ---------------------------------------------------------------- 기억/감정/권리

const MAX_ACTIVE_MEMORIES := 10
const MAX_EMOTIONS_PER_CHAR := 3

func add_memory(kind: String, origin_key: String, people: Array, branch_id: String = "", effect_key: String = "") -> String:
	var id := new_id("mem")
	memories.append({
		"id": id, "kind": kind, "origin_key": origin_key,
		"generation": generation, "turn": turn, "people": people.duplicate(),
		"branch_id": branch_id, "effect_key": effect_key if effect_key != "" else "memeffect." + kind,
		"active": true, "resolved_by": "",
	})
	# 상한 유지: 가장 오래된 활성 기억을 퇴색시킨다.
	var active_ids: Array = []
	for m in memories:
		if m["active"]:
			active_ids.append(m)
	while active_ids.size() > MAX_ACTIVE_MEMORIES:
		var oldest: Dictionary = active_ids.pop_front()
		oldest["active"] = false
		oldest["resolved_by"] = "faded"
	return id

func resolve_memory(mem_id: String, resolved_by: String) -> void:
	for m in memories:
		if m["id"] == mem_id:
			m["active"] = false
			m["resolved_by"] = resolved_by
			return

func active_memories() -> Array:
	var out: Array = []
	for m in memories:
		if m["active"]:
			out.append(m)
	return out

func memory_by_id(mem_id: String) -> Dictionary:
	for m in memories:
		if m["id"] == mem_id:
			return m
	return {}

func add_emotion(owner: String, kind: String, target: String, intensity: int, source_key: String, origin_memory_id: String = "") -> void:
	# 동일 (owner, kind, target)은 강화로 처리한다.
	for e in emotions:
		if e["owner"] == owner and e["kind"] == kind and e["target"] == target:
			e["intensity"] = clampi(int(e["intensity"]) + intensity / 2, 0, 100)
			return
	emotions.append({
		"id": new_id("emo"), "owner": owner, "kind": kind, "target": target,
		"intensity": clampi(intensity, 0, 100), "source_key": source_key,
		"origin_memory_id": origin_memory_id,
	})
	# 인당 상한: 가장 약한 감정을 제거.
	var mine: Array = []
	for e in emotions:
		if e["owner"] == owner:
			mine.append(e)
	if mine.size() > MAX_EMOTIONS_PER_CHAR:
		mine.sort_custom(func(a, b): return int(a["intensity"]) < int(b["intensity"]))
		emotions.erase(mine[0])

func emotions_of(owner: String) -> Array:
	var out: Array = []
	for e in emotions:
		if e["owner"] == owner:
			out.append(e)
	return out

func emotion_intensity(owner: String, kind: String, target: String) -> int:
	for e in emotions:
		if e["owner"] == owner and e["kind"] == kind and e["target"] == target:
			return int(e["intensity"])
	return 0

func add_claim(holder: String, kind: String, target: String, strength: int, origin_memory_id: String = "") -> String:
	var id := new_id("clm")
	claims.append({
		"id": id, "holder": holder, "kind": kind, "target": target,
		"strength": clampi(strength, 0, 100), "origin_memory_id": origin_memory_id, "active": true,
	})
	return id

func active_claims() -> Array:
	var out: Array = []
	for c in claims:
		if c["active"]:
			out.append(c)
	return out

func claim_of(holder: String, kind: String) -> Dictionary:
	for c in claims:
		if c["active"] and c["holder"] == holder and c["kind"] == kind:
			return c
	return {}

# ---------------------------------------------------------------- 재산/분가

func main_estate_ids() -> Array:
	var out: Array = []
	var ids: Array = estates.keys()
	ids.sort()
	for id in ids:
		if estates[id]["owner"] == "main":
			out.append(id)
	return out

func living_branches() -> Array:
	var out: Array = []
	var ids: Array = branches.keys()
	ids.sort()
	for id in ids:
		if branches[id]["alive"]:
			out.append(branches[id])
	return out

# ---------------------------------------------------------------- 경계/시간

func clamp_all() -> void:
	legitimacy = clampi(legitimacy, 0, 100)
	influence = clampi(influence, 0, 100)
	cohesion = clampi(cohesion, 0, 100)
	succession_stability = clampi(succession_stability, 0, 100)
	wealth = clampi(wealth, -30, 150)
	debt = maxi(debt, 0)
	rank = clampi(rank, 0, 2)
	action_points = clampi(action_points, 0, 2)
	for id in characters:
		var c: Dictionary = characters[id]
		for f in BOUNDED_CHAR_FIELDS:
			c[f] = clampi(int(c[f]), 0, 100)
		if c["loyalty"] != null:
			c["loyalty"] = clampi(int(c["loyalty"]), 0, 100)
	for h in ext_standing:
		ext_standing[h] = clampi(int(ext_standing[h]), 0, 100)

func year() -> int:
	return int(ceil(global_turn / 2.0))

func season() -> String:
	return "spring" if global_turn % 2 == 1 else "autumn"

func log_entry(actor: String, key: String, params: Dictionary = {}, major: bool = false) -> void:
	chronicle.append({
		"turn": turn, "generation": generation, "year": year(), "season": season(),
		"actor": actor, "key": key, "params": params, "major": major,
	})

func major_entries() -> Array:
	var out: Array = []
	for e in chronicle:
		if e["major"]:
			out.append(e)
	return out

# ---------------------------------------------------------------- 결정론 직렬화

func snapshot_string() -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append("G%d T%d GT%d P%s SEED%d RNG%d W%d D%d L%d I%d C%d S%d R%d AP%d H%s FH%s RG%s NS%s" % [
		generation, turn, global_turn, phase, seed_value, rng_state, wealth, debt,
		legitimacy, influence, cohesion, succession_stability, rank, action_points,
		current_head_id, formal_heir_id, regent_id, next_successor_id])
	for id in sorted_char_ids():
		var c: Dictionary = characters[id]
		var loy: String = "-" if c["loyalty"] == null else str(c["loyalty"])
		parts.append("%s %s a%d %s%s%s%s h%d ab%d lc%d lo%s am%d r%s f%s m%s sp%s b%s" % [
			id, c["name_key"], c["age_months"], "1" if c["alive"] else "0",
			"1" if c["in_house"] else "0", "1" if c["exiled"] else "0",
			"1" if c["disinherited"] else "0",
			c["health"], c["ability"], c["legal_claim"], loy, c["ambition"], c["role"],
			c["father_id"], c["mother_id"], c["spouse_id"], c["branch_id"]])
	var rkeys: Array = relationships.keys()
	rkeys.sort()
	for k in rkeys:
		parts.append("%s=%d" % [k, relationships[k]])
	var bkeys: Array = branches.keys()
	bkeys.sort()
	for k in bkeys:
		var b: Dictionary = branches[k]
		parts.append("BR %s f%s g%d e%s s%d %s" % [k, b["founder_id"], b["generation"], b["estate_id"], b["standing"], "1" if b["alive"] else "0"])
	var ekeys: Array = estates.keys()
	ekeys.sort()
	for k in ekeys:
		parts.append("ES %s=%s" % [k, estates[k]["owner"]])
	for m in marriages:
		parts.append("MA %s+%s %s g%d %s" % [m["a"], m["b"], m["house_id"], m["generation"], "1" if m["forced"] else "0"])
	var xkeys: Array = ext_standing.keys()
	xkeys.sort()
	for k in xkeys:
		parts.append("XS %s=%d" % [k, ext_standing[k]])
	for c in claims:
		parts.append("CL %s %s %s %s s%d %s" % [c["id"], c["holder"], c["kind"], c["target"], c["strength"], "1" if c["active"] else "0"])
	for m in memories:
		parts.append("ME %s %s g%d %s %s %s" % [m["id"], m["kind"], m["generation"], ",".join(PackedStringArray(m["people"])), "1" if m["active"] else "0", m["resolved_by"]])
	for e in emotions:
		parts.append("EM %s %s %s>%s i%d" % [e["id"], e["kind"], e["owner"], e["target"], e["intensity"]])
	var fkeys: Array = flags.keys()
	fkeys.sort()
	for k in fkeys:
		parts.append("%s=%s" % [k, str(flags[k])])
	for r in rank_history:
		parts.append("RH g%d t%d %d>%d" % [r["generation"], r["turn"], r["from"], r["to"]])
	for r in succession_records:
		parts.append("SR g%d %s %s %s>%s" % [r["generation"], r["cause"], r["outcome"], r["old_head"], r["new_head"]])
	return "; ".join(parts)

func record_history(tag: String) -> void:
	history.append(tag + " :: " + snapshot_string())

func digest() -> String:
	return ("\n".join(history)).md5_text()
