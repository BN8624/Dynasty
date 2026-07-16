# 캠페인 선택 화면 — 고정 시나리오와 3세대 캠페인의 진입점을 분리해 제시한다.
extends Control

func _ready() -> void:
	UIStyle.build_background(self)
	_build()

func _build() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UIStyle.make_panel()
	panel.custom_minimum_size = Vector2(720, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	var crest := CenterContainer.new()
	crest.add_child(UIStyle.heraldry(48))
	v.add_child(crest)
	var title := UIStyle.label(I18n.t("ui.campaign_selection"), 30, UIStyle.WAX, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var desc := UIStyle.label(I18n.t("ui.campaign_selection_hint"), 13, UIStyle.MUTED)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(desc)
	v.add_child(UIStyle.vspace(4))
	v.add_child(UIStyle.hline())
	v.add_child(_mode_panel("ui.last_winter_mode", "ui.last_winter_mode_hint", _start_last_winter))
	v.add_child(_mode_panel("ui.new_campaign", "ui.new_campaign_hint", _start_campaign))

	var back := UIStyle.button(I18n.t("ui.main_menu"), false, 14)
	back.pressed.connect(func() -> void: Game.goto("start"))
	v.add_child(back)

func _mode_panel(title_key: String, hint_key: String, start: Callable) -> Control:
	var panel := UIStyle.make_panel(UIStyle.PARCHMENT_DARK, UIStyle.GOLD_SOFT)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	panel.add_child(h)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 3)
	text.add_child(UIStyle.label(I18n.t(title_key), 18, UIStyle.INK, true))
	text.add_child(UIStyle.label(I18n.t(hint_key), 12, UIStyle.INK_SOFT))
	h.add_child(text)
	var choose := UIStyle.button(I18n.t("ui.choose_campaign"), true, 15)
	choose.custom_minimum_size = Vector2(130, 0)
	choose.pressed.connect(start)
	h.add_child(choose)
	return panel

func _start_last_winter() -> void:
	Game.new_game()
	Game.goto("office")

func _start_campaign() -> void:
	Game.new_campaign()
	Game.goto("camp_office")
