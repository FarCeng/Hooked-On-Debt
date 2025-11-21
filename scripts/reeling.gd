# ReelingBar.gd (simple, easy to debug)
extends Node2D

signal reeling_finished(success: bool)

@onready var bar: Sprite2D = $bar
@onready var arrow: Sprite2D = $arrow
@onready var start: Marker2D = $start
@onready var normalstart: Marker2D = $normalstart
@onready var rarestart: Marker2D = $rarestart
@onready var rareend: Marker2D = $rareend
@onready var normalend: Marker2D = $normalend
@onready var end: Marker2D = $end
@onready var button: TextureButton = $TextureButton
@onready var escape_timer: Timer = $EscapeTimer  # make sure you add this Timer child

# config
@export var speed_choices := [1000,1100,1200,1300,1400,1500]
@export var speed_increment := 100.0
@export var escape_min := 5.0
@export var escape_max := 10.0

# runtime
var running: bool = false
var dir: int = 1
var speed: float = 600.0

func _ready() -> void:
	visible = false
	if button:
		button.connect("pressed", Callable(self, "_on_button_pressed"))
	if is_instance_valid(escape_timer):
		escape_timer.one_shot = true
		escape_timer.connect("timeout", Callable(self, "_on_escape_timeout"))
	# Safety prints
	print("[REEL READY] Reeling node ready. Arrow path:", arrow, "Start:", start, "End:", end)

func start_reeling() -> void:
	# basic start: pick initial speed, show UI and reset arrow instantly
	if speed_choices.size() > 0:
		speed = float(speed_choices[randi() % speed_choices.size()])
	else:
		speed = 600.0
	_reset_bar()  # instant reset to start.x
	visible = true
	running = true
	dir = 1
	# start escape timer
	if is_instance_valid(escape_timer):
		escape_timer.start(randf_range(escape_min, escape_max))
	print("[REEL START] speed =", speed, "escape in", escape_timer.time_left if is_instance_valid(escape_timer) else "(no escape_timer)")

func stop_reeling() -> void:
	running = false
	visible = false
	# stop escape timer
	if is_instance_valid(escape_timer) and not escape_timer.is_stopped():
		escape_timer.stop()
	print("[REEL STOP] reeling stopped")

func _reset_bar() -> void:
	if arrow and start:
		arrow.position.x = start.position.x
		dir = 1

func _process(delta: float) -> void:
	if not running:
		return
	# move arrow simple linear
	arrow.position.x += dir * speed * delta
	# bounce at edges
	if arrow.position.x <= start.position.x:
		arrow.position.x = start.position.x
		dir = 1
		_on_bounce()
	elif arrow.position.x >= end.position.x:
		arrow.position.x = end.position.x
		dir = -1
		_on_bounce()

func _on_bounce() -> void:
	# increase speed on each bounce so difficulty ramps slightly
	speed += speed_increment
	print("[REEL] Bounce -> new speed:", speed)

func _on_button_pressed() -> void:
	if not running:
		return
	var zone = _get_zone()
	var success = false
	match zone:
		"green":
			success = true
		"yellow":
			success = randf() < 0.5
		"red":
			success = false
		_:
			success = false
	# stop and emit result
	stop_reeling()
	emit_signal("reeling_finished", success)
	print("[REEL] Player pressed. zone=", zone, "success=", success)

func _on_escape_timeout() -> void:
	# fish escapes
	if not running:
		return
	print("[REEL] Escape timer fired — fish escaped")
	stop_reeling()
	emit_signal("reeling_finished", false)

func _get_zone() -> String:
	# safe checks
	if not (arrow and start and normalstart and rarestart and rareend and normalend and end):
		return "unknown"
	var x = arrow.position.x
	var sx  = start.position.x
	var nsx = normalstart.position.x
	var rsx = rarestart.position.x
	var rex = rareend.position.x
	var nex = normalend.position.x
	var ex  = end.position.x
	# ensure order
	if not (sx <= nsx and nsx <= rsx and rsx <= rex and rex <= nex and nex <= ex):
		return "unknown"
	if x >= sx and x <= nsx:
		return "red"
	elif x > nsx and x <= rsx:
		return "yellow"
	elif x > rsx and x <= rex:
		return "green"
	elif x > rex and x <= nex:
		return "yellow"
	elif x > nex and x <= ex:
		return "red"
	return "unknown"
