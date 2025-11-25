extends Control

func _ready():
	$Settings.visible = false
	$AnimationPlayer.play("RESET")

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")
	$".".visible = false

func pause():
	get_tree().paused = true
	$AnimationPlayer.play("blur")
	$".".visible = true

func testEsc():
	if Input.is_action_just_pressed("Open main menu") and get_tree().paused == false:
		pause()
	elif Input.is_action_just_pressed("Open main menu") and get_tree().paused == true:
		resume()


func _on_continue_pressed() -> void:
	resume()


func _on_settings_pressed() -> void:
	$Settings.visible = true


func _on_endgame_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_endturn_pressed() -> void:
	pass # Replace with function body.

func _process(delta):
	testEsc()
