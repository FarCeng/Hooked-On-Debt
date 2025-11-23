extends Node2D
# Manages the main fishing gameplay loop and state machine.
# Mengatur alur gameplay utama (memancing) dan state machine.

# --- SINYAL UNTUK UI UTAMA (main.gd) ---
signal coins_changed(new_total: int)
signal fish_count_changed(new_count: int)
signal turn_changed(new_turn: int)
signal turn_transition_needed(current_turn, max_turns)
signal game_over_stats(is_win, final_coins, fish_counts_dict: Dictionary)

# --- REFERENSI NODE (Diatur via CanvasLayers) ---
@onready var bite_timer: Timer = $Timer
@onready var fisher: AnimatedSprite2D = $FisherDude
@onready var audio_manager: Node2D = $AudioManager

# Node UI ditempatkan di dalam CanvasLayer "PopupLayer"
@onready var reeling: Node = $PopupLayer/Reeling
@onready var quiz: Control = $PopupLayer/Quiz
@onready var catch_result: Control = $PopupLayer/CatchResult

# Background gelap ditempatkan di CanvasLayer "UILayer"
@onready var low_opacity_bg: ColorRect = $UILayer/LowOpacityBg

# --- KONFIGURASI ---
@export var min_wait := 1.0
@export var max_wait := 6.0

# --- GAME STATE ---
# State machine utama game.
# (idle, throwing, waiting, hooked, reeling, showing_quiz, finish)
var state := "idle"
var _pending_fish : Variant = null # Ikan yg didapat, menunggu hasil kuis

# Data sesi lokal (direset jika ganti scene)
var fish_count : int = 0
var fish_inventory : Array = []


# ===================================================
# --- FUNGSI BAWAAN GODOT ---
# ===================================================

func _ready() -> void:
	# Inisialisasi, hubungkan sinyal internal, dan emit state awal.
	if GlobalData == null:
		push_error("[INIT] WARNING: GlobalData Autoload TIDAK DITEMUKAN (null).")
	
	# Setup node internal
	reeling.visible = false
	bite_timer.one_shot = true
	bite_timer.connect("timeout", _on_bite)

	# Hubungkan sinyal dari node anak (via deferred call agar aman)
	call_deferred("_check_sprite_frames")
	call_deferred("_connect_reeling_signal")
	call_deferred("_connect_quiz_signal")
	call_deferred("_connect_catch_result_signal")

	_play_anim_safe("still") # Animasi idle awal
	if is_instance_valid(low_opacity_bg):
		low_opacity_bg.modulate.a = 0.0
	# Kirim data awal (dari GlobalData) ke UI (main.gd)
	if GlobalData != null:
		emit_signal("coins_changed", GlobalData.coins)
		emit_signal("turn_changed", GlobalData.turn)
	else:
		# Fallback jika GlobalData gagal load (misal: Run Scene F6)
		emit_signal("coins_changed", 0)
		emit_signal("turn_changed", 1)

	emit_signal("fish_count_changed", fish_count)


func _input(event) -> void:
	# Meneruskan input ke fungsi 'cast' jika state sedang 'idle'
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			cast()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		cast()
	if event.is_action_pressed("cast"):
		cast()


# ===================================================
# --- PENANGAN SINYAL (SIGNAL HANDLERS) ---
# ===================================================

# Dipanggil oleh sinyal 'finished' dari CatchResult SETELAH pemain mengklik.
func _on_catch_result_finished(result: bool) -> void:
	# Tampilkan lagi fisher
	if is_instance_valid(fisher):
		fisher.visible = true

	# Sembunyikan background gelap
	if is_instance_valid(low_opacity_bg):
		var tween = get_tree().create_tween()
		# Animasikan "modulate:a" (alpha) dari 1.0 ke 0.0 (transparan)
		tween.tween_property(low_opacity_bg, "modulate:a", 0.0, 0.5)

	# Mainkan animasi hasil (succeed/fail) dan TUNGGU (await)
	if result:
		if is_instance_valid(audio_manager):
			audio_manager.get_node("fisherdude_happy").play()
		await _play_anim_and_wait("succeed")
	else:
		await _play_anim_and_wait("fail")
	
	if is_instance_valid(low_opacity_bg):
		low_opacity_bg.hide() #hide bg

	print("[GAME] Final animation done, returning to idle.")
	state = "idle"
	_play_anim_safe("still")


