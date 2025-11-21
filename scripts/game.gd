extends Node2D

@onready var bite_timer: Timer = $Timer
@onready var reeling: Node = $Reeling
@onready var fisher: AnimatedSprite2D = $FisherDude

@export var min_wait := 1.0
@export var max_wait := 6.0

var state := "idle"  # idle, throwing, waiting, hooked, reeling, finish

func _ready():
	# setup
	reeling.visible = false
	bite_timer.one_shot = true
	bite_timer.connect("timeout", Callable(self, "_on_bite"))

	# defer checking sprite_frames to avoid race with editor assignment
	call_deferred("_check_sprite_frames")

	# connect reeling_finished signal safely (deferred so node tree ready)
	call_deferred("_connect_reeling_signal")

	# safe initial play if available
	_play_anim_safe("still")
	print("[INIT] Ready. State =", state)


# ---------------- connect helper ----------------
func _connect_reeling_signal() -> void:
	if not is_instance_valid(reeling):
		print("[CONNECT] reeling node not valid")
		return
	if not reeling.has_signal("reeling_finished"):
		print("[CONNECT] reeling node has no 'reeling_finished' signal")
		return

	var cb := Callable(self, "_on_reeling_finished")
	# is_connected expects the same Callable object that would be used to connect
	if not reeling.is_connected("reeling_finished", cb):
		reeling.connect("reeling_finished", cb)
		print("[CONNECT] connected to reeling_finished")
	else:
		print("[CONNECT] already connected to reeling_finished")


# ---------------- Input handler ----------------
func _input(event):
	# direct Space key (Godot 4 global KEY_SPACE)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			print("[INPUT] Space pressed — calling cast()")
			cast()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		cast()
	# fallback to action "cast" if user configured InputMap
	if event.is_action_pressed("cast"):
		print("[INPUT] Action 'cast' pressed — calling cast()")
		cast()


# ---------------- Cast flow ----------------
func cast():
	print("[CAST] called. current state:", state)
	if state != "idle":
		print("[CAST] ignored — not idle")
		return

	print("[CAST] Casting started!")
	state = "throwing"
	_play_anim_safe("throwing")

	# small safety delay (optional)
	await get_tree().create_timer(0.06).timeout

	var dur = _get_anim_len_safe("throwing")
	print("[CAST] Throwing duration =", dur)
	if dur > 0.0:
		await get_tree().create_timer(dur).timeout

	print("[CAST] Done throwing → state = waiting")
	state = "waiting"
	_play_anim_safe("waiting")

	var wait_time = randf_range(min_wait, max_wait)
	print("[WAITING] Timer started for", wait_time, "seconds")
	bite_timer.start(wait_time)


# ---------------- Bite / hook ----------------
func _on_bite():
	print("[_on_bite] timer timeout. current state:", state)
	if state != "waiting":
		print("[BITE] ignored, wrong state")
		return

	state = "hooked"
	print("[BITE] FISH HOOKED! → state = hooked")

	# 1) play reeling1 once
	_play_anim_safe("reeling1")
	var r1_dur = _get_anim_len_safe("reeling1")
	print("[BITE] reeling1 dur:", r1_dur)
	if r1_dur > 0.0:
		await get_tree().create_timer(r1_dur).timeout

	# small buffer before popup so it's not jarring
	await get_tree().create_timer(0.18).timeout

	# 2) show reeling UI and start its logic (call_deferred to be safe)
	if is_instance_valid(reeling) and reeling.has_method("start_reeling"):
		reeling.call_deferred("start_reeling")
		print("[BITE] called start_reeling()")
	else:
		# fallback: just show it and try to set visible
		print("[BITE] reeling.start_reeling missing — fallback visible true")
		if is_instance_valid(reeling):
			reeling.visible = true

	# 3) set state and loop reeling animation
	state = "reeling"
	_play_anim_safe("reeling2")


# ---------------- Reeling finished signal handler ----------------
func _on_reeling_finished(success: bool) -> void:
	print("[SIGNAL] reeling_finished received. success=", success, " current_state=", state)

	# only respond if we were in reeling/hooked state (avoid stray)
	if state != "reeling" and state != "hooked":
		print("[SIGNAL] ignoring because state =", state)
		return

	# defer actual finish to avoid re-entrancy
	call_deferred("_deferred_finish_reeling", success)


func _deferred_finish_reeling(success: bool) -> void:
	# call the existing finish flow
	finish_reeling(success)


# ---------------- Finish reeling ----------------
# call this to play result animation then return to idle
func finish_reeling(is_success: bool):
	# guard: if already idle, ignore
	if state == "idle":
		print("[FINISH] called but already idle — ignoring")
		return

	print("[FINISH] Reeling finished. Success =", is_success)

	# ensure UI hidden if not already
	if is_instance_valid(reeling):
		reeling.visible = false

	# set intermediate state
	state = "finish"

	# play proper result anim
	if is_success:
		var fish = GlobalData.get_random_fish()
		print("[DEBUG] GOT FISH:", fish)
		# kamu bisa simpan juga:
		GlobalData.current_fish = fish
		_play_anim_safe("succeed")
	else:
		_play_anim_safe("fail")


	var anim_name = "succeed" if is_success else "fail"
	var dur = _get_anim_len_safe(anim_name)
	print("[FINISH] Playing", anim_name, "duration =", dur)

	if dur > 0.0:
		await get_tree().create_timer(dur).timeout

	print("[FINISH] done. Returning to idle")
	state = "idle"
	_play_anim_safe("still")


# ---------------- Helpers (safe sprite_frames access) ----------------
func _play_anim_safe(name: String) -> void:
	if not is_instance_valid(fisher):
		return
	var sf = fisher.sprite_frames
	if sf == null:
		# no SpriteFrames assigned — skip playing but avoid crashing
		return
	if sf.has_animation(name):
		fisher.play(name)


func _get_anim_len_safe(name: String) -> float:
	# returns anim duration (seconds) or 0 if not available
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


func _check_sprite_frames() -> void:
	if not is_instance_valid(fisher):
		print("[CHECK] fisher node not found")
		return
	var sf = fisher.sprite_frames
	if sf == null:
		# print_err (not push_error) so debugger won't auto-break; informative for dev
		print("[CHECK] AnimatedSprite2D has no SpriteFrames assigned on node:", fisher.name)
		print("[HINT] Assign SpriteFrames in the Inspector (Frames property). See /mnt/data/7c2c46a3-85fa-4c8b-bd77-bc588f0c2ff1.png")
	else:
		print("[CHECK] SpriteFrames OK. Animations:", sf.get_animation_names())
