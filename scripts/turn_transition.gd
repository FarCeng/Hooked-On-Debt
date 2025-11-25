extends Control

# Sinyal yang dikirim saat pemain mengklik
signal finished

@onready var background: ColorRect = $Background
@onready var turn_label: Label = $TurnLabel
@onready var prompt_label: Label = $PromptLabel

func _ready() -> void:
	# Mulai dalam keadaan transparan penuh
	modulate.a = 0.0

# Fungsi ini akan dipanggil oleh main.gd
func show_turn(current_turn: int, max_turns: int) -> void:
	# Sekarang kita bisa menampilkan "TURN 2 / 6"
	turn_label.text = "TURN %s / %s" % [current_turn, max_turns]
	visible = true

	# Efek Fade In
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

# Menunggu input klik
func _input(event: InputEvent) -> void:
	# Hanya proses jika terlihat
	if not visible:
		return

	# Cek jika ada klik mouse ATAU sentuhan layar
	var is_click = event is InputEventMouseButton and event.pressed

	if is_click:
		get_viewport().set_input_as_handled() # Hentikan input agar tidak "tembus"

		# Sembunyikan UI dan kirim sinyal
		visible = false
		emit_signal("finished")
