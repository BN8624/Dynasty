# 캠페인 집무실 — 3세대 캠페인의 기본 관리 화면. 가족/가문/랭크/기억/행동/연대기를 제공한다.
extends Control

var _content: MarginContainer = null

func _ready() -> void:
	UIStyle.build_background(self)
	_rebuild()

func _rebuild() -> void:
	if _content != null:
		_content.queue_free()
	_content = MarginContainer.new()
	_content.name = "OfficeContent"
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.add_theme_constant_override("margin_left", 14)
	_content.add_theme_constant_override("margin_right", 14)
	_content.add_theme_constant_override("margin_top", 10)
	_content.add_theme_constant_override("margin_bottom", 10)
	add_child(_content)
	var v := VBoxContainer.new()
	v.name = "OfficeLayout"
	v.add_theme_constant_override("separation", 8)
	_content.add_child(v)
	v.add_child(_header())
	var main := HBoxContainer.new()
	main.name = "OfficeMain"
	main.add_theme_constant_override("separation", 8)
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(main)
	main.add_child(_family_column())
	main.add_child(_center_column())
	main.add_child(_right_column())
	v.add_child(_bottom_bar())

# ---------------------------------------------------------------- header

func _header() -> Control:
	var s: CampaignState = Game.camp
	var panel := UIStyle.make_panel(UIStyle.PARCHMENT_DARK)
	panel.name = "OfficeHeader"
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	panel.add_child(h)
	h.add_child(UIStyle.heraldry(40))
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(360, 0)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	name_row.add_child(UIStyle.label(I18n.name_of("house_arven"), 20, UIStyle.WAX, true))
	name_row.add_child(UIStyle.badge(I18n.t(CampaignState.RANK_IDS[s.rank]), UIStyle.GOLD))
	left.add_child(name_row)
	left.add_child(UIStyle.label(I18n.t("ui.camp_turn_line",
		{"generation": s.generation, "turn": s.turn, "year": s.year(),
		"season": I18n.t("season." + s.season())}), 14, UIStyle.INK_SOFT))
	h.add_child(left)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(spacer)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(300, 0)
	var ap := UIStyle.label(I18n.t("ui.action_points", {"ap": s.action_points}), 16, UIStyle.WAX, true)
	ap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(ap)
	var head := UIStyle.label(I18n.t("ui.head_line", {"name": CampText.name_of(s, s.current_head_id)}), 13, UIStyle.INK)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(head)
	var heir_text: String = I18n.t("ui.heir_line", {"name": CampText.name_of(s, s.formal_heir_id)}) \
		if s.formal_heir_id != "" else I18n.t("ui.heir_none")
	var heir := UIStyle.label(heir_text, 13, UIStyle.INK)
	heir.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(heir)
	h.add_child(right)
	return panel

# ---------------------------------------------------------------- family column

# 표시 순서: 가주 → 배우자 → 자녀 → 본가 구성원 → 분가 가주 → 추방자.
func _family_ids() -> Array:
	var s: CampaignState = Game.camp
	var out: Array = [s.current_head_id]
	var sp := s.spouse_of(s.current_head_id)
	if sp != "":
		out.append(sp)
	for cid in s.children_of(s.current_head_id):
		if s.chr(cid)["alive"] and not (cid in out):
			out.append(cid)
	for cid in s.sorted_char_ids():
		var c: Dictionary = s.chr(cid)
		if c["alive"] and c["in_house"] and c["branch_id"] == "" and not (cid in out):
			out.append(cid)
	for b in s.living_branches():
		if s.chr(b["founder_id"])["alive"] and not (b["founder_id"] in out):
			out.append(b["founder_id"])
	for cid in s.sorted_char_ids():
		var c: Dictionary = s.chr(cid)
		if c["alive"] and c["exiled"] and not (cid in out):
			out.append(cid)
	return out

