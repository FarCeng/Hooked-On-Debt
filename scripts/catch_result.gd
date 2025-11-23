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
	# --- COMMON ---
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
	
	# --- UNCOMMON ---
	"Area 51": preload("res://assets/images/fish/uncommon/Area 51.png"),
	"Fididdy": preload("res://assets/images/fish/uncommon/Fididdy.png"),
	"Gojo Siregar": preload("res://assets/images/fish/uncommon/Gojo Siregar.png"),
	"koin choco 1 fih": preload("res://assets/images/fish/uncommon/koin choco 1 fih.png"),
	"Miku Fih": preload("res://assets/images/fish/uncommon/Miku Fih.png"),
	"Stonks": preload("res://assets/images/fish/uncommon/Stonks.png"),

	# --- RARE ---
	"employment paper": preload("res://assets/images/fish/rare/employment paper.png"),
	"party": preload("res://assets/images/fish/rare/party.png"),
	"tupperware yg hilang": preload("res://assets/images/fish/rare/tupperware yg hilang.png"),

	# --- LEGEND ---
	"Stella": preload("res://assets/images/fish/legend/Stella.png")
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
