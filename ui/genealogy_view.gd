# 계보 화면 — 혈통/혼인/생사/가주/후계/계승권자를 지원 도구로 보여준다.
extends Control

# 선 그리기 레이어.
class LineLayer:
	extends Control
	var lines: Array = []  # [[from, to, color, width], ...]
	func _draw() -> void:
		for l in lines:
			draw_line(l[0], l[1], l[2], l[3])

const CARD_W := 190.0
const CARD_H := 150.0

func _ready() -> void:
	UIStyle.build_background(self)
	_build()

func _build() -> void:
	var s: SimState = Game.state
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 8)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(m, 14)
	margin.add_child(v)
	add_child(margin)

	v.add_child(UIStyle.label(I18n.t("gen.title"), 24, UIStyle.WAX, true))
	var marriage_text: String = I18n.t("gen.marriage_line", {"name": I18n.name_of(s.flags["marriage_partner_house_id"])}) \
		if s.flags["marriage_completed"] else I18n.t("gen.marriage_none")
	v.add_child(UIStyle.label(marriage_text, 13, UIStyle.INK_SOFT))

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(center)
	var canvas := Control.new()
	canvas.custom_minimum_size = Vector2(880, 420)
	center.add_child(canvas)

	var pos := {
		"beric_arven": Vector2(10, 10),
		"edric_arven": Vector2(290, 10),
		"myra_arven": Vector2(570, 10),
		"aldren_arven": Vector2(280, 260),
		"rowen_arven": Vector2(560, 260),
	}
	var lines := LineLayer.new()
	lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ink := UIStyle.GOLD_SOFT
	var e_c: Vector2 = pos["edric_arven"] + Vector2(CARD_W / 2, 0)
	var m_c: Vector2 = pos["myra_arven"] + Vector2(CARD_W / 2, 0)
	var couple_y := 80.0
	# 부부 연결선
	lines.lines.append([Vector2(pos["edric_arven"].x + CARD_W, couple_y), Vector2(pos["myra_arven"].x, couple_y), ink, 2.0])
	# 부부 중점 → 자녀 연결선
	var mid := Vector2((pos["edric_arven"].x + CARD_W + pos["myra_arven"].x) / 2.0, couple_y)
	var drop_y := 240.0
	lines.lines.append([mid, Vector2(mid.x, drop_y - 20), ink, 2.0])
	for kid in ["aldren_arven", "rowen_arven"]:
		var kx: float = pos[kid].x + CARD_W / 2
		lines.lines.append([Vector2(mid.x, drop_y - 20), Vector2(kx, drop_y - 20), ink, 2.0])
		lines.lines.append([Vector2(kx, drop_y - 20), Vector2(kx, pos[kid].y), ink, 2.0])
	# 에드릭–베릭 형제선
	lines.lines.append([Vector2(pos["edric_arven"].x + CARD_W, 40), Vector2(pos["beric_arven"].x, 40), Color(ink, 0.6), 1.0])
	canvas.add_child(lines)

	for id in pos:
		var card := _char_card(id)
		card.name = "GenealogyCard_" + id
		card.position = pos[id]
		card.custom_minimum_size = Vector2(CARD_W, CARD_H)
		canvas.add_child(card)

	# 관계 라벨
	var couple_label := UIStyle.label(I18n.t("gen.couple_label"), 11, UIStyle.MUTED)
	couple_label.name = "CoupleLabel"
	couple_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	couple_label.position = mid + Vector2(-20, -22)
	canvas.add_child(couple_label)
	var brother_label := UIStyle.label(I18n.t("gen.brother_label"), 11, UIStyle.MUTED)
	brother_label.name = "BrotherLabel"
	brother_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	brother_label.position = Vector2((pos["edric_arven"].x + CARD_W + pos["beric_arven"].x) / 2.0 - 40, 18)
	canvas.add_child(brother_label)

	var back := UIStyle.button(I18n.t("ui.back_office"), true, 16)
	back.pressed.connect(func() -> void: Game.goto("office"))
	var back_row := HBoxContainer.new()
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_row.add_child(spacer)
	back_row.add_child(back)
	v.add_child(back_row)

func _char_card(id: String) -> Control:
	var s: SimState = Game.state
	var c: Dictionary = s.chr(id)
	var faded: bool = (not c["alive"]) or (not c["in_house"])
	var card := UIStyle.make_panel(UIStyle.PARCHMENT if not faded else Color("cfc4ad"))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	card.add_child(v)
	var top := CenterContainer.new()
	top.add_child(UIStyle.portrait(id, I18n.name_of(id), 48, faded))
	v.add_child(top)
	var name := UIStyle.label(I18n.name_of(id), 14, UIStyle.INK, true)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name)
	var badges := VBoxContainer.new()
	badges.add_theme_constant_override("separation", 2)
	badges.alignment = BoxContainer.ALIGNMENT_CENTER
	var wrap := CenterContainer.new()
	wrap.add_child(badges)
	v.add_child(wrap)
	if not c["alive"]:
		badges.add_child(UIStyle.badge(I18n.t("gen.badge.deceased"), UIStyle.INK_SOFT))
	elif not c["in_house"]:
		badges.add_child(UIStyle.badge(I18n.t("gen.badge.departed"), UIStyle.INK_SOFT))
	if id == s.current_head_id and c["alive"]:
		badges.add_child(UIStyle.badge(
			I18n.t("gen.badge.provisional" if s.flags["civil_war_active"] else "gen.badge.head"), UIStyle.WAX))
	if id == s.formal_heir_id:
		badges.add_child(UIStyle.badge(I18n.t("gen.badge.heir"), UIStyle.GOLD))
	if id == s.flags["losing_claimant_id"]:
		badges.add_child(UIStyle.badge(I18n.t("gen.badge.claimant"), UIStyle.INK_SOFT))
	return card
