# 왕조 유산 화면 — 3세대 캠페인의 최종 평가. 기여 요인/승계 이력/차기 승계자/재시작을 제공한다.
extends Control

func _ready() -> void:
	UIStyle.build_background(self)
	_build()

func _build() -> void:
	var s: CampaignState = Game.camp
	var lr: Dictionary = s.legacy_result
	var rid: String = lr["result_id"]

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UIStyle.make_panel()
	panel.custom_minimum_size = Vector2(940, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	panel.add_child(v)

	# 고정 시나리오 종결과 구분되는 왕조 유산 결산 표기.
	var cls := UIStyle.label(I18n.t("legacy.class_line"), 16, UIStyle.GOLD, true)
	cls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cls)
	var title := UIStyle.label(I18n.t("legresult.%s.title" % rid), 30, UIStyle.WAX, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var desc := UIStyle.label(I18n.t("legresult.%s.desc" % rid), 14, UIStyle.INK)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(desc)
	var id_line := UIStyle.label("%s: %s (%d)   ·   %s" % [I18n.t("end.result_label"), rid,
		int(lr["score"]), I18n.t("ui.seed_line", {"seed": s.seed_value})], 12, UIStyle.MUTED)
	id_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(id_line)
	var succ_line := UIStyle.label(I18n.t("legacy.next_successor",
		{"name": CampText.name_of(s, s.next_successor_id)}), 15, UIStyle.INK, true)
	succ_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(succ_line)
	v.add_child(UIStyle.hline())

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 10)
	v.add_child(cols)

	# 기여 요인(+/-).
	var contrib_panel := UIStyle.make_panel(UIStyle.PARCHMENT_DARK, UIStyle.GOLD_SOFT)
	contrib_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 2)
	contrib_panel.add_child(cv)
	cv.add_child(UIStyle.label(I18n.t("legacy.contributors"), 15, UIStyle.INK, true))
	cv.add_child(UIStyle.hline())
	for c in lr["contributors"]:
		var val: int = int(c["value"])
		var vtext := ("+%d" % val) if val > 0 else str(val)
		var row := UIStyle.stat_row(I18n.t(c["key"]), vtext, 13)
		cv.add_child(row)
	cv.add_child(UIStyle.vspace(4))
	cv.add_child(UIStyle.label(I18n.t("legacy.successions_title"), 15, UIStyle.INK, true))
	cv.add_child(UIStyle.hline())
	for r in s.succession_records:
		cv.add_child(UIStyle.label(I18n.t("legacy.succession_line", {
			"generation": r["generation"],
			"cause": I18n.t("succcause." + str(r["cause"])),
			"outcome": I18n.t("outcome." + str(r["outcome"])),
		}), 12, UIStyle.INK_SOFT))
	cols.add_child(contrib_panel)

	# 왕조 인과 연대기(주요 사건).
	var chron_panel := UIStyle.make_panel(UIStyle.PARCHMENT_DARK, UIStyle.GOLD_SOFT)
	chron_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chron_panel.custom_minimum_size = Vector2(430, 320)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 2)
	chron_panel.add_child(hv)
	hv.add_child(UIStyle.label(I18n.t("legacy.history"), 15, UIStyle.INK, true))
	hv.add_child(UIStyle.hline())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hv.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)
	for e in s.major_entries():
		list.add_child(UIStyle.label(CampText.chronicle_line(s, e), 12, UIStyle.INK_SOFT))
	cols.add_child(chron_panel)

	v.add_child(UIStyle.vspace(2))
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var restart := UIStyle.button(I18n.t("ui.restart_campaign"), true, 18)
	restart.pressed.connect(_on_restart)
	btn_row.add_child(restart)
	var menu := UIStyle.button(I18n.t("ui.main_menu"), false, 15)
	menu.pressed.connect(func() -> void: Game.goto("start"))
	btn_row.add_child(menu)
	v.add_child(btn_row)

func _on_restart() -> void:
	Game.new_campaign()
	Game.goto("camp_office")
