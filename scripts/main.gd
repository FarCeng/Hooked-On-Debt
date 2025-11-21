extends Control

@onready var pause_button: TextureButton = $PauseButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalData.load_all_data()
	
	print("Fish:", GlobalData.fish_data.size())
	print("Quiz:", GlobalData.quiz_data.size())
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pause_button_pressed() -> void:
	print("pause")
	pass # Replace with function body.
