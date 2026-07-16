# 캠페인 UI 텍스트 헬퍼 — 동적 인물/가문/재산 이름 해석, 친족 호칭, 연대기 렌더링, 초상 색.
class_name CampText

# id → 표시 이름 (인물/외부 가문/재산/원문).
static func name_of(s: CampaignState, id: String) -> String:
	if s != null and s.has_chr(id):
		return I18n.t(s.chr(id)["name_key"])
	if I18n.has_key(I18n.locale, "name." + id):
		return I18n.t("name." + id)
	if I18n.has_key(I18n.locale, "estate." + id):
		return I18n.t("estate." + id)
	return id

# 파라미터 사전의 id 값을 표시 이름으로 치환.
static func resolve_params(s: CampaignState, params: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in params:
		var v = params[k]
		if v is String:
			if String(v).begins_with("succcause.") or String(v).begins_with("rank."):
				out[k] = I18n.t(v)
			else:
				out[k] = name_of(s, v)
		else:
			out[k] = v
	return out

# 연대기 항목 렌더링(캠페인 전용 — 동적 인물 이름 지원).
static func chronicle_line(s: CampaignState, entry: Dictionary) -> String:
	var when := I18n.t("chron.when", {
		"year": entry["year"],
		"season": I18n.t("season." + entry["season"]),
	})
	var params := resolve_params(s, entry["params"] as Dictionary)
	params["actor"] = name_of(s, entry["actor"])
	return when + " — " + I18n.t(entry["key"], params)

# 현 가주 기준 친족 호칭 키.
static func kinship_key(s: CampaignState, id: String) -> String:
	var head := s.current_head_id
	if id == head:
		return "kin.self"
	var c: Dictionary = s.chr(id)
	var h: Dictionary = s.chr(head)
	if c["spouse_id"] == head:
		return "kin.spouse"
	if c["father_id"] == head or c["mother_id"] == head:
		return "kin.child"
	if h["father_id"] == id or h["mother_id"] == id:
		return "kin.parent"
	if h["father_id"] != "" and (c["father_id"] == h["father_id"] or (c["mother_id"] != "" and c["mother_id"] == h["mother_id"])):
		return "kin.sibling"
	if c["branch_id"] != "":
		return "kin.branch"
	if c["exiled"]:
		return "kin.exile"
	if c["role"] == "regent":
		return "kin.regent"
	return "kin.kin"

# 인물 카드 한 줄 요약: 역할 · 나이.
static func role_line(s: CampaignState, id: String) -> String:
	var c: Dictionary = s.chr(id)
	var role := str(c["role"])
	if role.begins_with("deceased_"):
		role = role.substr(9)
	return "%s · %s" % [I18n.t("role." + role), I18n.t("stat.age_years", {"years": s.age_years(id)})]

# 인물 고유 초상 색 — 이름 키 해시에서 결정론적으로 생성.
static func portrait_color(s: CampaignState, id: String) -> Color:
	if not s.has_chr(id):
		return UIStyle.MUTED
	var h := absi(str(s.chr(id)["name_key"]).hash())
	return Color.from_hsv(float(h % 360) / 360.0, 0.32 + float(h / 360 % 20) / 100.0, 0.42)

# 캠페인 인물 초상(동적 색).
static func portrait(s: CampaignState, id: String, diameter: int = 52, faded: bool = false) -> Control:
	var wrap := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	var base := portrait_color(s, id)
	if faded:
		base = base.lerp(Color("777066"), 0.7)
	sb.bg_color = base
	sb.border_color = UIStyle.GOLD if not faded else Color("847a68")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(diameter / 2)
	wrap.add_theme_stylebox_override("panel", sb)
	wrap.custom_minimum_size = Vector2(diameter, diameter)
	var l := Label.new()
	l.text = name_of(s, id).substr(0, 1)
	l.add_theme_font_size_override("font_size", int(diameter * 0.45))
	l.add_theme_color_override("font_color", Color("f4e9d2") if not faded else Color("c9c2b4"))
	l.add_theme_font_override("font", UIStyle.serif_font())
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wrap.add_child(l)
	return wrap

# 행동 옵션 표시 라벨(동적 대상).
static func option_label(s: CampaignState, action_id: String, opt: String) -> String:
	if opt.contains("|"):
		var a := opt.get_slice("|", 0)
		var b := opt.get_slice("|", 1)
		return "%s ↔ %s" % [name_of(s, a), name_of(s, b)]
	if s.has_chr(opt):
		var extra := I18n.t("stat.legal_claim") + " " + str(s.chr(opt)["legal_claim"])
		return "%s (%s, %s)" % [name_of(s, opt), I18n.t(kinship_key(s, opt)), extra]
	return name_of(s, opt)

# 기억 한 줄: 종류 — G세대 · 관련 인물.
static func memory_line(s: CampaignState, m: Dictionary) -> String:
	var names: Array = []
	for pid in m["people"]:
		names.append(name_of(s, pid))
	return I18n.t("memory.line", {
		"kind": I18n.t("memkind." + str(m["kind"])),
		"generation": m["generation"],
		"people": ", ".join(PackedStringArray(names)),
	})

# 감정 한 줄: 종류 → 대상 (강도).
static func emotion_line(s: CampaignState, e: Dictionary) -> String:
	return "%s → %s (%d)" % [I18n.t("emotion." + str(e["kind"])), name_of(s, e["target"]), int(e["intensity"])]
