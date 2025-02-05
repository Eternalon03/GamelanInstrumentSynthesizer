extends Control

var fade_duration = 0.5
var timer_duration = 0.05
var play_button_position_x_offset = 1150
var note_background_y_offset = 520


func get_child_by_type(Parent, T):
	for child in Parent.get_children():
		if is_instance_of(child, T):
			return child
