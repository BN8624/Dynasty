# 로컬라이제이션 오토로드 — 영어/한국어 문자열 테이블을 로드하고 키 기반 조회를 제공한다.
extends Node

var locale: String = "en"
var _tables: Dictionary = {}  # locale -> {key -> text}

func _ready() -> void:
	load_tables()

func load_tables() -> void:
	_tables = {}
	for loc in ["en", "ko"]:
		var path := "res://i18n/%s.json" % loc
		var f := FileAccess.open(path, FileAccess.READ)
		assert(f != null, "missing translation file: " + path)
		var data: Variant = JSON.parse_string(f.get_as_text())
		assert(data is Dictionary, "invalid translation file: " + path)
		_tables[loc] = data

func set_locale(loc: String) -> void:
	assert(_tables.has(loc))
	locale = loc

func has_key(loc: String, key: String) -> bool:
	return _tables.has(loc) and _tables[loc].has(key)

func keys_for(loc: String) -> Array:
	return _tables[loc].keys() if _tables.has(loc) else []

# 키 조회 + {placeholder} 치환. 누락 키는 assert로 즉시 드러낸다.
func t(key: String, params: Dictionary = {}) -> String:
	var table: Dictionary = _tables.get(locale, {})
	assert(table.has(key), "missing i18n key [%s] %s" % [locale, key])
	var text: String = table.get(key, key)
	for p in params:
		text = text.replace("{%s}" % p, str(params[p]))
	return text

# 인물/가문 ID의 표시 이름.
func name_of(id: String) -> String:
	return t("name." + id)

# 연대기 항목을 현재 로케일 문장으로 렌더링.
func chronicle_line(entry: Dictionary) -> String:
	var when := t("chron.when", {
		"year": entry["year"],
		"season": t("season." + entry["season"]),
	})
	var params: Dictionary = (entry["params"] as Dictionary).duplicate()
	params["actor"] = name_of(entry["actor"]) if has_key(locale, "name." + entry["actor"]) else entry["actor"]
	return when + " — " + t(entry["key"], params)
