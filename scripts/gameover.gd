extends Control

@onready var result_label = $CenterContainer/VBox/ResultLabel
@onready var play_btn = $CenterContainer/VBox/PlayButton
@onready var bg = $Background

func _ready():
	var tex = load("res://media/background.jpg")
	if tex:
		bg.texture = tex
	result_label.text = Globals.game_result
	_style_button(play_btn, Color(0.15, 0.45, 0.15), Color(0.2, 0.65, 0.2))

func _style_button(btn: Button, normal_col: Color, hover_col: Color):
	for state in ["normal", "hover", "pressed"]:
		var sb = StyleBoxFlat.new()
		sb.bg_color = normal_col if state == "normal" else (hover_col if state == "hover" else normal_col.darkened(0.2))
		sb.border_width_left   = 2
		sb.border_width_right  = 2
		sb.border_width_top    = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.9, 0.9, 0.9, 0.85)
		sb.corner_radius_top_left     = 6
		sb.corner_radius_top_right    = 6
		sb.corner_radius_bottom_left  = 6
		sb.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override(state, sb)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
