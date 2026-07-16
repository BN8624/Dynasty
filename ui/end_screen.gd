# 종료 화면 — 최종 결과, 원인, 마지막 가문 상태, 승계, 주요 선택, 시드, 재시작.
extends Control

func _ready() -> void:
	UIStyle.build_background(self)
	_build()

func _build() -> void:
	var s: SimState = Game.state
	var rid: String = s.terminal_result_id
	var is_victory := rid.begins_with("victory_")

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UIStyle.make_panel()
	panel.custom_minimum_size = Vector2(880, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	var cls := UIStyle.label(I18n.t("end.class_victory" if is_victory else "end.class_defeat"),
		16, UIStyle.GOOD if is_victory else UIStyle.WAX, true)
	cls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cls)
	var title := UIStyle.label(I18n.t("result.%s.title" % rid), 30, UIStyle.WAX, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var desc := UIStyle.label(I18n.t("result.%s.desc" % rid), 14, UIStyle.INK)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(desc)
	var id_line := UIStyle.label("%s: %s   ·   %s" % [I18n.t("end.result_label"), rid,
		I18n.t("ui.seed_line", {"seed": s.seed_value})], 12, UIStyle.MUTED)
	id_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(id_line)
	v.add_child(UIStyle.hline())

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 10)
	v.add_child(cols)

	# 최종 가문 상태
	var state_panel := UIStyle.make_panel(UIStyle.PARCHMENT_DARK, UIStyle.GOLD_SOFT)
	state_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 2)
	state_panel.add_child(sv)
	sv.add_child(UIStyle.label(I18n.t("end.final_state"), 15, UIStyle.INK, true))
	sv.add_child(UIStyle.hline())
	for e in [["stat.wealth", str(s.wealth)], ["stat.debt", str(s.debt)],
			["stat.legitimacy", str(s.legitimacy)], ["stat.influence", str(s.influence)],
			["stat.cohesion", str(s.cohesion)], ["stat.succession_stability", str(s.succession_stability)],
			["stat.estate_count", str(s.estate_count)]]:
		sv.add_child(UIStyle.stat_row(I18n.t(e[0]), e[1], 13))
	sv.add_child(UIStyle.vspace(4))
	sv.add_child(UIStyle.label(I18n.t("end.succession_title"), 15, UIStyle.INK, true))
	sv.add_child(UIStyle.hline())
	if s.succession_outcome_id != "":
		sv.add_child(UIStyle.label(I18n.t("outcome." + s.succession_outcome_id), 13, UIStyle.INK_SOFT))
		sv.add_child(UIStyle.label(I18n.t("ui.head_line", {"name": I18n.name_of(s.current_head_id)}), 13, UIStyle.INK_SOFT))
	else:
		sv.add_child(UIStyle.label(I18n.t("end.no_succession"), 13, UIStyle.INK_SOFT))
	cols.add_child(state_panel)

	# 주요 선택 연대기
	var choice_panel := UIStyle.make_panel(UIStyle.PARCHMENT_DARK, UIStyle.GOLD_SOFT)
	choice_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_panel.custom_minimum_size = Vector2(430, 300)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 2)
	choice_panel.add_child(cv)
	cv.add_child(UIStyle.label(I18n.t("end.major_choices"), 15, UIStyle.INK, true))
	cv.add_child(UIStyle.hline())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cv.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)
	for e in s.major_choices():
		list.add_child(UIStyle.label(I18n.chronicle_line(e), 12, UIStyle.INK_SOFT))
	cols.add_child(choice_panel)

	v.add_child(UIStyle.vspace(2))
	var hint := UIStyle.label(I18n.t("end.replay_hint"), 12, UIStyle.MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var restart := UIStyle.button(I18n.t("ui.restart"), true, 18)
	restart.pressed.connect(_on_restart)
	btn_row.add_child(restart)
	var menu := UIStyle.button(I18n.t("ui.main_menu"), false, 15)
	menu.pressed.connect(func() -> void: Game.goto("start"))
	btn_row.add_child(menu)
	v.add_child(btn_row)

func _on_restart() -> void:
	Game.new_game()
	Game.goto("office")
