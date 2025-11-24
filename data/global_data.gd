extends Node

# Variabel yang melacak progres game saat ini
var turn := 1
var max_turns := 6
var attempts := 5
var attempts_per_turn := 5
var coins := 0
var target_coins := 400


# Variabel untuk menyimpan data dari file JSON
var fish_data := []
var quiz_data := []
var unused_questions := []
var current_fish := {}

# Saat Autoload ini dimuat, langsung panggil fungsi untuk load data JSON.
func _ready() -> void:
	load_all_data()

# Helper internal: Membuka file JSON dari path, mem-parsingnya, dan mengembalikannya sebagai Array.
func load_json(path: String) -> Array:
	# Pengecekan keamanan file
	if not FileAccess.file_exists(path):
		push_warning("[GlobalData] JSON NOT FOUND: " + path)
		return []

	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("[GlobalData] Failed to open file: " + path)
		return []
	var text = f.get_as_text()
	f.close()

	var json = JSON.new()
	var error = json.parse(text)
	
	# Cek jika ada error parsing
	if error != OK:
		push_error("[GlobalData] JSON PARSE ERROR in %s: %s (at line %d)" % [path, json.get_error_message(), json.get_error_line()])
		return []

	# Dapatkan datanya
	var result = json.get_data()

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

# Dipanggil oleh game.gd. Mengambil 1 ikan acak dari 'fish_data' berdasarkan persentase rarity.
func get_random_fish() -> Dictionary:
	# Pengaman: jika data ikan gagal dimuat, kembalikan data kosong.
	if fish_data.size() == 0:
		return {}

	# Tentukan rarity berdasarkan persentase (roll).
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

	# Kumpulkan semua ikan yang rarity-nya cocok.
	var selected_list := []
	for f in fish_data:
		if typeof(f) == TYPE_DICTIONARY and f.has("rarity") and str(f["rarity"]) == selected_rarity:
			selected_list.append(f)

	# Fallback: jika tidak ada yg cocok (misal, typo), pakai semua data ikan.
	if selected_list.size() == 0:
		selected_list = fish_data.duplicate(true)

	if selected_list.size() == 0:
		return {}

	return selected_list[randi() % selected_list.size()]

# Memuat semua file .json ke variabel di script ini.
func load_all_data() -> void:
	fish_data = load_json("res://data/fish_data.json")
	quiz_data = load_json("res://data/quiz_data.json")
	
	# Siapkan daftar kuis, lalu acak urutannya.
	unused_questions = quiz_data.duplicate(true)
	unused_questions.shuffle()

# Dipanggil oleh game.gd. Mengambil 1 pertanyaan dari 'unused_questions' dan menghapusnya dari daftar.
func get_random_question() -> Dictionary:
	if unused_questions.size() == 0:
		return {}
	return unused_questions.pop_at(randi() % unused_questions.size())

# Dipanggil oleh game.gd setiap kali pemain memancing. Hanya mengurangi 'attempt'.
func next_attempt_only():
	attempts -= 1
	if attempts < 0:
		attempts = 0

# Fungsi ini untuk memulai turn baru (dipanggil oleh game.gd saat attempt habis).
func advance_to_next_turn():
	turn += 1
	attempts = attempts_per_turn

# Dipanggil oleh game.gd saat kuis benar. Menambah koin pemain.
func add_coins(amount: int) -> void:
	coins += amount

# Mereset semua state game DAN memuat ulang data dari JSON (termasuk daftar kuis).
func reset_all() -> void:
	turn = 1
	attempts = attempts_per_turn
	coins = 0
	load_all_data()

# Dipanggil dari main_menu.gd. Mereset state game untuk permainan baru.
func reset() -> void:
	print("--- DEBUG: GlobalData di-reset ---")
	turn = 1
	coins = 0
	attempts = attempts_per_turn
	target_coins = 400
