extends Node2D

@onready var bar: Sprite2D = $bar
@onready var arrow: Sprite2D = $arrow
@onready var start: Marker2D = $start
@onready var normalstart: Marker2D = $normalstart
@onready var rarestart: Marker2D = $rarestart
@onready var rareend: Marker2D = $rareend
@onready var normalend: Marker2D = $normalend
@onready var end: Marker2D = $end
@onready var button: TextureButton = $TextureButton

var dir: int = 1
@export var speed: float = 400.0


func _ready() -> void:
	if button:
		button.connect("pressed", Callable(self, "_on_button_pressed"))
	if arrow and start:
		arrow.position.x = start.position.x


func _process(delta: float) -> void:
	if not arrow or not start or not end:
		return

	if arrow.position.x <= start.position.x:
		arrow.position.x = start.position.x
		dir = 1
	elif arrow.position.x >= end.position.x:
		arrow.position.x = end.position.x
		dir = -1

	arrow.position.x += dir * speed * delta


func _on_button_pressed() -> void:
	var zone = _get_zone()

	match zone:
		"red":
			_on_red_pressed()
		"yellow":
			_on_yellow_pressed()
		"green":
			_on_green_pressed()
		"unknown":
			pass


func _get_zone() -> String:
	if not arrow or not start or not normalstart or not rarestart or not rareend or not normalend or not end:
		return "unknown"

	var x = arrow.position.x

	var sx  = start.position.x
	var nsx = normalstart.position.x
	var rsx = rarestart.position.x
	var rex = rareend.position.x
	var nex = normalend.position.x
	var ex  = end.position.x

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


func _on_red_pressed() -> void:
	pass


func _on_yellow_pressed() -> void:
	pass


func _on_green_pressed() -> void:
	pass
