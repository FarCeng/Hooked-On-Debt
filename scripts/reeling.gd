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
@onready var escape_timer: Timer = $EscapeTimer
@onready var audio_manager: Node2D = $AudioManager

@export var speed_choices := [1000, 1100, 1200, 1300, 1400, 1500]
@export var speed_increment := 100.0
@export var escape_min := 5.0
@export var escape_max := 10.0

var running: bool = false
var dir: int = 1
var speed: float = 600.0

# Dipanggil saat node siap
func _ready() -> void:
	visible = false
	if button:
		button.connect("pressed", _on_button_pressed)
	if is_instance_valid(escape_timer):
		escape_timer.one_shot = true
		escape_timer.connect("timeout", _on_escape_timeout)
	print("reeling ready — visible:", visible, " button:", button != null)

# Gerakkan panah setiap frame saat mini-game berjalan
func _process(delta: float) -> void:
	if not running:
		return
	arrow.position.x += dir * speed * delta
	if arrow.position.x <= start.position.x:
		arrow.position.x = start.position.x
		dir = 1
		_on_bounce()
	elif arrow.position.x >= end.position.x:
		arrow.position.x = end.position.x
		dir = -1
		_on_bounce()

# Mulai mini-game reeling
func start_reeling() -> void:
	if speed_choices.size() > 0:
		speed = float(speed_choices[randi() % speed_choices.size()])
	else:
		speed = 600.0
	_reset_bar()
	visible = true
	running = true
	dir = 1
	if is_instance_valid(escape_timer):
		escape_timer.start(randf_range(escape_min, escape_max))
	print("Mulai reeling — running:", running, " speed:", speed)

# Hentikan mini-game
func stop_reeling() -> void:
	running = false
	visible = false
	if is_instance_valid(escape_timer) and not escape_timer.is_stopped():
		escape_timer.stop()
	print("Stop reeling")

# Reset posisi panah ke start
func _reset_bar() -> void:
	if arrow and start:
		arrow.position.x = start.position.x
		dir = 1
		print("Posisi panah di-reset ke:", arrow.position.x)

# Saat panah memantul, tingkatkan kesulitan
func _on_bounce() -> void:
	speed += speed_increment
	print("Pantulan — kecepatan sekarang:", speed)

# Timeout: ikan kabur
func _on_escape_timeout() -> void:
	if not running:
		return
	print("Ikan kabur (escape timer)")
	stop_reeling()
	emit_signal("reeling_finished", false)

# Tombol ditekan — hitung zona dan hasil
func _on_button_pressed() -> void:
	if not running:
		return
	if is_instance_valid(audio_manager):
		audio_manager.get_node("reel_button_click").play()
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
	stop_reeling()
	emit_signal("reeling_finished", success)
	print("Player pressed. zone=", zone, " success=", success)

# Tentukan zona (red/yellow/green) berdasarkan posisi panah
func _get_zone() -> String:
	if not (arrow and start and normalstart and rarestart and rareend and normalend and end):
		return "unknown"
	var x = arrow.position.x
	var sx = start.position.x
	var nsx = normalstart.position.x
	var rsx = rarestart.position.x
	var rex = rareend.position.x
	var nex = normalend.position.x
	var ex = end.position.x
	if not (sx <= nsx and nsx <= rsx and rsx <= rex and rex <= nex and nex <= ex):
		push_warning("Marker posisi bar tidak berurutan!")
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