func _family_column() -> Control:
	var panel := UIStyle.make_panel()
	panel.custom_minimum_size = Vector2(310, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	v.add_child(UIStyle.label(I18n.t("ui.family"), 17, UIStyle.WAX, true))
	v.add_child(UIStyle.hline())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	for id in _family_ids():
		list.add_child(_char_card(id))
	return panel

func _char_card(id: String) -> Control:
	var s: CampaignState = Game.camp
	var c: Dictionary = s.chr(id)
	var faded: bool = (not c["alive"]) or c["exiled"]
	var card := UIStyle.make_panel(UIStyle.PARCHMENT_DARK if not faded else Color("cfc4ad"), UIStyle.GOLD_SOFT)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	card.add_child(h)
	h.add_child(CampText.portrait(s, id, 48, faded))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	h.add_child(v)
	v.add_child(UIStyle.label(CampText.name_of(s, id), 15, UIStyle.INK, true))
	v.add_child(UIStyle.label("%s · %s" % [I18n.t(CampText.kinship_key(s, id)),
		CampText.role_line(s, id)], 12, UIStyle.MUTED))
	var badges := HBoxContainer.new()
	badges.add_theme_constant_override("separation", 4)
	if not c["alive"]:
		badges.add_child(UIStyle.badge(I18n.t("char.dead"), UIStyle.INK_SOFT))
	if id == s.current_head_id and c["alive"]:
		badges.add_child(UIStyle.badge(I18n.t("gen.badge.head"), UIStyle.WAX))
	if id == s.formal_heir_id:
		badges.add_child(UIStyle.badge(I18n.t("gen.badge.heir"), UIStyle.GOLD))
	if id == s.regent_id:
		badges.add_child(UIStyle.badge(I18n.t("badge.regent"), UIStyle.GOLD))
	if not s.claim_of(id, "succession").is_empty():
		badges.add_child(UIStyle.badge(I18n.t("gen.badge.claimant"), UIStyle.INK_SOFT))
	if c["branch_id"] != "":
		badges.add_child(UIStyle.badge(I18n.t("badge.branch"), UIStyle.INK_SOFT))
	if c["exiled"]:
		badges.add_child(UIStyle.badge(I18n.t("badge.exiled"), UIStyle.INK_SOFT))
	if c["disinherited"]:
		badges.add_child(UIStyle.badge(I18n.t("badge.disinherited"), UIStyle.INK_SOFT))
	if badges.get_child_count() > 0:
		v.add_child(badges)
	var stats := "%s %d · %s %d · %s %d" % [
		I18n.t("stat.health"), c["health"], I18n.t("stat.ability"), c["ability"],
		I18n.t("stat.legal_claim"), c["legal_claim"]]
	v.add_child(UIStyle.label(stats, 12, UIStyle.INK_SOFT))
	var line2 := ""
	if c["loyalty"] != null:
		line2 += "%s %d" % [I18n.t("stat.loyalty"), c["loyalty"]]
	line2 += ("" if line2 == "" else " · ") + "%s %d" % [I18n.t("stat.ambition"), c["ambition"]]
	v.add_child(UIStyle.label(line2, 12, UIStyle.INK_SOFT))
	for e in s.emotions_of(id):
		v.add_child(UIStyle.label(CampText.emotion_line(s, e), 11, UIStyle.WAX))
	return card

# ---------------------------------------------------------------- center column

func _center_column() -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	col.add_child(_house_panel())
	col.add_child(_actions_panel())
	return col

func _house_panel() -> Control:
	var s: CampaignState = Game.camp
	var panel := UIStyle.make_panel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	v.add_child(UIStyle.label(I18n.t("ui.house_state"), 17, UIStyle.WAX, true))
	v.add_child(UIStyle.hline())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 2)
	v.add_child(grid)
	var entries := [
		["stat.wealth", str(s.wealth)],
		["stat.debt", str(s.debt)],
		["stat.legitimacy", "%d / 100" % s.legitimacy],
		["stat.influence", "%d / 100" % s.influence],
		["stat.cohesion", "%d / 100" % s.cohesion],
		["stat.succession_stability", "%d / 100" % s.succession_stability],
		["stat.estate_count", str(s.main_estate_ids().size())],
		["stat.rank", I18n.t(CampaignState.RANK_IDS[s.rank])],
	]
	for e in entries:
		var row := UIStyle.stat_row(I18n.t(e[0]), e[1])
		row.custom_minimum_size = Vector2(190, 0)
		grid.add_child(row)
	return panel

func _actions_panel() -> Control:
	var s: CampaignState = Game.camp
	var panel := UIStyle.make_panel()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	v.add_child(UIStyle.label(I18n.t("ui.actions_panel"), 17, UIStyle.WAX, true))
	v.add_child(UIStyle.hline())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for entry in CampaignRules.action_catalog(s):
		list.add_child(_action_row(entry))
	return panel

func _action_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var id: String = entry["id"]
	var btn := UIStyle.button(I18n.t("action.%s.title" % id), false, 14)
	btn.custom_minimum_size = Vector2(180, 0)
	btn.disabled = not entry["ok"]
	btn.pressed.connect(_on_action_pressed.bind(id, entry["options"]))
	row.add_child(btn)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 1)
	info.add_child(UIStyle.label(I18n.t("action.%s.desc" % id), 12, UIStyle.INK_SOFT))
	if not entry["ok"]:
		info.add_child(UIStyle.label(I18n.t(entry["reason"]), 12, UIStyle.WAX))
	row.add_child(info)
	return row

