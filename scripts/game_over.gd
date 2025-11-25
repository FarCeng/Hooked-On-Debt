extends Control

# Sinyal dikirim saat tombol "NextButton" ditekan
signal continue_pressed(is_win: bool)

# --- REFERENSI NODE ---
@onready var succeed_panel: TextureRect = $Succeed
@onready var fail_panel: TextureRect = $Fail
@onready var total_fish_label: Label = $TotalFish
@onready var total_coin_label: Label = $TotalCoin
@onready var next_button: TextureButton = $NextButton
@onready var audio_manager: Node2D = $AudioManager

# Variabel untuk menyimpan status
var current_is_win: bool = false

func _ready() -> void:
	# Sembunyikan panel "Succeed" dan "Fail" saat mulai
	succeed_panel.visible = false
	fail_panel.visible = false
	
	# Hubungkan sinyal tombol
	next_button.connect("pressed", _on_NextButton_pressed)

# Fungsi utama yang dipanggil oleh main.gd
func show_results(is_win: bool, final_coins: int, total_fish: int) -> void:
	current_is_win = is_win
	
	if is_win:
		# Tampilkan panel SUKSES
		if is_instance_valid(audio_manager):
			audio_manager.get_node("succeed").play()
		succeed_panel.visible = true
		fail_panel.visible = false
	else:
		# Tampilkan panel GAGAL
		if is_instance_valid(audio_manager):
			audio_manager.get_node("fail").play()
		succeed_panel.visible = false
		fail_panel.visible = true
		
	# Atur label (kembali ke logika simpel)
	total_coin_label.text = str(final_coins)
	total_fish_label.text = str(total_fish)
		
	visible = true

# Saat tombol "NextButton" ditekan
func _on_NextButton_pressed() -> void:
	if is_instance_valid(audio_manager):
			audio_manager.get_node("UI_button_clik").play()
	visible = false
	emit_signal("continue_pressed", current_is_win)
