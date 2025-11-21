extends Control

# --- ONREADY ---
@onready var lbl_question  : Label = $TextureRect/LabelQuestion
@onready var lbl_timer     : Label = $PanelBackground/TimerLabel
@onready var timer         : Timer = $Timer

@onready var btn1 : TextureButton = $HBoxContainer/Answer1
@onready var btn2 : TextureButton = $HBoxContainer/Answer2
@onready var btn3 : TextureButton = $HBoxContainer/Answer3

@onready var lbl1 : Label = $HBoxContainer/Answer1/LabelAnswer1
@onready var lbl2 : Label = $HBoxContainer/Answer2/LabelAnswer1
@onready var lbl3 : Label = $HBoxContainer/Answer3/LabelAnswer1

# --- DATA ---
var current_question : Dictionary = {}
var choices : Array = []             # 3 pilihan
var correct_answer : String = ""     # jawaban benar
var time_left : int = 30

# SINYAL KE GAME
signal quiz_done(result : bool)


func _ready():
	visible = true
	btn1.pressed.connect(_on_answer1)
	btn2.pressed.connect(_on_answer2)
	btn3.pressed.connect(_on_answer3)
	timer.timeout.connect(_on_timer_tick)


# ----------------------------------------------------------
#  CALL INI DARI GAME: Quiz.start_question(GlobalData.get_random_question())
# ----------------------------------------------------------
func start_question(q : Dictionary) -> void:
	if q.size() == 0:
		push_warning("Quiz: dictionary question kosong!")
		return

	current_question = q
	visible = true

	# Isi data
	lbl_question.text = str(q.get("question", "NO QUESTION"))
	choices = q.get("choices", [])
	correct_answer = str(q.get("answer", ""))

	# Kasih teks ke tombol
	if choices.size() >= 3:
		lbl1.text = str(choices[0])
		lbl2.text = str(choices[1])
		lbl3.text = str(choices[2])
	else:
		print("ERROR: choices kurang dari 3!")

	# Reset timer
	time_left = 30
	lbl_timer.text = str(time_left)
	timer.start(1.0)


# ---------------------------------------------------------
#   TIMER HITUNG MUNDUR
# ---------------------------------------------------------
func _on_timer_tick():
	time_left -= 1
	lbl_timer.text = str(time_left)

	if time_left <= 0:
		timer.stop()
		visible = false
		emit_signal("quiz_done", false)   # gagal karena timeout


# ----------------------------------------------------------
#   JAWABAN PLAYER
# ----------------------------------------------------------
func _on_answer1(): _handle_answer(lbl1.text)
func _on_answer2(): _handle_answer(lbl2.text)
func _on_answer3(): _handle_answer(lbl3.text)


func _handle_answer(text : String):
	timer.stop()
	visible = false

	var is_correct := false
	if text == correct_answer:
		is_correct = true

	emit_signal("quiz_done", is_correct)
