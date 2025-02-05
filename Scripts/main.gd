extends Node2D

@onready var noteUI = $Control/Background/MarginContainer/Rows/Info/ScrollContainer/HistoryRows/Notes
@onready var noteBackground = $Control/Background
@onready var scrollBar = $Control/Background/MarginContainer/Rows/Info/ScrollContainer

var speler = AudioStreamPlayer.new();
var timer := Timer.new()
var beat_timer := Timer.new()
var keys = []

var is_visual_beat_active = false

# Called when the node enters the scene tree for the first time.
func _ready():
	on_resize()
	noteUI.anchor_left = 0
	noteUI.anchor_right = 1
	scrollBar.get_v_scroll_bar().changed.connect(scroll_to_bottom)
	get_tree().get_root().size_changed.connect(on_resize) 
	# deals with audio
	self.add_child(speler);
	# timer to determine how long to wait for a note to play
	add_child(timer)
	timer.wait_time = Utils.timer_duration
	timer.one_shot = true
	# timer that adds a dash to the notes every x secs, to mimic guitar tabs
	add_child(beat_timer)
	beat_timer.wait_time = Utils.timer_duration
	beat_timer.one_shot = true
	# keeps track of all keys
	for key in $GamelanBackground.get_children():
		if key is Area2D:
			key.input_event.connect(clicked_key_event.bind(int(str(key.name).split("_")[1]) - 1))
			keys.append(key)
	
	
func add_to_notes(note):
	# for autowrapping, the vbox containing label was set to horizontal fill and expand
	noteUI.text = noteUI.text + note

var queued_sounds = []
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if beat_timer.time_left == 0 and is_visual_beat_active:
		beat_timer.start()
		add_to_notes('-')
	for i in range(1, (keys.size() * 2) + 1):
		# JUST PRESSED IS IMPORTANT FOR QUEUED SOUNDS TO WORK
		if Input.is_action_just_pressed("KEY" + str(i)):
			if i > 12: add_to_notes(str(i - 12) + "^") 
			else : add_to_notes(str(i))
			if timer.time_left == 0:
				play_audio_and_visual_cue(i)
			elif i not in queued_sounds:
				queued_sounds.append(i)
	for i in queued_sounds:
		play_audio_and_visual_cue(i)
		await timer.time_left == 0
	queued_sounds = []


func _on_play_button_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.is_pressed():
		is_visual_beat_active = !is_visual_beat_active
		if is_visual_beat_active:
			$"PlayButton/Play-button-sprite".modulate.a = 0
			$"PlayButton/Pause-button-sprite".modulate.a = 1
		else:
			$"PlayButton/Play-button-sprite".modulate.a = 1
			$"PlayButton/Pause-button-sprite".modulate.a = 0
			
			
func play_audio_and_visual_cue(key_index: int):
	speler.stream = load("res://Sound_Effects/" + str(key_index) + ".wav");
	speler.play()
	timer.start()
	var key_color: Color = Color(0.498039, 1, 0, 1)
	if key_index > 12: 
		key_index = key_index - 12
		key_color = Color(0, 1, 1, 1)
	Utils.get_child_by_type(keys[key_index-1], Polygon2D).set_color(key_color)
	var tween: Tween = create_tween()
	tween.tween_property(Utils.get_child_by_type(keys[key_index-1], Polygon2D), "modulate:a", 0, Utils.fade_duration).from(1)

func clicked_key_event(viewport, event, shape, key_index):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		add_to_notes(str(key_index+1))
		if timer.time_left == 0:
			play_audio_and_visual_cue(key_index)
		elif key_index not in queued_sounds:
			queued_sounds.append(key_index)
			
func on_resize():
	noteBackground.size.x = get_viewport().get_visible_rect().size.x
	noteBackground.size.y = get_viewport().get_visible_rect().size.y - Utils.note_background_y_offset
	$GamelanBackground.position.x = get_viewport().get_visible_rect().size.x / 2.0
	$PlayButton.position.x = get_viewport().get_visible_rect().size.x - Utils.play_button_position_x_offset
	
	
func scroll_to_bottom():
	scrollBar.scroll_vertical = scrollBar.get_v_scroll_bar().max_value
