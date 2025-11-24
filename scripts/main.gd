extends Control

@onready var turn_label: Label = $TurnCoinHooks/Turn
@onready var coin_label: Label = $TurnCoinHooks/CoinLabel
@onready var fish_label: Label = $TurnCoinHooks/FishLabel
@onready var turn_transition: Control = $TurnTransition
@onready var game_over_screen: Control = $GameOver
@onready var audio_manager: Node2D = $Game/AudioManager
@onready var attempts_label: Label = $TurnCoinHooks/AttemptsLabel

@onready var game_node: Node2D = $Game 
@onready var pause_button: TextureButton = $PauseButton


func _ready() -> void:
	pause_button.hide()

	game_node.coins_changed.connect(_on_coins_changed)
	game_node.fish_count_changed.connect(_on_fish_count_changed)
	game_node.turn_changed.connect(_on_turn_changed)

	game_node.connect("turn_transition_needed", _on_game_turn_transition_needed)
	game_node.connect("game_over_stats", _on_game_game_over_stats)

	turn_transition.connect("finished", _on_turn_transition_finished)
	game_over_screen.connect("continue_pressed", _on_GameOver_continue_pressed)
	
	audio_manager.play_bgm_for_turn(GlobalData.turn)

# Sinyal dari game.gd. Update label koin.
func _on_coins_changed(new_total: int) -> void:
	if coin_label:
		coin_label.text = str(new_total)

# Sinyal dari game.gd. Update label total ikan.
func _on_fish_count_changed(new_count: int) -> void:
	if fish_label:
		fish_label.text = str(new_count)

# Sinyal dari game.gd. Update label turn DAN attempt.
func _on_turn_changed(new_turn: int) -> void:
	if GlobalData == null:
		return 
	if turn_label:
		turn_label.text = "%d" % [new_turn]
	if attempts_label:
		attempts_label.text = "%d" % [GlobalData.attempts]

# Sinyal dari PauseButton. Menjeda atau melanjutkan game.
func _on_pause_button_pressed() -> void:
	get_tree().paused = !get_tree().paused

# Sinyal dari game.gd. Menampilkan UI transisi antar turn.
func _on_game_turn_transition_needed(current_turn: int, max_turns: int) -> void:
	turn_transition.show_turn(current_turn, max_turns)
	audio_manager.play_bgm_for_turn(current_turn)

# Sinyal dari game.gd. Menghentikan BGM & menampilkan layar Game Over.
func _on_game_game_over_stats(is_win: bool, final_coins: int, total_fish: int) -> void:
	if is_instance_valid(audio_manager):
		audio_manager.stop_all_bgm()
	game_over_screen.show_results(is_win, final_coins, total_fish)

# Sinyal dari TurnTransition. Memberitahu game.gd untuk lanjut.
func _on_turn_transition_finished() -> void:
	game_node.resume_from_transition()

# Sinyal dari GameOver. Pindah ke scene ending yang sesuai (menang/kalah).
func _on_GameOver_continue_pressed(is_win: bool) -> void:
	if is_win:
		get_tree().change_scene_to_file("res://scenes/Scene_Menang.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Scene_kalah.tscn")
