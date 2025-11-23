extends Control
# Script ini mengontrol UI utama (Main HUD) dan bertindak sebagai "Scene Manager".
# Ia mendengarkan sinyal dari 'game_node' dan 'GlobalData' untuk memperbarui UI.

# --- REFERENSI NODE ---
@onready var turn_label: Label = $TurnCoinHooks/Turn
@onready var coin_label: Label = $TurnCoinHooks/CoinLabel
@onready var fish_label: Label = $TurnCoinHooks/FishLabel
@onready var turn_transition: Control = $TurnTransition
@onready var game_over_screen: Control = $GameOver
@onready var audio_manager: Node2D = $Game/AudioManager

# Node Gameplay (scene game.tscn)
@onready var game_node: Node2D = $Game 

# Node UI Lainnya
@onready var pause_button: TextureButton = $PauseButton


# --- FUNGSI BAWAAN GODOT ---

func _ready() -> void:
	# ... (Validasi node Anda) ...

	# Hubungkan sinyal dari 'game.gd'
	game_node.coins_changed.connect(_on_coins_changed)
	game_node.fish_count_changed.connect(_on_fish_count_changed)
	game_node.turn_changed.connect(_on_turn_changed)

	# --- HAPUS KONEKSI LAMA INI ---
	# GlobalData.game_over.connect(_on_game_over)

	# --- TAMBAHKAN KONEKSI BARU INI ---
	# 1. Dengarkan sinyal DARI game.gd
	game_node.connect("turn_transition_needed", _on_game_turn_transition_needed)
	game_node.connect("game_over_stats", _on_game_game_over_stats)

	# 2. Dengarkan sinyal DARI UI baru
	turn_transition.connect("finished", _on_turn_transition_finished)
	game_over_screen.connect("continue_pressed", _on_GameOver_continue_pressed)
	
	audio_manager.play_bgm_for_turn(GlobalData.turn)

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

# --- FUNGSI TOMBOL UI ---

func _on_pause_button_pressed() -> void:
	# Logika dasar untuk pause/unpause game
	get_tree().paused = !get_tree().paused

# --- FUNGSI HANDLER BARU (TAMBAHKAN INI DI main.gd) ---

# Dipanggil oleh sinyal "turn_transition_needed" dari game.gd
func _on_game_turn_transition_needed(current_turn: int, max_turns: int) -> void:
	# Suruh UI TurnTransition untuk tampil
	turn_transition.show_turn(current_turn, max_turns)
	audio_manager.play_bgm_for_turn(current_turn)

# Dipanggil oleh sinyal "game_over_stats" dari game.gd
func _on_game_game_over_stats(is_win: bool, final_coins: int, total_fish: int) -> void:
	if is_instance_valid(audio_manager):
		audio_manager.stop_all_bgm()
	game_over_screen.show_results(is_win, final_coins, total_fish)

# Dipanggil oleh sinyal "finished" dari TurnTransition (saat diklik)
func _on_turn_transition_finished() -> void:
	# Beritahu game.gd untuk lanjut
	game_node.resume_from_transition() # <-- INI PERBAIKANNYA

# Dipanggil oleh sinyal "continue_pressed" dari GameOverScreen (saat tombol 'Next' ditekan)
func _on_GameOver_continue_pressed(is_win: bool) -> void:
	if is_win:
		get_tree().change_scene_to_file("res://scenes/cutscenes/good_ending.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/cutscenes/bad_ending.tscn")
	# TODO: Tampilkan/sembunyikan Menu Pause Anda di sini
	# if get_tree().paused:
	#	  $PauseMenu.show()
	# else:
	#	  $PauseMenu.hide()
