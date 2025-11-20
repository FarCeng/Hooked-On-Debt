extends Node2D

@onready var bite_timer: Timer = $Timer
@onready var reeling: Node2D = $Reeling
@onready var fisher: AnimatedSprite2D = $FisherDude

@export var min_wait := 1.0
@export var max_wait := 4.0

var state := "idle"  # idle, throwing, waiting, hooked, reeling, finish

func _ready():
	reeling.visible = false
	bite_timer.one_shot = true
	bite_timer.connect("timeout", Callable(self, "_on_bite"))

	# defer checking sprite_frames to avoid race with editor assignment
	call_deferred("_check_sprite_frames")

	# safe initial play if available
	_play_anim_safe("still")
	print("[INIT] Ready. State =", state)


# ---------------- Input handler ----------------
func _input(event):
	# direct Space key (Godot 4 global KEY_SPACE)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			print("[INPUT] Space pressed — calling cast()")
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

	var dur = _get_anim_len_safe("throwing")
	print("[CAST] Throwing duration =", dur)

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

	_play_anim_safe("reeling1")

	var dur = _get_anim_len_safe("reeling1")
	print("[BITE] Playing reeling1 for", dur)
	await get_tree().create_timer(dur).timeout

	print("[BITE] Switching to REELING UI")
	reeling.visible = true

	state = "reeling"
	_play_anim_safe("reeling2")  # loop animation


# ---------------- Finish reeling ----------------
# call this from your reeling UI, e.g. reeling_node.finish_reeling(true/false)
func finish_reeling(is_success: bool):
	print("[FINISH] Reeling finished. Success =", is_success)

	reeling.visible = false
	state = "finish"

	if is_success:
		_play_anim_safe("succeed")
	else:
		_play_anim_safe("fail")

	var anim_name = "succeed" if is_success else "fail"
	var dur = _get_anim_len_safe(anim_name)
	print("[FINISH] Playing", anim_name, "duration =", dur)

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
		print("[HINT] Assign SpriteFrames in the Inspector (Frames property). See", "/mnt/data/7c2c46a3-85fa-4c8b-bd77-bc588f0c2ff1.png")
	else:
		print("[CHECK] SpriteFrames OK. Animations:", sf.get_animation_names())
