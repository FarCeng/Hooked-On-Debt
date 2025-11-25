extends Control

signal continue_pressed(is_win: bool)

@onready var succeed_panel: TextureRect = $Succeed
@onready var fail_panel: TextureRect = $Fail
@onready var total_fish_label: Label = $TotalFish
@onready var total_coin_label: Label = $TotalCoin
@onready var next_button: TextureButton = $NextButton
@onready var audio_manager: Node2D = $AudioManager

var current_is_win: bool = false

# Setup awal: sembunyikan panel dan hubungkan tombol
func _ready() -> void:
	succeed_panel.visible = false
	fail_panel.visible = false
	next_button.connect("pressed", _on_NextButton_pressed)
	print("Endscreen: ready")

# Tampilkan hasil akhir — dipanggil dari main.gd
func show_results(is_win: bool, final_coins: int, total_fish: int) -> void:
	current_is_win = is_win

	if is_win:
		if is_instance_valid(audio_manager):
			audio_manager.get_node("succeed").play()
		succeed_panel.visible = true
		fail_panel.visible = false
	else:
		if is_instance_valid(audio_manager):
			audio_manager.get_node("fail").play()
		succeed_panel.visible = false
		fail_panel.visible = true

	total_coin_label.text = str(final_coins)
	total_fish_label.text = str(total_fish)

	visible = true
	print("Endscreen: show_results — is_win=", is_win, " coins=", final_coins, " fish=", total_fish)

# Tombol Next ditekan — tutup layar dan beri tahu main
func _on_NextButton_pressed() -> void:
	if is_instance_valid(audio_manager):
		audio_manager.get_node("UI_button_clik").play()
	visible = false
	emit_signal("continue_pressed", current_is_win)
	print("Endscreen: Next pressed — is_win=", current_is_win)
