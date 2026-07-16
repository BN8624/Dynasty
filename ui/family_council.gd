# 가족 회의 화면 — 인물 중심으로 딜레마의 입장/이해관계/선택지를 제시한다.
extends Control

func _ready() -> void:
	UIStyle.build_background(self)
	_build()

func _build() -> void:
	var s: SimState = Game.state
	var ev: Dictionary = s.pending_event
	if ev.is_empty():
		Game.goto(Game.screen_for_phase())
		return
	var eid: String = ev["event_id"]

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UIStyle.make_panel()
	panel.custom_minimum_size = Vector2(860, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	var head_row := HBoxContainer.new()
	head_row.add_theme_constant_override("separation", 10)
	head_row.add_child(UIStyle.heraldry(36))
	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.add_child(UIStyle.label(I18n.t("council.title"), 14, UIStyle.MUTED))
	title_col.add_child(UIStyle.label(I18n.t("event.%s.title" % eid), 24, UIStyle.WAX, true))
	head_row.add_child(title_col)
	v.add_child(head_row)
	v.add_child(UIStyle.hline())

	var desc := UIStyle.label(I18n.t("event.%s.desc" % eid), 14, UIStyle.INK)
	v.add_child(desc)
	var stakes := UIStyle.label("%s — %s" % [I18n.t("council.stakes"), I18n.t("event.%s.stakes" % eid)], 13, UIStyle.INK_SOFT)
	v.add_child(stakes)
	v.add_child(UIStyle.vspace(4))

	# 참석자와 입장
	var parts: Array = ev["participants"]
	for i in range(parts.size()):
		var pid: String = parts[i]
		if not pid.begins_with("house_") and Game.state.characters.has(pid):
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			row.add_child(UIStyle.portrait(pid, I18n.name_of(pid), 48, not s.chr(pid)["alive"]))
			var col := VBoxContainer.new()
			col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			col.add_theme_constant_override("separation", 1)
			col.add_child(UIStyle.label(I18n.name_of(pid), 15, UIStyle.INK, true))
			col.add_child(UIStyle.label("“%s”" % I18n.t("event.%s.pos.%d" % [eid, i]), 13, UIStyle.INK_SOFT))
			row.add_child(col)
			v.add_child(row)
	v.add_child(UIStyle.vspace(4))
	v.add_child(UIStyle.hline())

	# 선택지 — 알려진 직접 비용과 비활성 사유 표시
	for c in ev["choices"]:
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
		info.add_child(UIStyle.label(I18n.t("choice.%s.desc" % cid), 12, UIStyle.INK_SOFT))
		if not c["ok"]:
			info.add_child(UIStyle.label(I18n.t(c["reason"]), 12, UIStyle.WAX))
		row2.add_child(info)
		v.add_child(row2)
	v.add_child(UIStyle.vspace(2))
	v.add_child(UIStyle.label(I18n.t("council.hint"), 11, UIStyle.MUTED))

func _on_choice(choice_id: String) -> void:
	Game.choose(choice_id)