# Dipanggil oleh sinyal 'reeling_finished' dari Reeling.
func _on_reeling_finished(success: bool) -> void:
	# Hanya proses jika kita memang sedang reeling
	if state != "reeling" and state != "hooked":
		return
	# Defer call untuk menghindari error "signal re-entrancy"
	call_deferred("_deferred_finish_reeling", success)


func _deferred_finish_reeling(success: bool) -> void:
	finish_reeling(success) # Panggil alur logika utama


# Dipanggil oleh sinyal 'quiz_done' dari Quiz.
func _on_quiz_done(result: bool) -> void:
	if is_instance_valid(quiz):
		quiz.visible = false
	
	# Tampilkan lagi fisher (yang disembunyikan saat kuis)
	if is_instance_valid(fisher):
		fisher.visible = true
	
	state = "finish" # Masuk state "finish" (menunggu popup result)
	
	var fish = _pending_fish
	_pending_fish = null

	if fish == null:
		push_warning("[GAME] Kuis selesai tapi _pending_fish kosong.")

	if result:
		# --- KUIS BENAR ---
		if fish != null:
			# Tambah data
			fish_inventory.append(fish)
			fish_count += 1
			var price = int(fish.get("price", 0))

			# Update GlobalData
			if GlobalData != null:
				GlobalData.add_coins(price)
				emit_signal("coins_changed", GlobalData.coins)
			
			emit_signal("fish_count_changed", fish_count)
			
			# Tampilkan popup "Success"
			if is_instance_valid(audio_manager):
				audio_manager.get_node("succeed").play()
			if is_instance_valid(catch_result):
				catch_result.show_result(true, fish) # Kirim data ikan
		else:
			# Kuis benar tapi tidak ada ikan? Aneh. Anggap gagal.
			if is_instance_valid(catch_result):
				catch_result.show_result(false)
	
	else:
		# --- KUIS SALAH ---
		if is_instance_valid(audio_manager):
			audio_manager.get_node("fail").play()
		if is_instance_valid(catch_result):
			catch_result.show_result(false) # Tampilkan popup "Fail"
	
	# Game sekarang menunggu input di CatchResult, yang akan memicu
	# sinyal 'finished' dan ditangani oleh '_on_catch_result_finished'.


# ===================================================
# --- STATE MACHINE (ALUR GAME) ---
# ===================================================

# Fungsi utama yg dipanggil oleh Input. Memulai alur memancing.
func cast() -> void:
	# 1. Cek State
	if state != "idle":
		return

	# 2. [LOGIKA BARU] Cek Game Over
	if GlobalData.turn > GlobalData.max_turns:
		_show_game_over_screen()
		return

	# 3. [LOGIKA BARU] Cek Transisi Turn
	if GlobalData.attempts <= 0:
		state = "transition" # Set state sibuk

		GlobalData.advance_to_next_turn() # Panggil fungsi baru GlobalData
		emit_signal("turn_changed", GlobalData.turn) # Update UI

		# Cek lagi, mungkin ini turn terakhir
		if GlobalData.turn > GlobalData.max_turns:
			_show_game_over_screen()
		else:
			# Beri tahu main.gd untuk menampilkan UI transisi
			emit_signal("turn_transition_needed", GlobalData.turn, GlobalData.max_turns)

		return # Berhenti di sini, jangan lanjut cast

	# --- Jika semua cek di atas lolos, baru kita lanjutkan cast ---

	# 4. Kurangi Attempt & Update UI
	#if is_instance_valid(audio_manager):
		#audio_manager.get_node("UI_button_clik").play() # (Ganti nama node jika perlu)

	GlobalData.next_attempt_only() # Panggil fungsi attempt yang baru
	emit_signal("turn_changed", GlobalData.turn) # (Ini akan update UI attempts)

	# 5. Mulai Alur Memancing (Kode lama Anda)
	state = "throwing"
	_play_anim_safe("throwing")

	# (Sisa kode await dan audio splash Anda)
	await get_tree().create_timer(0.9).timeout
	if is_instance_valid(audio_manager):
		audio_manager.get_node("water_splash").play()

	await get_tree().create_timer(0.06).timeout
	var dur = _get_anim_len_safe("throwing")
	if dur > 0.0:
		await get_tree().create_timer(dur).timeout

	state = "waiting"
	_play_anim_safe("waiting")

	var wait_time = randf_range(min_wait, max_wait)
	bite_timer.start(wait_time)

