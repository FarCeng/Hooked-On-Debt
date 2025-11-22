extends Control
# Script ini mengontrol UI utama (Main HUD) dan bertindak sebagai "Scene Manager".
# Ia mendengarkan sinyal dari 'game_node' dan 'GlobalData' untuk memperbarui UI.

# --- REFERENSI NODE ---
@onready var turn_label: Label = $TurnCoinHooks/Turn
@onready var coin_label: Label = $TurnCoinHooks/CoinLabel
@onready var fish_label: Label = $TurnCoinHooks/FishLabel

# Node Gameplay (scene game.tscn)
@onready var game_node: Node2D = $Game 

# Node UI Lainnya
@onready var pause_button: TextureButton = $PauseButton


# --- FUNGSI BAWAAN GODOT ---

func _ready() -> void:
	# Validasi node
	if game_node == null:
		push_error("Main.gd: Node 'Game' tidak ditemukan! UI tidak akan terhubung.")
		return
	if GlobalData == null:
		push_error("Main.gd: Autoload 'GlobalData' tidak ditemukan! UI tidak akan terhubung.")
		return

	# Hubungkan sinyal dari 'game.gd' (untuk UI in-game)
	game_node.coins_changed.connect(_on_coins_changed)
	game_node.fish_count_changed.connect(_on_fish_count_changed)
	game_node.turn_changed.connect(_on_turn_changed)

	# Hubungkan sinyal dari 'GlobalData' (untuk state game global)
	GlobalData.game_over.connect(_on_game_over)
	
	# Atur tampilan UI awal saat game dimulai
	_on_coins_changed(GlobalData.coins)
	_on_turn_changed(GlobalData.turn)
	_on_fish_count_changed(0) # 'fish_count' adalah data sesi (selalu 0 di awal)


# --- FUNGSI PENANGAN SINYAL (SIGNAL HANDLERS) ---

func _on_coins_changed(new_total: int) -> void:
	if coin_label:
		coin_label.text = str(new_total)

func _on_fish_count_changed(new_count: int) -> void:
	if fish_label:
		fish_label.text = str(new_count)

func _on_turn_changed(new_turn: int) -> void:
	if turn_label and GlobalData != null:
		# Perbaikan: Format teks agar sesuai UI ("1 / 6")
		turn_label.text = "%d" % [new_turn]


func _on_game_over(is_good_ending: bool) -> void:
	# Dipanggil oleh sinyal 'game_over' dari GlobalData
	print("MAIN MENERIMA SINYAL GAME OVER! Good ending: ", is_good_ending)

	get_tree().paused = true # Hentikan semua proses

	# Pindahkan scene ke ending yang sesuai
	if is_good_ending:
		get_tree().change_scene_to_file("res://scenes/good_ending.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/bad_ending.tscn")


# --- FUNGSI TOMBOL UI ---

func _on_pause_button_pressed() -> void:
	# Logika dasar untuk pause/unpause game
	get_tree().paused = !get_tree().paused
	
	# TODO: Tampilkan/sembunyikan Menu Pause Anda di sini
	# if get_tree().paused:
	#	  $PauseMenu.show()
	# else:
	#	  $PauseMenu.hide()
