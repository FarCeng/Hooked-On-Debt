extends Control

func _ready():
	visible = false   # Pause tidak muncul saat awal
	process_mode = Node.PROCESS_MODE_ALWAYS   # Tetap aktif saat paused

func show_pause():
	get_tree().paused = true
	visible = true

func hide_pause():
	get_tree().paused = false
	visible = false

func _on_continue_pressed() -> void:
	hide_pause()


func _on_end_game_pressed() -> void:
	pass # Replace with function body.


func _on_end_turn_pressed() -> void:
	pass # Replace with function body.
