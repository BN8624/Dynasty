# 캠페인 승계 화면 — 승계 사유/후보 점수/결과/즉각 변화를 설명하고 다음 세대 또는 유산 평가로 잇는다.
extends Control

func _ready() -> void:
	UIStyle.build_background(self)
	_build()

func _build() -> void:
	var s: CampaignState = Game.camp
	var rec: Dictionary = s.succession_records[s.succession_records.size() - 1]
	var ev: Dictionary = rec["evidence"]

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UIStyle.make_panel()
	panel.custom_minimum_size = Vector2(920, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	panel.add_child(v)

	v.add_child(UIStyle.label(I18n.t("succ.camp_title", {"generation": rec["generation"]}), 26, UIStyle.WAX, true))
	# 왜 승계가 일어났는가.
	v.add_child(UIStyle.label(I18n.t("succ.camp_cause_line", {
		"head": CampText.name_of(s, rec["old_head"]),
		"cause": I18n.t("succcause." + str(rec["cause"])),
	}), 14, UIStyle.INK))
	v.add_child(UIStyle.hline())

	# 후보 점수 패널(상위 3인까지).
	var cand_ids: Array = (ev["candidates"] as Dictionary).keys()
	cand_ids.sort_custom(func(a, b):
		return int(ev["candidates"][a]["total"]) > int(ev["candidates"][b]["total"]))
	var cand_row := HBoxContainer.new()
	cand_row.add_theme_constant_override("separation", 10)
	for cid in cand_ids.slice(0, 3):
		cand_row.add_child(_candidate_panel(s, cid, ev))
	v.add_child(cand_row)
	if cand_ids.size() > 3:
		v.add_child(UIStyle.label(I18n.t("succ.more_candidates", {"count": cand_ids.size() - 3}), 12, UIStyle.MUTED))
	v.add_child(UIStyle.hline())

	# 결과.
	v.add_child(UIStyle.label("%s: %s" % [I18n.t("succ.outcome_title"),
		I18n.t("outcome." + str(rec["outcome"]))], 20, UIStyle.WAX, true))
	var head_key := "succ.camp_next_successor" if rec["generation"] >= 3 else "succ.new_head"
	v.add_child(UIStyle.label(I18n.t(head_key, {"name": CampText.name_of(s, str(ev["winner"]))}), 15, UIStyle.INK, true))
	if str(ev["runner"]) != "":
		v.add_child(UIStyle.label(I18n.t("succ.losing", {"name": CampText.name_of(s, str(ev["runner"]))}), 14, UIStyle.INK_SOFT))
	if s.regent_id != "" and rec["generation"] < 3:
		v.add_child(UIStyle.label(I18n.t("succ.regent_line", {"name": CampText.name_of(s, s.regent_id)}), 14, UIStyle.WAX))

	if not (ev["changes"] as Array).is_empty():
		v.add_child(UIStyle.vspace(2))
		v.add_child(UIStyle.label(I18n.t("succ.changes_title"), 14, UIStyle.INK, true))
		for ch in ev["changes"]:
			var val: int = int(ch["value"])
			var vtext := ("+%d" % val) if val > 0 else str(val)
			v.add_child(UIStyle.label("· " + I18n.t(ch["key"], {"value": vtext}), 13, UIStyle.INK_SOFT))

	v.add_child(UIStyle.vspace(6))
	var btn_text := I18n.t("ui.view_legacy") if rec["generation"] >= 3 else I18n.t("ui.next_generation")
	var btn := UIStyle.button(btn_text, true, 18)
	btn.pressed.connect(_on_continue)
	v.add_child(btn)

func _candidate_panel(s: CampaignState, cid: String, ev: Dictionary) -> Control:
	var panel := UIStyle.make_panel(UIStyle.PARCHMENT_DARK, UIStyle.GOLD_SOFT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	panel.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(CampText.portrait(s, cid, 42))
	var name_col := VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_col.add_child(UIStyle.label(CampText.name_of(s, cid), 15, UIStyle.INK, true))
	name_col.add_child(UIStyle.label(I18n.t("succ.total", {"score": ev["candidates"][cid]["total"]}), 13, UIStyle.WAX, true))
	head.add_child(name_col)
	v.add_child(head)
	v.add_child(UIStyle.hline())
	for p in ev["candidates"][cid]["parts"]:
		var val: int = int(p["value"])
		var vtext := ("+%d" % val) if val >= 0 else str(val)
		v.add_child(UIStyle.stat_row(I18n.t(p["key"]), vtext, 12))
	return panel

func _on_continue() -> void:
	Game.camp_confirm_succession()
