extends Node2D
# Mengatur alur gameplay utama (memancing) dan state machine.

# Sinyal yang dikirim ke main.gd (UI)
signal coins_changed(new_total: int)
signal fish_count_changed(new_count: int)
signal turn_changed(new_turn: int)
signal turn_transition_needed(current_turn, max_turns)
signal game_over_stats(is_win, final_coins, fish_counts: int)

# Referensi node
@onready var bite_timer: Timer = $Timer
@onready var fisher: AnimatedSprite2D = $FisherDude
@onready var audio_manager: Node2D = $AudioManager

# Node UI di CanvasLayer "PopupLayer"
@onready var reeling: Node = $PopupLayer/Reeling
@onready var quiz: Control = $PopupLayer/Quiz
@onready var catch_result: Control = $PopupLayer/CatchResult

# Background gelap di CanvasLayer "UILayer"
@onready var low_opacity_bg: ColorRect = $UILayer/LowOpacityBg

@export var min_wait := 1.0
@export var max_wait := 6.0

# State machine utama game.
# (idle, throwing, waiting, hooked, reeling, showing_quiz, finish)
var state := "idle"
var _pending_fish : Variant = null # Ikan yg didapat, menunggu hasil kuis

# Data sesi lokal
var fish_count : int = 0
var fish_inventory : Array = []

# Dipanggil saat node dimuat. Menghubungkan sinyal & setup awal.
func _ready() -> void:
	if GlobalData == null:
		push_error("GlobalData Autoload TIDAK DITEMUKAN (null).")

	reeling.visible = false
	bite_timer.one_shot = true
	bite_timer.connect("timeout", _on_bite)

	if GlobalData != null:
		print("game.gd: Membaca GlobalData. Turn: ", GlobalData.turn, ", Koin: ", GlobalData.coins)

	# Hubungkan sinyal dari node anak
	call_deferred("_check_sprite_frames")
	call_deferred("_connect_reeling_signal")
	call_deferred("_connect_quiz_signal")
	call_deferred("_connect_catch_result_signal")

	_play_anim_safe("still")
	if is_instance_valid(low_opacity_bg):
		low_opacity_bg.modulate.a = 0.0

	# Kirim data awal ke UI (main.gd)
	if GlobalData != null:
		emit_signal("coins_changed", GlobalData.coins)
		emit_signal("turn_changed", GlobalData.turn)
	else:
		emit_signal("coins_changed", 0)
		emit_signal("turn_changed", 1)

	emit_signal("fish_count_changed", fish_count)

# Menangani input pemain (Spasi/Klik) untuk memancing.
func _input(event) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			cast()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		cast()

# Sinyal dari CatchResult. Dipanggil SETELAH pemain mengklik popup hasil.
func _on_catch_result_finished(result: bool) -> void:
	if is_instance_valid(fisher):
		fisher.visible = true

	if is_instance_valid(low_opacity_bg):
		var tween = get_tree().create_tween()
		tween.tween_property(low_opacity_bg, "modulate:a", 0.0, 0.5)

	if result:
		if is_instance_valid(audio_manager):
			audio_manager.get_node("fisherdude_happy").play()
		await _play_anim_and_wait("succeed")
	else:
		await _play_anim_and_wait("fail")

	if is_instance_valid(low_opacity_bg):
		low_opacity_bg.hide()

	print("Game: Animasi selesai, kembali ke idle.")
	state = "idle"
	_play_anim_safe("still")

# Sinyal dari Reeling.gd. Dipanggil saat mini-game reeling selesai.
func _on_reeling_finished(success: bool) -> void:
	if state != "reeling" and state != "hooked":
		return
	call_deferred("_deferred_finish_reeling", success)

# Helper
func _deferred_finish_reeling(success: bool) -> void:
	finish_reeling(success)

# Sinyal dari Quiz.gd
func _on_quiz_done(result: bool) -> void:
	if is_instance_valid(quiz):
		quiz.visible = false

	if is_instance_valid(fisher):
		fisher.visible = true

	state = "finish"

	var fish = _pending_fish
	_pending_fish = null

	if fish == null:
		push_warning("Kuis selesai tapi _pending_fish kosong.")

	if result:
		# Kuis Benar
		if fish != null:
			fish_inventory.append(fish)
			fish_count += 1
			var price = int(fish.get("price", 0))

			if GlobalData != null:
				GlobalData.add_coins(price)
				emit_signal("coins_changed", GlobalData.coins)

			emit_signal("fish_count_changed", fish_count)

			if is_instance_valid(audio_manager):
				audio_manager.get_node("succeed").play()
			if is_instance_valid(catch_result):
				catch_result.show_result(true, fish)
	else:
		if is_instance_valid(catch_result):
			catch_result.show_result(false)

	# Kuis Salah
	if not result:
		if is_instance_valid(audio_manager):
			audio_manager.get_node("fail").play()
		if is_instance_valid(catch_result):
			catch_result.show_result(false)

# Fungsi utama input
func cast() -> void:
	if state != "idle":
		return

	if GlobalData.turn > GlobalData.max_turns:
		_show_game_over_screen()
		return

	if GlobalData.attempts <= 0:
		state = "transition"
		GlobalData.advance_to_next_turn()
		emit_signal("turn_changed", GlobalData.turn)

		if GlobalData.turn > GlobalData.max_turns:
			_show_game_over_screen()
		else:
			emit_signal("turn_transition_needed", GlobalData.turn, GlobalData.max_turns)
		return

	GlobalData.next_attempt_only()
	emit_signal("turn_changed", GlobalData.turn)

	state = "throwing"
	_play_anim_safe("throwing")

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

