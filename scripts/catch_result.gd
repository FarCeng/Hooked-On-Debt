extends Control

signal finished(result: bool)

# Referensi UI
@onready var succeed_container: Control = $Succeed
@onready var fail_container: Control = $Fail

@onready var fish_texture: TextureRect = $Succeed/FishTexture
@onready var coin_label: Label = $Succeed/CoinLabel
@onready var lore_label: Label = $Succeed/LoreLabel
@onready var name_label: Label = $Succeed/NameLabel

# Peta nama ikan → tekstur preloaded
var fish_texture_map := {
	"Agus BRJS": preload("res://assets/images/fish/common/Agus BPJS.png"),
	"Asli banjarmasin": preload("res://assets/images/fish/common/Asli banjarmasin.png"),
	"cecep kolang kaling": preload("res://assets/images/fish/common/cecep kolang kaling.png"),
	"Habis Usia": preload("res://assets/images/fish/common/Habis Usia.png"),
	"honda suzuki": preload("res://assets/images/fish/common/honda suzuki.png"),
	"Listrik PLN": preload("res://assets/images/fish/common/Listrik PLN.png"),
	"Mimi Prikitw": preload("res://assets/images/fish/common/Mimi Prikitiw.png"),
	"Nasi Padang": preload("res://assets/images/fish/common/Nasi Padang.png"),
	"Oui Oui": preload("res://assets/images/fish/common/Oui Oui.png"),
	"Tatang skena": preload("res://assets/images/fish/common/Tatang skena.png"),

	"Area 51": preload("res://assets/images/fish/uncommon/Area 51.png"),
	"Fididdy": preload("res://assets/images/fish/uncommon/Fididdy.png"),
	"Gojo Siregar": preload("res://assets/images/fish/uncommon/Gojo Siregar.png"),
	"koin choco 1 fih": preload("res://assets/images/fish/uncommon/koin choco 1 fih.png"),
	"Miku Fih": preload("res://assets/images/fish/uncommon/Miku Fih.png"),
	"Stonks": preload("res://assets/images/fish/uncommon/Stonks.png"),

	"employment paper": preload("res://assets/images/fish/rare/employment paper.png"),
	"party": preload("res://assets/images/fish/rare/party.png"),
	"tupperware yg hilang": preload("res://assets/images/fish/rare/tupperware yg hilang.png"),

	"Stella": preload("res://assets/images/fish/legend/Stella.png")
}

var current_result: bool = false


func _ready() -> void:
	visible = false


# Menampilkan hasil tangkapan
func show_result(is_success: bool, fish_data: Dictionary = {}) -> void:
	current_result = is_success
	visible = true

	if is_success:
		succeed_container.visible = true
		fail_container.visible = false

		if fish_data.is_empty():
			push_error("CatchResult: sukses tapi fish_data kosong.")
			return

		name_label.text = fish_data.get("name", "Nama Ikan?")
		coin_label.text = str(int(fish_data.get("price", 0)))
		lore_label.text = fish_data.get("lore", "...")

		var image_id = fish_data.get("image_id", "")
		if image_id == "":
			push_warning("image_id kosong.")
			fish_texture.texture = null
		else:
			var tex = fish_texture_map.get(image_id, null)
			if tex != null:
				fish_texture.texture = tex
			else:
				push_error("Texture untuk '%s' tidak ditemukan." % image_id)
				fish_texture.texture = null

		print("Hasil: Sukses | Ikan:", fish_data)
	else:
		succeed_container.visible = false
		fail_container.visible = true
		print("Hasil: Gagal menangkap ikan")


# Input untuk menutup popup
func _input(event):
	if not visible:
		return

	var is_click = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var is_action = event.is_action_pressed("ui_accept")

	if is_click or is_action:
		get_viewport().set_input_as_handled()
		visible = false
		emit_signal("finished", current_result)