# Dipicu oleh Timer. Memulai mini-game reeling.
func _on_bite() -> void:
	if state != "waiting":
		return # Input dibatalkan, dll.

	state = "hooked"
	if is_instance_valid(audio_manager):
		audio_manager.get_node("water_splash").play()
	if is_instance_valid(audio_manager):
		audio_manager.get_node("reeling").play()
	# Tampilkan background gelap
	if is_instance_valid(low_opacity_bg):
		low_opacity_bg.show() # Tampilkan node-nya (yang masih transparan)
		var tween = get_tree().create_tween()
		# Animasikan "modulate:a" (alpha) dari 0.0 ke 1.0 (terlihat)
		tween.tween_property(low_opacity_bg, "modulate:a", 1.0, 0.3)
		
	print("[BITE] FISH HOOKED! → state = hooked")
		
	# Mainkan animasi "hooked"
	_play_anim_safe("reeling1")
	var r1_dur = _get_anim_len_safe("reeling1")
	if r1_dur > 0.0:
		await get_tree().create_timer(r1_dur).timeout

	await get_tree().create_timer(0.18).timeout # Buffer

	# Tampilkan mini-game reeling
	if is_instance_valid(reeling) and reeling.has_method("start_reeling"):
		reeling.call_deferred("start_reeling")
	else:
		push_warning("[BITE] reeling.start_reeling() tidak ditemukan.")
		if is_instance_valid(reeling):
			reeling.visible = true

	# Masuk state "reeling" (looping animasi)
	state = "reeling"
	_play_anim_safe("reeling2")


# Dipanggil oleh sinyal 'reeling_finished'. Menentukan lanjut ke Kuis atau Gagal.
func finish_reeling(is_success: bool) -> void:
	if state == "idle":
		return # Sinyal telat, abaikan

	if is_instance_valid(reeling):
		reeling.visible = false
	if is_instance_valid(audio_manager):
		audio_manager.get_node("reeling").stop()
	# PAUSE animasi 'reeling2' di frame saat ini
	fisher.stop() 

	if is_success:
		# --- REELING SUKSES -> Lanjut ke Kuis ---
		state = "showing_quiz"
		
		var fish = null
		if GlobalData != null and GlobalData.has_method("get_random_fish"):
			fish = GlobalData.get_random_fish()
		if fish == null or fish.is_empty(): # Fallback
			fish = {"id":"fish_dummy","name":"Ikan Contoh","rarity":"common","price":10}
		_pending_fish = fish # Simpan ikan untuk nanti

		var question_data = null
		if GlobalData != null and GlobalData.has_method("get_random_question"):
			question_data = GlobalData.get_random_question()
		if question_data == null or question_data.is_empty(): # Fallback
			question_data = { "question": "Fallback?", "choices": ["A", "B", "C"], "answer": 1 }

		if is_instance_valid(quiz) and quiz.has_method("start_question"):
			quiz.visible = true
			quiz.start_question(question_data, 10)
			return # Game menunggu sinyal 'quiz_done'
		else:
			# Gagal memuat kuis, anggap sukses (fallback)
			push_warning("[FINISH] Quiz node/fungsi start_question() tidak ditemukan.")
			if is_instance_valid(catch_result):
				catch_result.call_deferred("show_result", true, fish)
			
	else:
		# --- REELING GAGAL ---
		state = "finish" # Langsung ke state "finish"
		if is_instance_valid(audio_manager):
			audio_manager.get_node("fail").play()
		if is_instance_valid(catch_result):
			catch_result.call_deferred("show_result", false) # Tampilkan popup "Fail"
		
		# Game menunggu input di CatchResult
		return


