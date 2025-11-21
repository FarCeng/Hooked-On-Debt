# global_data.gd
extends Node

# ----- GAME PROGRESSION -----
var turn: int = 1
var max_turns: int = 6

var attempts: int = 5       # attempts per turn
var attempts_per_turn: int = 5

var coins: int = 0
var target_coins: int = 1000

# ----- DATA STORAGE -----
var fish_data: Array = []      # loaded from fish_data.json
var quiz_data: Array = []      # loaded from quiz_data.json

# For quiz — ensures no repeating
var unused_questions: Array = []


var current_fish: Dictionary = {}
# ----- SIMPLE HELPERS -----

func load_json(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_warning("JSON NOT FOUND: " + path)
		return []

	var f := FileAccess.open(path, FileAccess.READ)
	var text := f.get_as_text()
	f.close()

	var parsed = JSON.parse_string(text)

	# Jika gagal → parsed == null
	if parsed == null:
		push_error("JSON PARSE ERROR in " + path)
		return []

	# Jika berhasil → parsed adalah data (Array / Dictionary)
	if typeof(parsed) == TYPE_ARRAY:
		return parsed
	elif typeof(parsed) == TYPE_DICTIONARY:
		return [parsed]   # opsional, tergantung format
	else:
		push_error("Unsupported JSON type in " + path)
		return []

func get_random_fish() -> Dictionary:
	var pool = fish_data
	var weights = {
		"common": 60,
		"uncommon": 25,
		"rare": 10,
		"legend": 5
	}

	var roll = randi() % 100
	print("[DEBUG] RNG roll =", roll)

	var selected_rarity = ""
	if roll < 60:
		selected_rarity = "common"
	elif roll < 85:
		selected_rarity = "uncommon"
	elif roll < 95:
		selected_rarity = "rare"
	else:
		selected_rarity = "legend"

	print("[DEBUG] Rarity chosen:", selected_rarity)

	var selected_list = []
	for f in pool:
		if f["rarity"] == selected_rarity:
			selected_list.append(f)

	print("[DEBUG] Candidate fish list:", selected_list)

	return selected_list[randi() % selected_list.size()]



func load_all_data():
	fish_data = load_json("res://data/fish_data.json")
	quiz_data = load_json("res://data/quiz_data.json")
	unused_questions = quiz_data.duplicate(true)
	unused_questions.shuffle()

func get_random_question() -> Dictionary:
	if unused_questions.size() == 0:
		return {}
	return unused_questions.pop_at(randi() % unused_questions.size())

func next_attempt():
	attempts -= 1
	if attempts <= 0:
		attempts = attempts_per_turn
		turn += 1

func add_coins(amount: int):
	coins += amount

func reset_all():
	turn = 1
	attempts = attempts_per_turn
	coins = 0
	load_all_data()
