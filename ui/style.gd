# UI 공용 스타일 — 양피지/잉크/밀랍 인장 방향의 절차 생성 비주얼 헬퍼 모음.
class_name UIStyle

const BG_DARK := Color("241c14")
const BG_WOOD := Color("2f251a")
const PARCHMENT := Color("e9dcc3")
const PARCHMENT_DARK := Color("d9c9a8")
const INK := Color("2e2418")
const INK_SOFT := Color("4a3c2a")
const MUTED := Color("6b5b44")
const DISABLED := Color("93826a")
const WAX := Color("7e2a22")
const WAX_DARK := Color("5e1f19")
const GOLD := Color("a8842f")
const GOLD_SOFT := Color("bfa15c")
const GOOD := Color("3f5d33")

const PORTRAIT_COLORS := {
	"edric_arven": Color("54626e"),
	"myra_arven": Color("4e6248"),
	"aldren_arven": Color("3f5470"),
	"rowen_arven": Color("7e3b2c"),
	"beric_arven": Color("6d5230"),
}

static func panel_box(bg: Color = PARCHMENT, border: Color = GOLD, radius: int = 6, border_w: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(12)
	return sb

static func make_panel(bg: Color = PARCHMENT, border: Color = GOLD) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_box(bg, border))
	return p

static func label(text: String, size: int = 15, color: Color = INK, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Georgia", "Times New Roman", "Malgun Gothic", "sans-serif"])
		f.font_weight = 700
		l.add_theme_font_override("font", f)
	else:
		l.add_theme_font_override("font", serif_font())
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

static var _serif: SystemFont = null

static func serif_font() -> SystemFont:
	if _serif == null:
		_serif = SystemFont.new()
		_serif.font_names = PackedStringArray(["Georgia", "Times New Roman", "Malgun Gothic", "sans-serif"])
	return _serif

# 밀랍 인장풍 주요 버튼 / 양피지풍 보조 버튼.
static func button(text: String, primary: bool = false, size: int = 16) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_font_override("font", serif_font())
	var bg := WAX if primary else PARCHMENT_DARK
	var fg := Color("f4e9d2") if primary else INK
	var normal := panel_box(bg, WAX_DARK if primary else GOLD, 5, 2)
	normal.set_content_margin_all(8)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	var hover := normal.duplicate()
	hover.bg_color = bg.lightened(0.08)
	var pressed := normal.duplicate()
	pressed.bg_color = bg.darkened(0.12)
	var disabled := normal.duplicate()
	disabled.bg_color = Color("cec1a6")
	disabled.border_color = Color("a2937a")
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", hover.duplicate())
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_focus_color", fg)
	b.add_theme_color_override("font_disabled_color", Color("8a7a5f"))
	return b

# 원형 초상 — 인물 고유색 원판 + 이름 첫 글자. 사망/이탈 시 탈색.
static func portrait(char_id: String, display_name: String, diameter: int = 56, faded: bool = false) -> Control:
	var wrap := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	var base: Color = PORTRAIT_COLORS.get(char_id, MUTED)
	if faded:
		base = base.lerp(Color("777066"), 0.7)
	sb.bg_color = base
	sb.border_color = GOLD if not faded else Color("847a68")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(diameter / 2)
	wrap.add_theme_stylebox_override("panel", sb)
	wrap.custom_minimum_size = Vector2(diameter, diameter)
	var l := Label.new()
	l.text = display_name.substr(0, 1)
	l.add_theme_font_size_override("font_size", int(diameter * 0.45))
	l.add_theme_color_override("font_color", Color("f4e9d2") if not faded else Color("c9c2b4"))
	l.add_theme_font_override("font", serif_font())
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wrap.add_child(l)
	return wrap

# 작은 신분 배지 (가주/후계자/계승권자/사망 등).
static func badge(text: String, color: Color = WAX) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	p.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color("f4e9d2"))
	p.add_child(l)
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return p

static func hline(color: Color = GOLD_SOFT) -> Control:
	var r := ColorRect.new()
	r.color = color
	r.custom_minimum_size = Vector2(0, 1)
	return r

static func vspace(h: int = 8) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

# 전체 화면 배경(짙은 목재) + 중앙 콘텐츠 마진.
static func build_background(root: Control) -> void:
	var bg := ColorRect.new()
	bg.color = BG_DARK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

# 헤더 문장(방패) — 절차 생성 아르벤 문장.
static func heraldry(size: int = 40) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(size, size)
	var poly := Polygon2D.new()
	var w := float(size)
	poly.polygon = PackedVector2Array([
		Vector2(w * 0.1, w * 0.05), Vector2(w * 0.9, w * 0.05),
		Vector2(w * 0.9, w * 0.55), Vector2(w * 0.5, w * 0.95),
		Vector2(w * 0.1, w * 0.55),
	])
	poly.color = WAX
	c.add_child(poly)
	var band := Polygon2D.new()
	band.polygon = PackedVector2Array([
		Vector2(w * 0.1, w * 0.3), Vector2(w * 0.9, w * 0.3),
		Vector2(w * 0.9, w * 0.45), Vector2(w * 0.1, w * 0.45),
	])
	band.color = GOLD
	c.add_child(band)
	return c

# 스탯 한 줄: 이름 + 값 (+괄호 안 부가정보).
static func stat_row(name_text: String, value_text: String, size: int = 14) -> Control:
	var h := HBoxContainer.new()
	var n := label(name_text, size, INK_SOFT)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := label(value_text, size, INK, true)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(n)
	h.add_child(v)
	return h
