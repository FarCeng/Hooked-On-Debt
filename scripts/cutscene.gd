extends Control

var cutscenes = []
var durations = [3.0, 3.5, 4.0, 6.5, 5.0, 5.0, 3.5, 5.0, 6.0, 4.0, 7.0, 6.0]
var index := 0
var is_transitioning := false

@onready var skip_button: TextureButton = $Skip

# Dipanggil saat scene dimulai.
# Mengisi array 'cutscenes', menghubungkan tombol Skip, dan memulai cutscene pertama.
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

	if not skip_button.pressed.is_connected(_on_cutscene_finished):
		skip_button.pressed.connect(_on_cutscene_finished)

	index = 0
	show_cutscene(index)

# Menampilkan cutscene berdasarkan index 'i'.
# Memainkan audio yang terkait dan memulai timer otomatis.
func show_cutscene(i: int) -> void:
	var c = cutscenes[i]
	c.visible = true

	if c.has_node("AudioStreamPlayer"):
		var audio: AudioStreamPlayer = c.get_node("AudioStreamPlayer")
		audio.play()

	var timer: Timer = c.get_node("Timer")
	timer.one_shot = true
	timer.wait_time = durations[i]

	if not timer.timeout.is_connected(_on_cutscene_finished):
		timer.timeout.connect(_on_cutscene_finished)

	timer.start()
	
	is_transitioning = false

# Dipanggil oleh timer (saat durasi habis) ATAU oleh tombol 'Skip'.
# Menghentikan cutscene saat ini dan lanjut ke cutscene berikutnya, atau pindah scene jika sudah selesai.
func _on_cutscene_finished() -> void:
	if is_transitioning:
		return
	is_transitioning = true # Mencegah spam klik

	if cutscenes[index].has_node("AudioStreamPlayer"):
		cutscenes[index].get_node("AudioStreamPlayer").stop()
		
	# Hentikan timer secara manual, penting jika di-skip.
	var timer: Timer = cutscenes[index].get_node("Timer")
	timer.stop()

	cutscenes[index].visible = false
	index += 1

	if index < cutscenes.size():
		show_cutscene(index)
	else:
		# Selesai, pindah ke scene game utama.
		get_tree().change_scene_to_file("res://scenes/main.tscn")
