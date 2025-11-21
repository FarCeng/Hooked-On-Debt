extends Control

var cutscenes = []
var index := 0

func _ready():
	cutscenes = [$"Cutscene 1",$"Cutscene 2",$"Cutscene 3",$"Cutscene 4"]

	for c in cutscenes:
		c.visible = false

	index = 0
	show_cutscene(index)


func show_cutscene(i: int) -> void:
	var c = cutscenes[i]
	c.visible = true

	var timer: Timer = c.get_node("Timer")
	timer.one_shot = true

	# FORMAT GODOT 4 YANG BENAR
	if not timer.timeout.is_connected(_on_cutscene_finished):
		timer.timeout.connect(_on_cutscene_finished)

	timer.wait_time = 5.0
	timer.start()


func _on_cutscene_finished() -> void:
	cutscenes[index].visible = false
	index += 1
	
	if index < cutscenes.size():
		show_cutscene(index)
	else:
		print("Semua cutscene selesai!")
