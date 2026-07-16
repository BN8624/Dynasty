# 캠페인 가족 회의 — 딜레마의 원인/관련 인물/이해득실/위험을 인물 중심으로 제시한다.
extends Control

func _ready() -> void:
	UIStyle.build_background(self)
	_build()

func _build() -> void:
	var s: CampaignState = Game.camp
	var dlm: Dictionary = s.pending_dilemma
	if dlm.is_empty():
		Game.goto(Game.camp_screen_for_phase())
		return
	var structure: String = dlm["structure"]

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UIStyle.make_panel()
	panel.custom_minimum_size = Vector2(900, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	panel.add_child(v)

	var head_row := HBoxContainer.new()
	head_row.add_theme_constant_override("separation", 10)
	head_row.add_child(UIStyle.heraldry(36))
	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.add_child(UIStyle.label(I18n.t("council.title"), 14, UIStyle.MUTED))
	title_col.add_child(UIStyle.label(I18n.t(dlm["title_key"]), 24, UIStyle.WAX, true))
	head_row.add_child(title_col)
	v.add_child(head_row)
	v.add_child(UIStyle.hline())

	var params := CampText.resolve_params(s, dlm["cause_params"] as Dictionary)
	v.add_child(UIStyle.label(I18n.t(dlm["desc_key"], params), 14, UIStyle.INK))
	# 갈등의 근거(권리/의무/기억).
	v.add_child(UIStyle.label("%s — %s" % [I18n.t("council.cause"),
		I18n.t(dlm["cause_key"], params)], 13, UIStyle.INK_SOFT))
	# 이전 세대 기억이 원인인 경우 원사건을 노출한다.
	if dlm["origin_memory_id"] != "":
		var m := s.memory_by_id(dlm["origin_memory_id"])
		if not m.is_empty():
			v.add_child(UIStyle.label("%s %s" % [I18n.t("council.memory_origin"),
				CampText.memory_line(s, m)], 13, UIStyle.WAX))
	v.add_child(UIStyle.vspace(2))

	# 관련 인물: 이름/가주와의 관계/관련 권리/입장.
	var parts: Array = dlm["participants"]
	for i in range(parts.size()):
		var pid: String = parts[i]
		if not s.has_chr(pid):
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.add_child(CampText.portrait(s, pid, 44, not s.chr(pid)["alive"]))
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 1)
		var name_line := "%s · %s" % [CampText.name_of(s, pid), I18n.t(CampText.kinship_key(s, pid))]
		var cl := s.claim_of(pid, "succession")
		if not cl.is_empty():
			name_line += " · %s %d" % [I18n.t("ui.claim_strength"), int(cl["strength"])]
		col.add_child(UIStyle.label(name_line, 15, UIStyle.INK, true))
		var pos_key := "dlm.%s.pos.%d" % [structure, i]
		if I18n.has_key(I18n.locale, pos_key):
			col.add_child(UIStyle.label("“%s”" % I18n.t(pos_key, params), 13, UIStyle.INK_SOFT))
		row.add_child(col)
		v.add_child(row)
	v.add_child(UIStyle.vspace(2))
	v.add_child(UIStyle.hline())

	# 선택지: 즉각 결과/수혜자/피해자/가시적 위험, 비활성 사유.
	for c in dlm["choices"]:
		var cid: String = c["id"]
		var row2 := HBoxContainer.new()
		row2.add_theme_constant_override("separation", 10)
		var btn := UIStyle.button(I18n.t("choice.%s.title" % cid), true, 15)
		btn.custom_minimum_size = Vector2(230, 0)
		btn.disabled = not c["ok"]
		btn.pressed.connect(_on_choice.bind(cid))
		row2.add_child(btn)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 1)
		info.add_child(UIStyle.label(I18n.t("choice.%s.desc" % cid, params), 12, UIStyle.INK_SOFT))
		var who := ""
		if not (c["benefit"] as Array).is_empty():
			who += "%s %s" % [I18n.t("council.benefits"), _names(s, c["benefit"])]
		if not (c["harm"] as Array).is_empty():
			who += ("   " if who != "" else "") + "%s %s" % [I18n.t("council.harms"), _names(s, c["harm"])]
		if who != "":
			info.add_child(UIStyle.label(who, 11, UIStyle.MUTED))
		info.add_child(UIStyle.label("%s %s" % [I18n.t("council.risk"), I18n.t(c["risk_key"])], 11, UIStyle.WAX))
		if not c["ok"]:
			info.add_child(UIStyle.label(I18n.t(c["reason"]), 12, UIStyle.WAX))
		row2.add_child(info)
		v.add_child(row2)
	v.add_child(UIStyle.label(I18n.t("council.hint"), 11, UIStyle.MUTED))

func _names(s: CampaignState, ids: Array) -> String:
	var out: Array = []
	for id in ids:
		if id != "":
			out.append(CampText.name_of(s, id))
	return ", ".join(PackedStringArray(out))

func _on_choice(choice_id: String) -> void:
	Game.camp_choose(choice_id)
