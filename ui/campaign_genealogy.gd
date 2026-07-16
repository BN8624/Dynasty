# 캠페인 계보 화면 — 세대별 혈통/혼인/생사/분가/권리를 지원 도구로 보여준다.
extends Control

func _ready() -> void:
	UIStyle.build_background(self)
	_build()

func _build() -> void:
	var s: CampaignState = Game.camp
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(m, 14)
	add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)

	v.add_child(UIStyle.label(I18n.t("gen.camp_title"), 24, UIStyle.WAX, true))
	v.add_child(UIStyle.label(I18n.t("gen.camp_sub", {"generation": s.generation}), 13, UIStyle.INK_SOFT))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 10)
	scroll.add_child(rows)

	# 세대별 행: 본가 구성원(배우자 포함), 이어서 분가.
	for g in range(1, s.generation + 1):
		var members: Array = []
		for cid in s.sorted_char_ids():
			var c: Dictionary = s.chr(cid)
			if int(c["generation_born"]) == g and c["role"] != "spouse" \
					and not str(c["role"]).begins_with("deceased_spouse"):
				members.append(cid)
		if members.is_empty():
			continue
		rows.add_child(UIStyle.label(I18n.t("gen.generation_row", {"generation": g}), 15, UIStyle.GOLD, true))
		rows.add_child(UIStyle.hline())
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		rows.add_child(row)
		for cid in members.slice(0, 6):
			row.add_child(_char_card(cid))

	# 분가 목록.
	var branches := s.living_branches()
	if not branches.is_empty():
		rows.add_child(UIStyle.label(I18n.t("gen.branches_row"), 15, UIStyle.GOLD, true))
		rows.add_child(UIStyle.hline())
		var brow := HBoxContainer.new()
		brow.add_theme_constant_override("separation", 8)
		rows.add_child(brow)
		for b in branches:
			brow.add_child(_branch_card(b))

	var back := UIStyle.button(I18n.t("ui.back_office"), true, 16)
	back.name = "CampGenealogyBack"
	back.pressed.connect(func() -> void: Game.goto("camp_office"))
	var back_row := HBoxContainer.new()
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_row.add_child(spacer)
	back_row.add_child(back)
	v.add_child(back_row)

func _char_card(id: String) -> Control:
	var s: CampaignState = Game.camp
	var c: Dictionary = s.chr(id)
	var faded: bool = (not c["alive"]) or c["exiled"]
	var card := UIStyle.make_panel(UIStyle.PARCHMENT if not faded else Color("cfc4ad"))
	card.name = "CampGenealogyCard_" + id
	card.custom_minimum_size = Vector2(190, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	card.add_child(v)
	var top := CenterContainer.new()
	top.add_child(CampText.portrait(s, id, 44, faded))
	v.add_child(top)
	var name := UIStyle.label(CampText.name_of(s, id), 14, UIStyle.INK, true)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name)
	# 혈통/혼인 정보.
	if c["father_id"] != "" or c["mother_id"] != "":
		var parent: String = c["father_id"] if c["father_id"] != "" else c["mother_id"]
		var pl := UIStyle.label(I18n.t("gen.child_of", {"name": CampText.name_of(s, parent)}), 11, UIStyle.MUTED)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(pl)
	if c["spouse_id"] != "":
		var ml := UIStyle.label(I18n.t("gen.married_to", {"name": CampText.name_of(s, c["spouse_id"])}), 11, UIStyle.MUTED)
		ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(ml)
	var badges := HBoxContainer.new()
	badges.add_theme_constant_override("separation", 3)
	badges.alignment = BoxContainer.ALIGNMENT_CENTER
	if not c["alive"]:
		badges.add_child(UIStyle.badge(I18n.t("gen.badge.deceased"), UIStyle.INK_SOFT))
	if id == s.current_head_id and c["alive"]:
		badges.add_child(UIStyle.badge(I18n.t("gen.badge.head"), UIStyle.WAX))
	if id == s.next_successor_id:
		badges.add_child(UIStyle.badge(I18n.t("badge.next_successor"), UIStyle.GOLD))
	if id == s.formal_heir_id:
		badges.add_child(UIStyle.badge(I18n.t("gen.badge.heir"), UIStyle.GOLD))
	if not s.claim_of(id, "succession").is_empty():
		badges.add_child(UIStyle.badge(I18n.t("gen.badge.claimant"), UIStyle.INK_SOFT))
	if c["branch_id"] != "":
		badges.add_child(UIStyle.badge(I18n.t("badge.branch"), UIStyle.INK_SOFT))
	if c["exiled"]:
		badges.add_child(UIStyle.badge(I18n.t("badge.exiled"), UIStyle.INK_SOFT))
	if c["disinherited"]:
		badges.add_child(UIStyle.badge(I18n.t("badge.disinherited"), UIStyle.INK_SOFT))
	if badges.get_child_count() > 0:
		var wrap := CenterContainer.new()
		wrap.add_child(badges)
		v.add_child(wrap)
	return card

func _branch_card(b: Dictionary) -> Control:
	var s: CampaignState = Game.camp
	var card := UIStyle.make_panel(UIStyle.PARCHMENT_DARK, UIStyle.GOLD_SOFT)
	card.custom_minimum_size = Vector2(220, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	card.add_child(v)
	v.add_child(UIStyle.label(I18n.t("gen.branch_name", {"name": CampText.name_of(s, b["founder_id"])}), 13, UIStyle.INK, true))
	v.add_child(UIStyle.label(I18n.t("gen.branch_line", {
		"generation": b["generation"],
		"estate": CampText.name_of(s, b["estate_id"]),
	}), 11, UIStyle.MUTED))
	return card
