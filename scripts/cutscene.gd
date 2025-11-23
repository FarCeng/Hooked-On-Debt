extends Control

var cutscenes = []
var durations = [3.0, 3.5, 4.0, 6.5, 5.0, 5.0, 3.5, 5.0, 6.0, 4.0, 7.0, 6.0]
var index := 0

func _ready():
	cutscenes = [
		$"Cutscene 1",
		$"Cutscene 2",
		$"Cutscene 3",
		$"Cutscene 4",
		$"Cutscene 5",
		$"Cutscene 6",
		$"Cutscene 7",
		$"Cutscene 8",
		$"Cutscene 9",
		$"Cutscene 10",
		$"Cutscene 11",
		$"Cutscene 12"
	]

	for c in cutscenes:
		c.visible = false

	index = 0
	show_cutscene(index)


func show_cutscene(i: int) -> void:
	var c = cutscenes[i]
	c.visible = true

	# Play Audio kalau ada
	if c.has_node("AudioStreamPlayer"):
		var audio: AudioStreamPlayer = c.get_node("AudioStreamPlayer")
		audio.play()

	# Timer
	var timer: Timer = c.get_node("Timer")
	timer.one_shot = true
	timer.wait_time = durations[i]

	if not timer.timeout.is_connected(_on_cutscene_finished):
		timer.timeout.connect(_on_cutscene_finished)

	timer.start()


func _on_cutscene_finished() -> void:
	# Stop sound jika perlu
	if cutscenes[index].has_node("AudioStreamPlayer"):
		cutscenes[index].get_node("AudioStreamPlayer").stop()

	cutscenes[index].visible = false
	index += 1

	if index < cutscenes.size():
		show_cutscene(index)
	else:
		print("Semua cutscene selesai!")
