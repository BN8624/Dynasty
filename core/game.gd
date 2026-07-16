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
	"camp_office": "res://ui/campaign_office.tscn",
	"camp_council": "res://ui/campaign_council.tscn",
	"camp_succession": "res://ui/campaign_succession.tscn",
	"camp_genealogy": "res://ui/campaign_genealogy.tscn",
	"camp_legacy": "res://ui/campaign_legacy.tscn",
}

# 내보낸 빌드 검증용: `--verify-office` 사용자 인자로 실행하면 새 게임이
# 집무실에 도달하는지 확인하고 결과를 출력한 뒤 종료한다. 일반 플레이에는 관여하지 않는다.
func _ready() -> void:
	if "--verify-office" in OS.get_cmdline_user_args():
		_verify_office()

func _verify_office() -> void:
	await get_tree().process_frame
	new_game()
	goto("office")
	for i in range(5):
		await get_tree().process_frame
	var cs := get_tree().current_scene
	var ok: bool = cs != null and cs.name == "HouseOffice" and state.turn == 1 and state.action_points == 2
	print("VERIFY_OFFICE_RESULT: %s (scene=%s)" % ["PASS" if ok else "FAIL", cs.name if cs != null else "<none>"])
	get_tree().quit(0 if ok else 1)

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

# ---------------------------------------------------------------- 3세대 캠페인 모드

var camp: CampaignState = null
var next_camp_seed: int = 1

func new_campaign() -> void:
	camp = CampaignRules.new_campaign(next_camp_seed)
	next_camp_seed += 1
	state_changed.emit()

func camp_screen_for_phase() -> String:
	match camp.phase:
		CampaignState.PHASE_ACTIONS:
			return "camp_office"
		CampaignState.PHASE_DILEMMA:
			return "camp_council"
		CampaignState.PHASE_SUCCESSION:
			return "camp_succession"
		CampaignState.PHASE_LEGACY:
			return "camp_legacy"
	return "camp_office"

func camp_do_action(id: String, option: String = "") -> void:
	CampaignRules.apply_action(camp, id, option)
	state_changed.emit()
	if camp.phase != CampaignState.PHASE_ACTIONS:
		goto(camp_screen_for_phase())

func camp_end_turn() -> void:
	CampaignRules.end_action_phase(camp)
	state_changed.emit()
	goto(camp_screen_for_phase())

func camp_choose(choice_id: String) -> void:
	CampaignRules.apply_dilemma_choice(camp, choice_id)
	state_changed.emit()
	goto(camp_screen_for_phase())

func camp_confirm_succession() -> void:
	CampaignRules.confirm_succession(camp)
	state_changed.emit()
	goto(camp_screen_for_phase())
