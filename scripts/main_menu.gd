extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Settings.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	GlobalData.reset()
	get_tree().change_scene_to_file("res://scenes/Scene_Intro.tscn")


func _on_settings_pressed() -> void:
	$Settings.visible = true


func _on_quit_pressed() -> void:
	get_tree().quit()
