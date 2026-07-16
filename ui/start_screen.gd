# 시작 화면 — 새 게임/종료/언어 전환.
extends Control

func _ready() -> void:
	UIStyle.build_background(self)
	_build()

func _build() -> void:
	for child in get_children():
		if child is CenterContainer:
			child.queue_free()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := UIStyle.make_panel()
	card.custom_minimum_size = Vector2(520, 0)
	center.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)

	var crest_row := CenterContainer.new()
	crest_row.add_child(UIStyle.heraldry(56))
	v.add_child(crest_row)

	var title := UIStyle.label(I18n.t("ui.title"), 44, UIStyle.WAX, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UIStyle.label(I18n.t("ui.subtitle"), 22, UIStyle.INK, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var tag := UIStyle.label(I18n.t("ui.tagline"), 14, UIStyle.MUTED)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tag)
	v.add_child(UIStyle.vspace(6))
	v.add_child(UIStyle.hline())
	v.add_child(UIStyle.vspace(6))

	var new_btn := UIStyle.button(I18n.t("ui.new_game"), true, 20)
	new_btn.pressed.connect(_on_new_game)
	v.add_child(new_btn)
	var camp_btn := UIStyle.button(I18n.t("ui.new_campaign"), true, 20)
	camp_btn.pressed.connect(_on_new_campaign)
	v.add_child(camp_btn)
	var camp_hint := UIStyle.label(I18n.t("ui.new_campaign_hint"), 12, UIStyle.MUTED)
	camp_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(camp_hint)
	var lang_btn := UIStyle.button(I18n.t("ui.language"), false, 14)
	lang_btn.pressed.connect(_on_language)
	v.add_child(lang_btn)
	var quit_btn := UIStyle.button(I18n.t("ui.quit"), false, 14)
	quit_btn.pressed.connect(_on_quit)
	v.add_child(quit_btn)

func _on_new_game() -> void:
	Game.new_game()
	Game.goto("office")

func _on_new_campaign() -> void:
	Game.new_campaign()
	Game.goto("camp_office")

func _on_language() -> void:
	I18n.set_locale("ko" if I18n.locale == "en" else "en")
	_build()

func _on_quit() -> void:
	get_tree().quit()
