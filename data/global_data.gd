extends Node

# ----- GAME PROGRESSION -----
var turn := 1
var max_turns := 6
var attempts := 5
var attempts_per_turn := 5
var coins := 0
var target_coins := 400
#signal game_over(is_good_ending: bool)

# ----- DATA STORAGE -----
var fish_data := []
var quiz_data := []
var unused_questions := []
var current_fish := {}

# ----- HELPERS -----
func _ready() -> void:
	# Autoload entry point: load JSON data on startup
	load_all_data()

func load_json(path: String) -> Array:
	# safe file check
	if not FileAccess.file_exists(path):
		push_warning("[GlobalData] JSON NOT FOUND: " + path)
		return []

	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("[GlobalData] Failed to open file: " + path)
		return []
	var text = f.get_as_text()
	f.close()

	# --- UNTUK GODOT 4 ---
	var json = JSON.new()
	var error = json.parse(text)
	
	# Cek jika ada error parsing
	if error != OK:
		push_error("[GlobalData] JSON PARSE ERROR in %s: %s (at line %d)" % [path, json.get_error_message(), json.get_error_line()])
		return []

	# Dapatkan datanya
	var result = json.get_data()
	# --- AKHIR PERBAIKAN ---

	# Cek tipe data hasil
	if typeof(result) == TYPE_ARRAY:
		return result
	elif typeof(result) == TYPE_DICTIONARY:
		# jika filenya berisi 1 objek, kita bungkus dalam array
		return [result]
	else:
		# tipe JSON top-level tidak didukung
		push_error("[GlobalData] Unsupported JSON type in " + path)
		return []


func get_random_fish() -> Dictionary:
	# defensive: if no fish data loaded return empty dict
	if fish_data.size() == 0:
		return {}

	# pick rarity by thresholds
	var roll = randi() % 100
	var selected_rarity := ""
	if roll < 60:
		selected_rarity = "common"
	elif roll < 85:
		selected_rarity = "uncommon"
	elif roll < 95:
		selected_rarity = "rare"
	else:
		selected_rarity = "legend"

	# collect candidates
	var selected_list := []
	for f in fish_data:
		if typeof(f) == TYPE_DICTIONARY and f.has("rarity") and str(f["rarity"]) == selected_rarity:
			selected_list.append(f)

	# fallback: take whole pool if none matched
	if selected_list.size() == 0:
		selected_list = fish_data.duplicate(true)

	if selected_list.size() == 0:
		return {}

	return selected_list[randi() % selected_list.size()]


func load_all_data() -> void:
	fish_data = load_json("res://data/fish_data.json")
	quiz_data = load_json("res://data/quiz_data.json")
	# prepare unused questions
	unused_questions = quiz_data.duplicate(true)
	unused_questions.shuffle()


func get_random_question() -> Dictionary:
	if unused_questions.size() == 0:
		return {}
	return unused_questions.pop_at(randi() % unused_questions.size())


func next_attempt_only():
	attempts -= 1
	if attempts < 0:
		attempts = 0

# Fungsi ini untuk memulai turn baru (dipanggil oleh game.gd)
func advance_to_next_turn():
	turn += 1
	if turn <= max_turns:
		# Reset attempts di sini
		attempts = attempts_per_turn

func add_coins(amount: int) -> void:
	coins += amount


func reset_all() -> void:
	turn = 1
	attempts = attempts_per_turn
	coins = 0
	load_all_data()
