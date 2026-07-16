# 시뮬레이션 정본 상태 모델 — UI와 독립된 단일 진실 상태(가문/인물/관계/플래그/연대기)를 보관한다.
class_name SimState
extends RefCounted

# --- Phases ---
const PHASE_ACTIONS := "actions"
const PHASE_EVENT := "event"
const PHASE_SUCCESSION := "succession"
const PHASE_OVER := "over"

# --- House state (canon 8.1) ---
var wealth: int = 0
var debt: int = 0
var legitimacy: int = 0
var influence: int = 0
var cohesion: int = 0
var succession_stability: int = 0
var estate_count: int = 0
var action_points: int = 0
var formal_heir_id: String = ""      # "" = null
var current_head_id: String = ""
var turn: int = 1
var seed_value: int = 0
var succession_outcome_id: String = ""  # "" = null
var terminal_result_id: String = ""     # "" = null

# --- Characters (canon 8.2): id -> Dictionary ---
var characters: Dictionary = {}

# --- Relationships (canon 8.3): sorted "a|b" -> int ---
var relationships: Dictionary = {}

# --- Scenario flags (canon 8.4) ---
var flags: Dictionary = {}

# --- Runtime bookkeeping ---
var phase: String = PHASE_ACTIONS
var actions_used: Dictionary = {}        # action_id -> true, cleared each turn
var pending_event: Dictionary = {}       # {event_id, choices:[...], participants:[...]}
var succession_evidence: Dictionary = {}
var chronicle: Array = []                # [{turn, actor, key, params, major}]
var history: PackedStringArray = PackedStringArray()

const BOUNDED_HOUSE_FIELDS := ["legitimacy", "influence", "cohesion", "succession_stability"]
const BOUNDED_CHAR_FIELDS := ["health", "ability", "legal_claim", "ambition"]

static func rel_key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a

func get_rel(a: String, b: String) -> int:
	return int(relationships.get(rel_key(a, b), 0))

func set_rel(a: String, b: String, value: int) -> void:
	relationships[rel_key(a, b)] = clampi(value, 0, 100)

func add_rel(a: String, b: String, delta: int) -> void:
	set_rel(a, b, get_rel(a, b) + delta)

func chr(id: String) -> Dictionary:
	return characters[id]

func add_char_stat(id: String, field: String, delta: int) -> void:
	var c: Dictionary = characters[id]
	if c[field] == null:
		return
	c[field] = int(c[field]) + delta
	if field in BOUNDED_CHAR_FIELDS or field == "loyalty":
		c[field] = clampi(int(c[field]), 0, 100)

func clamp_all() -> void:
	legitimacy = clampi(legitimacy, 0, 100)
	influence = clampi(influence, 0, 100)
	cohesion = clampi(cohesion, 0, 100)
	succession_stability = clampi(succession_stability, 0, 100)
	debt = maxi(debt, 0)
	estate_count = maxi(estate_count, 0)
	action_points = clampi(action_points, 0, 2)
	for id in characters:
		var c: Dictionary = characters[id]
		for f in BOUNDED_CHAR_FIELDS:
			c[f] = clampi(int(c[f]), 0, 100)
		if c["loyalty"] != null:
			c["loyalty"] = clampi(int(c["loyalty"]), 0, 100)

func year() -> int:
	return int(ceil(turn / 2.0))

func season() -> String:
	return "spring" if turn % 2 == 1 else "autumn"

func log_entry(actor: String, key: String, params: Dictionary = {}, major: bool = false) -> void:
	chronicle.append({
		"turn": turn, "year": year(), "season": season(),
		"actor": actor, "key": key, "params": params, "major": major,
	})

func major_choices() -> Array:
	var out: Array = []
	for e in chronicle:
		if e["major"]:
			out.append(e)
	return out

func eligible_next_heir_id() -> String:
	# 정본 17.1 — 생존, 가문 내, 현 가주가 아님, legal_claim >= 1.
	# 잠긴 시나리오에서는 생존한 비가주 형제만 이 규칙을 충족할 수 있다.
	for id in ["aldren_arven", "rowen_arven"]:
		var c: Dictionary = characters[id]
		if c["alive"] and c["in_house"] and id != current_head_id and int(c["legal_claim"]) >= 1:
			return id
	return ""

# --- Determinism: canonical serialization, history, digest ---

func snapshot_string() -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append("T%d P%s W%d D%d L%d I%d C%d S%d E%d AP%d H%s FH%s SO%s TR%s" % [
		turn, phase, wealth, debt, legitimacy, influence, cohesion,
		succession_stability, estate_count, action_points,
		current_head_id, formal_heir_id, succession_outcome_id, terminal_result_id])
	var cids: Array = characters.keys()
	cids.sort()
	for id in cids:
		var c: Dictionary = characters[id]
		var loy: String = "-" if c["loyalty"] == null else str(c["loyalty"])
		parts.append("%s a%d %s %s h%d ab%d lc%d lo%s am%d r%s" % [
			id, c["age_months"], "1" if c["alive"] else "0", "1" if c["in_house"] else "0",
			c["health"], c["ability"], c["legal_claim"], loy, c["ambition"], c["role"]])
	var rkeys: Array = relationships.keys()
	rkeys.sort()
	for k in rkeys:
		parts.append("%s=%d" % [k, relationships[k]])
	var fkeys: Array = flags.keys()
	fkeys.sort()
	for k in fkeys:
		parts.append("%s=%s" % [k, str(flags[k])])
	return "; ".join(parts)

func record_history(tag: String) -> void:
	history.append(tag + " :: " + snapshot_string())

func digest() -> String:
	return ("\n".join(history)).md5_text()
