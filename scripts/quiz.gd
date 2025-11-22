extends Control

signal quiz_done(result: bool)

# === REFERENSI UI ===
@onready var lbl_question : Label = $TextureRect/LabelQuestion
@onready var lbl_timer : Label = $TimerLabel
@onready var timer : Timer = $Timer

@onready var btn1 : TextureButton = $HBoxContainer/Answer1
@onready var btn2 : TextureButton = $HBoxContainer/Answer2
@onready var btn3 : TextureButton = $HBoxContainer/Answer3

@onready var lbl1 : Label = $HBoxContainer/Answer1/LabelAnswer1
@onready var lbl2 : Label = $HBoxContainer/Answer2/LabelAnswer1
@onready var lbl3 : Label = $HBoxContainer/Answer3/LabelAnswer1

# === DATA KUIS ===
var current_question : Dictionary = {}
var choices : Array = []
var correct_index : int = 0
var time_left : int = 20

func _ready() -> void:
	visible = false

	# Hubungkan sinyal tombol dan timer
	btn1.pressed.connect(_on_btn1)
	btn2.pressed.connect(_on_btn2)
	btn3.pressed.connect(_on_btn3)
	timer.timeout.connect(_on_timer_tick)


# ===================================================
#          MULAI KUIS (Dipanggil oleh game.gd)
# ===================================================

func start_question(q: Dictionary, seconds: int = 20) -> void:
	current_question = q

	lbl_question.text = str(q.get("question", "NO QUESTION"))

	# Isi choices
	var raw_choices = q.get("choices", [])
	if typeof(raw_choices) == TYPE_ARRAY:
		choices = raw_choices
	else:
		choices = [] # Fallback

	# Isi label jawaban (pastikan tidak error jika pilihan < 3)
	lbl1.text = "" # Reset dulu
	lbl2.text = ""
	lbl3.text = ""
	if choices.size() >= 1:
		lbl1.text = str(choices[0])
	if choices.size() >= 2:
		lbl2.text = str(choices[1])
	if choices.size() >= 3:
		lbl3.text = str(choices[2])

	# Ambil index jawaban (aman dari int/float)
	var ans = q.get("answer", 0)
	if typeof(ans) == TYPE_INT or typeof(ans) == TYPE_FLOAT:
		correct_index = int(ans)
	else:
		push_warning("Tipe data 'answer' di JSON salah, seharusnya angka.")
		correct_index = 0

	# Mulai timer
	time_left = seconds
	lbl_timer.text = str(time_left)
	timer.wait_time = 1.0
	timer.start()

	visible = true


# ===================================================
#                      TIMER
# ===================================================

func _on_timer_tick() -> void:
	time_left -= 1
	lbl_timer.text = str(time_left)

	if time_left <= 0:
		timer.stop()
		visible = false
		print("[Quiz] timeout => WRONG")
		emit_signal("quiz_done", false) # Kirim hasil Gagal


# ===================================================
#                   JAWABAN PEMAIN
# ===================================================

func _on_btn1() -> void:
	_handle_answer(0)

func _on_btn2() -> void:
	_handle_answer(1)

func _on_btn3() -> void:
	_handle_answer(2)


func _handle_answer(idx: int) -> void:
	timer.stop()
	visible = false

	var ok = (idx == correct_index)
	print("[Quiz] chosen idx =", idx, " | correct =", correct_index, " | result =", ok)

	emit_signal("quiz_done", ok) # Kirim hasil (true/false)
