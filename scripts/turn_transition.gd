extends Control

signal finished

@export var fade_in_duration := 0.5
@export var min_display_duration := 2.5

@onready var turn_label: Label = $TurnLabel
@onready var prompt_label: Label = $PromptLabel

var is_clickable := false

func _ready() -> void:
	modulate.a = 0.0
	visible = false
	prompt_label.visible = false

func show_turn(current_turn: int, max_turns: int) -> void:
	is_clickable = false
	modulate.a = 0.0
	turn_label.text = "TURN %s / %s" % [current_turn, max_turns]
	visible = true
	
	prompt_label.visible = false

	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)
	
	await get_tree().create_timer(min_display_duration).timeout
	
	is_clickable = true
	prompt_label.visible = true

func _input(event: InputEvent) -> void:
	if not visible or not is_clickable:
		return

	var is_click = event is InputEventMouseButton and event.pressed
	var is_action = event.is_action_pressed("ui_accept")

	if is_click or is_action:
		get_viewport().set_input_as_handled()
		
		visible = false
		modulate.a = 0.0
		emit_signal("finished")
