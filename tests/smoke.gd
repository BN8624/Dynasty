# 씬 흐름 스모크 테스트 — 실제 화면과 버튼으로 전체 경로를 EN/KO로 구동한다.
# 실행: godot --headless --path . res://tests/smoke.tscn
# 씬 전환이 current_scene(이 씬)을 해제하므로, 구동 로직은 루트에 상주하는 드라이버 노드가 맡는다.
extends Node

func _ready() -> void:
	var driver := Driver.new()
	get_tree().root.add_child.call_deferred(driver)


class Driver:
	extends Node

	var failures: Array = []
	var saw_council := false
	var saw_succession := false

	func _ready() -> void:
		_run()

	func _run() -> void:
		get_tree().root.size = Vector2i(1280, 720)
		await _settle()
		await _pass_one_locale("en")
		await _pass_one_locale("ko")
		print("")
		print("=== SMOKE SUMMARY ===")
		for f in failures:
			print("FAIL: " + str(f))
		var exit_code := 0 if failures.is_empty() else 1
		if exit_code == 0:
			print("SMOKE PASSED")
		var current := get_tree().current_scene
		if current != null:
			current.queue_free()
		await _settle()
		get_tree().quit(exit_code)

	func fail(msg: String) -> void:
		failures.append(msg)

	func _settle() -> void:
		await get_tree().process_frame
		await get_tree().process_frame

	func scene_name() -> String:
		var cs := get_tree().current_scene
		return cs.name if cs != null else "<none>"

	# 트리에서 표시 텍스트가 일치하는 버튼 탐색.
	func find_button(text: String) -> Button:
		return _find_button_rec(get_tree().current_scene, text)

	func _find_button_rec(node: Node, text: String) -> Button:
		if node is Button and (node as Button).text == text:
			return node
		for child in node.get_children():
			var r := _find_button_rec(child, text)
			if r != null:
				return r
		return null

	# 활성화된 버튼 중 첫 번째(가족 회의 선택지용).
	func first_enabled_choice_button() -> Button:
		var all: Array = []
		_collect_buttons(get_tree().current_scene, all)
		for b in all:
			if not b.disabled:
				return b
		return null

	func _collect_buttons(node: Node, into: Array) -> void:
		if node is Button:
			into.append(node)
		for child in node.get_children():
			_collect_buttons(child, into)

	func press(btn: Button, ctx: String) -> void:
		if btn == null:
			fail(ctx + ": button not found on " + scene_name())
			return
		if btn.disabled:
			fail(ctx + ": button disabled on " + scene_name())
			return
		btn.pressed.emit()

	func check_control_on_screen(control: Control, ctx: String) -> void:
		if control == null:
			fail(ctx + ": control not found on " + scene_name())
			return
		var rect := control.get_global_rect()
		var viewport_rect := get_tree().root.get_visible_rect()
		if not control.is_visible_in_tree():
			fail(ctx + ": control is not visible")
		elif rect.size.x < 2.0 or rect.size.y < 2.0:
			fail(ctx + ": control has no usable size: " + str(rect))
		elif not viewport_rect.encloses(rect):
			fail(ctx + ": control is outside the viewport: %s vs %s" % [rect, viewport_rect])

	func check_office_layout(loc: String) -> void:
		var office := get_tree().current_scene
		var main := office.find_child("OfficeMain", true, false) as Control
		check_control_on_screen(main, loc + ": office main area")
		if main != null and main.size.y < 350.0:
			fail(loc + ": office main area is vertically collapsed: " + str(main.get_global_rect()))
		check_control_on_screen(find_button(I18n.t("ui.genealogy")), loc + ": genealogy button")
		check_control_on_screen(find_button(I18n.t("ui.end_turn")), loc + ": end-turn button")

	func check_genealogy_layout(loc: String) -> void:
		var genealogy := get_tree().current_scene
		for label_name in ["CoupleLabel", "BrotherLabel"]:
			var relation_label := genealogy.find_child(label_name, true, false) as Control
			check_control_on_screen(relation_label, loc + ": genealogy " + label_name)
			if relation_label == null:
				continue
			for id in ["edric_arven", "myra_arven", "aldren_arven", "rowen_arven", "beric_arven"]:
				var card := genealogy.find_child("GenealogyCard_" + id, true, false) as Control
				if card != null and relation_label.get_global_rect().intersects(card.get_global_rect()):
					fail("%s: genealogy %s overlaps %s" % [loc, label_name, id])

	func _pass_one_locale(loc: String) -> void:
		saw_council = false
		saw_succession = false
		I18n.set_locale(loc)
		Game.goto("start")
		await _settle()
		if scene_name() != "StartScreen":
			fail(loc + ": expected StartScreen, got " + scene_name())
			return
		press(find_button(I18n.t("ui.new_game")), loc + ": new game")
		await _settle()
		if scene_name() != "HouseOffice":
			fail(loc + ": expected HouseOffice after new game, got " + scene_name())
			return
		check_office_layout(loc)
		# 계보 왕복
		var genealogy_button := find_button(I18n.t("ui.genealogy"))
		press(genealogy_button, loc + ": open genealogy")
		await _settle()
		if scene_name() != "GenealogyView":
			fail(loc + ": expected GenealogyView, got " + scene_name())
		check_genealogy_layout(loc)
		var back_button := find_button(I18n.t("ui.back_office"))
		check_control_on_screen(back_button, loc + ": genealogy back button")
		press(back_button, loc + ": back to office")
		await _settle()
		if scene_name() != "HouseOffice":
			fail(loc + ": expected HouseOffice after genealogy, got " + scene_name())
			return
		# 본편 진행
		var guard := 0
		while guard < 80:
			guard += 1
			match scene_name():
				"HouseOffice":
					press(find_button(I18n.t("ui.end_turn")), loc + ": end turn")
				"FamilyCouncil":
					saw_council = true
					var choice_button := first_enabled_choice_button()
					check_control_on_screen(choice_button, loc + ": council choice")
					press(choice_button, loc + ": council choice")
				"SuccessionScreen":
					saw_succession = true
					if Game.state.succession_evidence.is_empty():
						fail(loc + ": succession screen without evidence")
					var continue_button := find_button(I18n.t("ui.continue"))
					check_control_on_screen(continue_button, loc + ": succession continue")
					press(continue_button, loc + ": succession continue")
				"EndScreen":
					break
				_:
					fail(loc + ": unexpected scene " + scene_name())
					return
			await _settle()
		if scene_name() != "EndScreen":
			fail(loc + ": never reached EndScreen (stuck on %s, turn %d)" % [scene_name(), Game.state.turn])
			return
		var terminal := Game.state.terminal_result_id
		if terminal == "":
			fail(loc + ": end screen without terminal result")
		if not saw_council:
			fail(loc + ": family council never appeared")
		if not saw_succession:
			fail(loc + ": succession screen never appeared")
		# 재시작 → 정본 초기 픽스처 복원 확인
		var restart_button := find_button(I18n.t("ui.restart"))
		check_control_on_screen(restart_button, loc + ": restart button")
		press(restart_button, loc + ": restart")
		await _settle()
		if scene_name() != "HouseOffice":
			fail(loc + ": expected HouseOffice after restart, got " + scene_name())
			return
		var fresh := Rules.new_game(Game.state.seed_value)
		if Game.state.snapshot_string() != fresh.snapshot_string():
			fail(loc + ": restart did not restore the canonical initial fixture")
		print("smoke pass [%s]: terminal=%s, council=%s, succession=%s, restart ok" % [
			loc, terminal, saw_council, saw_succession])
