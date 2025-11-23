extends Control

# Sinyal: Dipancarkan saat popup ditutup, mengirimkan hasil (sukses/gagal).
signal finished(result: bool)

# === REFERENSI NODE ===
@onready var succeed_container: Control = $Succeed
@onready var fail_container: Control = $Fail

# Referensi untuk UI 'Succeed'
@onready var fish_texture: TextureRect = $Succeed/FishTexture
@onready var coin_label: Label = $Succeed/CoinLabel
@onready var lore_label: Label = $Succeed/LoreLabel
@onready var name_label: Label = $Succeed/NameLabel

var fish_texture_map := {
	"stella": preload("res://assets/images/fish/stella.png"),
	"tatang_skena": preload("res://assets/images/fish/tatang_skena.png"),
	"employment_paper": preload("res://assets/images/fish/employment_paper.png"),
	"koin_choco_1_fih": preload("res://assets/images/fish/koin_choco_1_fih.png"),
	"cecep_kolang_kaling": preload("res://assets/images/fish/cecep_kolang_kaling.png"),
	"party": preload("res://assets/images/fish/party.png"),
	"tupperware_emak_yg_hilang": preload("res://assets/images/fish/tupperware_emak_yg_hilang.png"),
	"stonks": preload("res://assets/images/fish/stonks.png"),
	"miku_fih": preload("res://assets/images/fish/miku_fih.png"),
	"gojo_siregar": preload("res://assets/images/fish/gojo_siregar.png"),
	"fididdy": preload("res://assets/images/fish/fididdy.png"),
	"area_51": preload("res://assets/images/fish/area_51.png"),
	"agus_bpjs": preload("res://assets/images/fish/agus_bpjs.png"),
	"asli_banjarmasin": preload("res://assets/images/fish/asli_banjarmasin.png"),
	"habis_usia": preload("res://assets/images/fish/habis_usia.png"),
	"honda_suzuki": preload("res://assets/images/fish/honda_suzuki.png"),
	"mimi_prikitiw": preload("res://assets/images/fish/mimi_prikitiw.png"),
	"nasi_padang": preload("res://assets/images/fish/nasi_padang.png"),
	"oui_oui": preload("res://assets/images/fish/oui_oui.png"),
	"listrik_pln": preload("res://assets/images/fish/listrik_pln.png")
}

# Variabel untuk menyimpan hasil saat ini
var current_result: bool = false

func _ready() -> void:
	visible = false

# ===================================================
#          FUNGSI UTAMA (Dipanggil oleh game.gd)
# ===================================================

func show_result(is_success: bool, fish_data: Dictionary = {}) -> void:
	current_result = is_success
	visible = true
	
	if is_success:
		# --- TAMPILAN SUKSES ---
		succeed_container.visible = true
		fail_container.visible = false
		
		if fish_data.is_empty():
			push_error("CatchResult: 'is_success' true, tapi 'fish_data' kosong!")
			return

		# Atur Teks (cast ke int() agar tidak ada ".0")
		name_label.text = fish_data.get("name", "Nama Ikan?")
		coin_label.text = str(int(fish_data.get("price", 0)))
		lore_label.text = fish_data.get("lore", "...")

		# --- Logika memuat gambar (dengan path dinamis) ---
		var image_path = ""
		var image_id = fish_data.get("image_id", "")
		if image_id == "":
			push_warning("Warning: 'image_id' kosong di JSON.")
			fish_texture.texture = null
		else:
			# Langsung cari di kamus
			var preloaded_tex = fish_texture_map.get(image_id, null)
			
			if preloaded_tex != null:
				fish_texture.texture = preloaded_tex # Berhasil!
			else:
				# Error ini berarti Anda salah ketik ID di JSON atau belum
				# menambahkannya ke 'fish_texture_map' di atas
				push_error("Error: Tekstur untuk ID '%s' tidak ditemukan di fish_texture_map." % image_id)
				fish_texture.texture = null
		# --- Akhir blok gambar ---
			
	else:
		# --- TAMPILAN GAGAL ---
		succeed_container.visible = false
		fail_container.visible = true


# ===================================================
#                TANGANI INPUT UNTUK MENUTUP
# ===================================================

func _input(event):
	# Hanya proses input jika popup ini terlihat
	if not visible:
		return

	var is_click = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var is_action = event.is_action_pressed("ui_accept") # "ui_accept" (Spasi/Enter)

	if is_click or is_action:
		get_viewport().set_input_as_handled() # Agar klik tidak "tembus"
		visible = false
		
		# Pancarkan sinyal 'finished' DAN kirim kembali hasilnya
		emit_signal("finished", current_result)
