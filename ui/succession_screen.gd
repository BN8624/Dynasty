# 승계 결산 화면 — 죽음, 후보 점수와 수정치, 베릭 변수, 결과와 즉각 변화를 설명한다.
extends Control

func _ready() -> void:
	UIStyle.build_background(self)
	_build()

func _build() -> void:
	var s: SimState = Game.state
	var ev: Dictionary = s.succession_evidence
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UIStyle.make_panel()
	panel.custom_minimum_size = Vector2(900, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	v.add_child(UIStyle.label(I18n.t("succ.title"), 26, UIStyle.WAX, true))
	v.add_child(UIStyle.label(I18n.t("succ.death_line"), 14, UIStyle.INK))
	v.add_child(UIStyle.hline())

	# 후보 점수 패널 두 개
	var cand_row := HBoxContainer.new()
	cand_row.add_theme_constant_override("separation", 10)
	for cid in ["aldren_arven", "rowen_arven"]:
		cand_row.add_child(_candidate_panel(cid, ev))
	v.add_child(cand_row)

	# 베릭 수정치
	var beric_line := "%s — %s" % [I18n.t("succ.beric_title"), I18n.t("succ.beric." + str(ev["beric"]["branch"]))]
	v.add_child(UIStyle.label(beric_line, 13, UIStyle.INK_SOFT))

	# 동점 처리
	if ev["tiebreaker_used"]:
		var rule_key := "succ.tiebreaker.formal_heir" if str(ev["inputs"]["formal_heir_id"]) != "" else "succ.tiebreaker.primogeniture"
		v.add_child(UIStyle.label(I18n.t("succ.tiebreaker", {"rule": I18n.t(rule_key)}), 13, UIStyle.WAX))
	v.add_child(UIStyle.hline())

	# 결과
	v.add_child(UIStyle.label("%s: %s" % [I18n.t("succ.outcome_title"), I18n.t("outcome." + s.succession_outcome_id)], 20, UIStyle.WAX, true))
	var head_key := "succ.provisional_head" if s.succession_outcome_id == "succession_civil_war" else "succ.new_head"
	v.add_child(UIStyle.label(I18n.t(head_key, {"name": I18n.name_of(str(ev["winner"]))}), 15, UIStyle.INK, true))
	v.add_child(UIStyle.label(I18n.t("succ.losing", {"name": I18n.name_of(str(ev["loser"]))}), 14, UIStyle.INK_SOFT))

	# 즉각적인 상태 변화
	if not (ev["changes"] as Array).is_empty():
		v.add_child(UIStyle.vspace(2))
		v.add_child(UIStyle.label(I18n.t("succ.changes_title"), 14, UIStyle.INK, true))
		for ch in ev["changes"]:
			var val: int = int(ch["value"])
			var vtext := ("+%d" % val) if val > 0 else str(val)
			v.add_child(UIStyle.label("· " + I18n.t(ch["key"], {"value": vtext}), 13, UIStyle.INK_SOFT))

	v.add_child(UIStyle.vspace(6))
	var btn := UIStyle.button(I18n.t("ui.continue"), true, 18)
	btn.pressed.connect(_on_continue)
	v.add_child(btn)

func _candidate_panel(cid: String, ev: Dictionary) -> Control:
	var panel := UIStyle.make_panel(UIStyle.PARCHMENT_DARK, UIStyle.GOLD_SOFT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	panel.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(UIStyle.portrait(cid, I18n.name_of(cid), 44))
	var name_col := VBoxContainer.new()
	name_col.add_child(UIStyle.label(I18n.name_of(cid), 16, UIStyle.INK, true))
	name_col.add_child(UIStyle.label(I18n.t("succ.total", {"score": ev["candidates"][cid]["total"]}), 14, UIStyle.WAX, true))
	head.add_child(name_col)
	v.add_child(head)
	v.add_child(UIStyle.hline())
	for p in ev["candidates"][cid]["parts"]:
		var val: int = int(p["value"])
		var vtext := ("+%d" % val) if val >= 0 else str(val)
		v.add_child(UIStyle.stat_row(I18n.t(p["key"]), vtext, 13))
	return panel

func _on_continue() -> void:
	Game.confirm_succession()