# ===================================================
# --- HELPERS ---
# ===================================================

# Helper untuk menghubungkan sinyal dari node anak
func _connect_catch_result_signal() -> void:
	if not is_instance_valid(catch_result):
		push_warning("[CONNECT] CatchResult node not found")
		return
	var cb := Callable(self, "_on_catch_result_finished")
	if not catch_result.is_connected("finished", cb):
		catch_result.connect("finished", cb)

func _connect_reeling_signal() -> void:
	if not is_instance_valid(reeling):
		push_warning("[CONNECT] reeling node not valid")
		return
	if not reeling.has_signal("reeling_finished"):
		push_warning("[CONNECT] reeling node has no 'reeling_finished' signal")
		return

	var cb := Callable(self, "_on_reeling_finished")
	if not reeling.is_connected("reeling_finished", cb):
		reeling.connect("reeling_finished", cb)

func _connect_quiz_signal() -> void:
	if not is_instance_valid(quiz):
		push_warning("[CONNECT] quiz node not found - quiz integration skipped")
		return
	var cb := Callable(self, "_on_quiz_done")
	if not quiz.is_connected("quiz_done", cb):
		quiz.connect("quiz_done", cb)

# Helper untuk memainkan animasi dengan aman
func _play_anim_safe(name: String) -> void:
	if not is_instance_valid(fisher):
		return
	var sf = fisher.sprite_frames
	if sf == null:
		return
	if sf.has_animation(name):
		fisher.play(name)

# Helper untuk mendapatkan durasi animasi
func _get_anim_len_safe(name: String) -> float:
	if not is_instance_valid(fisher):
		return 0.0
	var sf = fisher.sprite_frames
	if sf == null:
		return 0.0
	if not sf.has_animation(name):
		return 0.0
	var frames = sf.get_frame_count(name)
	var fps = sf.get_animation_speed(name)
	if fps <= 0:
		return 0.0
	return float(frames) / float(fps)

# Helper untuk mengecek SpriteFrames saat startup
func _check_sprite_frames() -> void:
	if not is_instance_valid(fisher):
		push_warning("[CHECK] fisher node not found")
		return
	var sf = fisher.sprite_frames
	if sf == null:
		push_warning("[CHECK] AnimatedSprite2D has no SpriteFrames assigned on node: " + fisher.name)
		print("[HINT] Assign SpriteFrames in the Inspector.")

# Helper untuk memainkan animasi dan MENUNGGU (await) sampai selesai.
func _play_anim_and_wait(name: String) -> void:
	var dur = _get_anim_len_safe(name)
	
	if dur > 0.0:
		_play_anim_safe(name)
		await get_tree().create_timer(dur).timeout
	else:
		_play_anim_safe(name)

# Di dalam game.gd

func _show_game_over_screen() -> void:
	# Hanya jalankan sekali
	if state == "game_over":
		return
		
	state = "game_over"
	
	var final_coins = GlobalData.coins
	var total_fish = fish_inventory.size() # <-- Kita kembali pakai total_fish
	
	# --- DEBUG PRINT #1 (Seperti yang Anda minta) ---
	print("--- DEBUG GAME OVER ---")
	print("Koin Didapat: ", final_coins)
	print("Target Koin: ", GlobalData.target_coins)
	# -----------------------------------------------

	# --- PERBAIKAN BUG "WIN" ADA DI SINI ---
	# Kita cek >= (lebih besar atau SAMA DENGAN)
	var is_win = (final_coins >= GlobalData.target_coins)
	# -----------------------------------------------
	
	# --- DEBUG PRINT #2 (Seperti yang Anda minta) ---
	if is_win:
		print("HASIL: Menang (Good Ending)")
	else:
		print("HASIL: Kalah (Bad Ending)")
	print("-------------------------")

	# Kirim sinyal (hanya kirim total_fish, BUKAN dictionary)
	emit_signal("game_over_stats", is_win, final_coins, total_fish)

func resume_from_transition() -> void:
	state = "idle"