# Dipicu timer
func _on_bite() -> void:
	if state != "waiting":
		return

	state = "hooked"

	if is_instance_valid(audio_manager):
		audio_manager.get_node("water_splash").play()
	if is_instance_valid(audio_manager):
		audio_manager.get_node("reeling").play()

	if is_instance_valid(low_opacity_bg):
		low_opacity_bg.show()
		var tween = get_tree().create_tween()
		tween.tween_property(low_opacity_bg, "modulate:a", 1.0, 0.3)

	print("Game: Ikan terkail!")

	_play_anim_safe("reeling1")
	var r1_dur = _get_anim_len_safe("reeling1")
	if r1_dur > 0.0:
		await get_tree().create_timer(r1_dur).timeout

	await get_tree().create_timer(0.18).timeout

	if is_instance_valid(reeling) and reeling.has_method("start_reeling"):
		reeling.call_deferred("start_reeling")
	else:
		push_warning("reeling.start_reeling() tidak ditemukan.")
		if is_instance_valid(reeling):
			reeling.visible = true

	state = "reeling"
	_play_anim_safe("reeling2")

# Menentukan lanjut ke Kuis atau gagal
func finish_reeling(is_success: bool) -> void:
	if state == "idle":
		return

	if is_instance_valid(reeling):
		reeling.visible = false
	if is_instance_valid(audio_manager):
		audio_manager.get_node("reeling").stop()
	fisher.stop()

	if is_success:
		state = "showing_quiz"

		var fish = null
		if GlobalData != null and GlobalData.has_method("get_random_fish"):
			fish = GlobalData.get_random_fish()
		if fish == null or fish.is_empty():
			fish = {"id":"fish_dummy","name":"Ikan Contoh","rarity":"common","price":10}
		_pending_fish = fish

		var question_data = null
		if GlobalData != null and GlobalData.has_method("get_random_question"):
			question_data = GlobalData.get_random_question()
		if question_data == null or question_data.is_empty():
			question_data = { "question": "Fallback?", "choices": ["A", "B", "C"], "answer": 1 }

		if is_instance_valid(quiz) and quiz.has_method("start_question"):
			quiz.visible = true
			quiz.start_question(question_data, 30)
			return
		else:
			push_warning("Quiz node/fungsi start_question() tidak ditemukan.")
			if is_instance_valid(catch_result):
				catch_result.call_deferred("show_result", true, fish)
	else:
		state = "finish"
		if is_instance_valid(audio_manager):
			audio_manager.get_node("fail").play()
		if is_instance_valid(catch_result):
			catch_result.call_deferred("show_result", false)
		return

# Hubungkan sinyal
func _connect_catch_result_signal() -> void:
	if not is_instance_valid(catch_result):
		push_warning("CatchResult node not found")
		return
	var cb := Callable(self, "_on_catch_result_finished")
	if not catch_result.is_connected("finished", cb):
		catch_result.connect("finished", cb)

func _connect_reeling_signal() -> void:
	if not is_instance_valid(reeling):
		push_warning("reeling node not valid")
		return
	if not reeling.has_signal("reeling_finished"):
		push_warning("reeling node has no 'reeling_finished' signal")
		return

	var cb := Callable(self, "_on_reeling_finished")
	if not reeling.is_connected("reeling_finished", cb):
		reeling.connect("reeling_finished", cb)

func _connect_quiz_signal() -> void:
	if not is_instance_valid(quiz):
		push_warning("quiz node not found - quiz integration skipped")
		return
	var cb := Callable(self, "_on_quiz_done")
	if not quiz.is_connected("quiz_done", cb):
		quiz.connect("quiz_done", cb)

# Animasi aman
func _play_anim_safe(name: String) -> void:
	if not is_instance_valid(fisher):
		return
	var sf = fisher.sprite_frames
	if sf == null:
		return
	if sf.has_animation(name):
		fisher.play(name)

# Dapatkan durasi animasi
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

# Cek sprite frame di awal
func _check_sprite_frames() -> void:
	if not is_instance_valid(fisher):
		push_warning("fisher node not found")
		return
	var sf = fisher.sprite_frames
	if sf == null:
		push_warning("AnimatedSprite2D has no SpriteFrames assigned on node: " + fisher.name)
		print("HINT: Assign SpriteFrames in the Inspector.")

# Menunggu animasi selesai
func _play_anim_and_wait(name: String) -> void:
	var dur = _get_anim_len_safe(name)

	if dur > 0.0:
		_play_anim_safe(name)
		await get_tree().create_timer(dur).timeout
	else:
		_play_anim_safe(name)

# Game over
func _show_game_over_screen() -> void:
	if state == "game_over":
		return

	state = "game_over"

	var final_coins = GlobalData.coins
	var total_fish = fish_inventory.size()

	print("--- DEBUG GAME OVER ---")
	print("Koin Didapat: ", final_coins)
	print("Target Koin: ", GlobalData.target_coins)

	var is_win = (final_coins >= GlobalData.target_coins)

	if is_win:
		print("HASIL: Menang (Good Ending)")
	else:
		print("HASIL: Kalah (Bad Ending)")
	print("-------------------------")

	emit_signal("game_over_stats", is_win, final_coins, total_fish)

# Dipanggil main.gd
func resume_from_transition() -> void:
	state = "idle"
