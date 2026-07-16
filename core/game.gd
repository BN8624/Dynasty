# 게임 오토로드 — 단일 SimState를 보관하고 UI 화면 전환과 규칙 호출을 중개한다.
extends Node

signal state_changed

var state: SimState = null
var next_seed: int = 1
# 승계 화면에서 복귀할 때 집무실이 이어서 처리하도록 대기 상태를 기록.
var came_from_council_event: String = ""

const SCENES := {
	"start": "res://ui/start_screen.tscn",
	"office": "res://ui/house_office.tscn",
	"council": "res://ui/family_council.tscn",
	"succession": "res://ui/succession_screen.tscn",
	"genealogy": "res://ui/genealogy_view.tscn",
	"end": "res://ui/end_screen.tscn",
}

func new_game() -> void:
	state = Rules.new_game(next_seed)
	next_seed += 1
	came_from_council_event = ""
	state_changed.emit()

func goto(screen: String) -> void:
	get_tree().change_scene_to_file(SCENES[screen])

# 현재 페이즈에 맞는 화면 이름.
func screen_for_phase() -> String:
	match state.phase:
		SimState.PHASE_ACTIONS:
			return "office"
		SimState.PHASE_EVENT:
			return "council"
		SimState.PHASE_SUCCESSION:
			return "succession"
		SimState.PHASE_OVER:
			return "end"
	return "office"

func do_action(id: String, option: String = "") -> void:
	Rules.apply_action(state, id, option)
	state_changed.emit()
	if state.phase == SimState.PHASE_OVER:
		goto("end")

func end_turn() -> void:
	Rules.end_action_phase(state)
	state_changed.emit()
	goto(screen_for_phase())

func choose(choice_id: String) -> void:
	Rules.apply_event_choice(state, choice_id)
	state_changed.emit()
	goto(screen_for_phase())

func confirm_succession() -> void:
	Rules.continue_after_succession(state)
	state_changed.emit()
	goto(screen_for_phase())
