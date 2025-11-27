extends Control

@onready var place_holder: TextureRect = $PlaceHolder
@onready var objective: TextureRect = $Objective
@onready var start: TextureButton = $Start
@onready var target_coin: Label = $TargetCoin


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	place_holder.visible = false
	objective.visible = false
	start.visible = false
	target_coin.visible = false
	