func _on_action_pressed(id: String, options: Array) -> void:
	if options.is_empty():
		Game.camp_do_action(id)
		if Game.camp.phase == CampaignState.PHASE_ACTIONS:
			_rebuild()
		return
	_open_option_overlay(id, options)

# 대상 선택 오버레이 — 옵션 라벨은 상태에서 동적으로 만든다.
func _open_option_overlay(action_id: String, options: Array) -> void:
	var s: CampaignState = Game.camp
	var overlay := Control.new()
	overlay.name = "OptionOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := UIStyle.make_panel()
	panel.custom_minimum_size = Vector2(460, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	v.add_child(UIStyle.label(I18n.t("action.%s.title" % action_id), 18, UIStyle.WAX, true))
	v.add_child(UIStyle.label(I18n.t("ui.choose_option"), 13, UIStyle.MUTED))
	v.add_child(UIStyle.hline())
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, mini(options.size() * 52, 420))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for opt in options:
		var b := UIStyle.button(CampText.option_label(s, action_id, opt), true, 14)
		b.pressed.connect(_on_option_chosen.bind(action_id, opt, overlay))
		list.add_child(b)
	var cancel := UIStyle.button(I18n.t("ui.cancel"), false, 13)
	cancel.pressed.connect(overlay.queue_free)
	v.add_child(cancel)
	add_child(overlay)

func _on_option_chosen(action_id: String, opt: String, overlay: Control) -> void:
	overlay.queue_free()
	Game.camp_do_action(action_id, opt)
	if Game.camp.phase == CampaignState.PHASE_ACTIONS:
		_rebuild()

# ---------------------------------------------------------------- right column

func _right_column() -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(330, 0)
	col.add_theme_constant_override("separation", 8)
	col.add_child(_obligations_panel())
	col.add_child(_memories_panel())
	col.add_child(_chronicle_panel())
	return col

func _obligations_panel() -> Control:
	var s: CampaignState = Game.camp
	var panel := UIStyle.make_panel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	panel.add_child(v)
	v.add_child(UIStyle.label(I18n.t("ui.obligations_panel"), 15, UIStyle.WAX, true))
	v.add_child(UIStyle.hline())
	for ev in CampaignRules.upcoming_events(s):
		var text: String = I18n.t("upcoming.line", {"turn": ev["turn"], "text": I18n.t(ev["key"])})
		var color: Color = UIStyle.WAX if ev["certain"] else UIStyle.INK_SOFT
		v.add_child(UIStyle.label(text, 12, color))
	if s.flags["obligation_house"] != "":
		v.add_child(UIStyle.label(I18n.t("focus.camp_obligation",
			{"house": CampText.name_of(s, s.flags["obligation_house"])}), 12, UIStyle.WAX))
	return panel

# 활성 가문 기억 — 원인 사건/세대/관련 인물/현재 효과를 노출한다.
func _memories_panel() -> Control:
	var s: CampaignState = Game.camp
	var panel := UIStyle.make_panel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	panel.add_child(v)
	v.add_child(UIStyle.label(I18n.t("ui.memories_panel"), 15, UIStyle.WAX, true))
	v.add_child(UIStyle.hline())
	var mems := s.active_memories()
	if mems.is_empty():
		v.add_child(UIStyle.label(I18n.t("ui.no_memories"), 12, UIStyle.MUTED))
	for m in mems.slice(0, 6):
		v.add_child(UIStyle.label(CampText.memory_line(s, m), 12, UIStyle.INK_SOFT))
		v.add_child(UIStyle.label("  " + I18n.t(m["effect_key"]), 11, UIStyle.MUTED))
	return panel

func _chronicle_panel() -> Control:
	var s: CampaignState = Game.camp
	var panel := UIStyle.make_panel()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	panel.add_child(v)
	v.add_child(UIStyle.label(I18n.t("ui.chronicle_panel"), 15, UIStyle.WAX, true))
	v.add_child(UIStyle.hline())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	var entries: Array = s.chronicle.duplicate()
	entries.reverse()
	for e in entries.slice(0, 12):
		list.add_child(UIStyle.label(CampText.chronicle_line(s, e), 12, UIStyle.INK_SOFT))
	return panel

# ---------------------------------------------------------------- bottom bar

func _bottom_bar() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var gen := UIStyle.button(I18n.t("ui.genealogy"), false, 15)
	gen.pressed.connect(func() -> void: Game.goto("camp_genealogy"))
	h.add_child(gen)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(spacer)
	var seed_l := UIStyle.label(I18n.t("ui.seed_line", {"seed": Game.camp.seed_value}), 12, Color("8a7a5f"))
	seed_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(seed_l)
	var end_btn := UIStyle.button(I18n.t("ui.end_turn"), true, 18)
	end_btn.pressed.connect(func() -> void: Game.camp_end_turn())
	h.add_child(end_btn)
	return h
