extends Control

signal finished

@onready var background: ColorRect = $Background
@onready var turn_label: Label = $TurnLabel
@onready var prompt_label: Label = $PromptLabel

func _ready() -> void:
	# Start hidden (transparent)
	modulate.a = 0.0
	visible = false
	print("TurnPopup: ready")

# Show turn popup (dipanggil oleh main.gd)
func show_turn(current_turn: int, max_turns: int) -> void:
	turn_label.text = "TURN %s / %s" % [current_turn, max_turns]
	visible = true

	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	print("TurnPopup: show_turn ->", current_turn, "/", max_turns)

# Tunggu input klik untuk melanjutkan
func _input(event: InputEvent) -> void:
	if not visible:
		return

	var is_click = event is InputEventMouseButton and event.pressed
	if is_click:
		get_viewport().set_input_as_handled()
		visible = false
		emit_signal("finished")
		print("TurnPopup: clicked -> emit finished")
