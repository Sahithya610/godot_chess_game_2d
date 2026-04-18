extends Control

@onready var play_button = $VBox/PlayButton
@onready var mode_buttons = $VBox/ModeButtons
@onready var btn_ai = $VBox/ModeButtons/AIButton
@onready var btn_two_player = $VBox/ModeButtons/TwoPlayerButton
@onready var bg = $Background

func _ready():
	mode_buttons.hide()
	var tex = load("res://media/background.jpg")
	if tex:
		bg.texture = tex
	_style_button(play_button, Color(0.2, 0.6, 0.2), Color(0.3, 0.8, 0.3))
	_style_button(btn_ai, Color(0.15, 0.35, 0.6), Color(0.2, 0.5, 0.85))
	_style_button(btn_two_player, Color(0.5, 0.25, 0.1), Color(0.75, 0.4, 0.15))

func _style_button(btn: Button, normal_color: Color, hover_color: Color):
	# Normal state — filled box with border
	var normal = StyleBoxFlat.new()
	normal.bg_color = normal_color
	normal.border_width_left   = 2
	normal.border_width_right  = 2
	normal.border_width_top    = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.9, 0.9, 0.9, 0.8)
	normal.corner_radius_top_left     = 6
	normal.corner_radius_top_right    = 6
	normal.corner_radius_bottom_left  = 6
	normal.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", normal)

	# Hover state
	var hover = StyleBoxFlat.new()
	hover.bg_color = hover_color
	hover.border_width_left   = 2
	hover.border_width_right  = 2
	hover.border_width_top    = 2
	hover.border_width_bottom = 2
	hover.border_color = Color(1.0, 1.0, 1.0, 1.0)
	hover.corner_radius_top_left     = 6
	hover.corner_radius_top_right    = 6
	hover.corner_radius_bottom_left  = 6
	hover.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("hover", hover)

	# Pressed state — slightly darker
	var pressed = StyleBoxFlat.new()
	pressed.bg_color = normal_color.darkened(0.2)
	pressed.border_width_left   = 2
	pressed.border_width_right  = 2
	pressed.border_width_top    = 2
	pressed.border_width_bottom = 2
	pressed.border_color = Color(1.0, 1.0, 1.0, 0.6)
	pressed.corner_radius_top_left     = 6
	pressed.corner_radius_top_right    = 6
	pressed.corner_radius_bottom_left  = 6
	pressed.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))

func _on_play_pressed():
	play_button.hide()
	mode_buttons.show()

func _on_ai_pressed():
	Globals.selected_mode = Globals.PLAYER_2_TYPE.AI
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_two_player_pressed():
	Globals.selected_mode = Globals.PLAYER_2_TYPE.HUMAN
	get_tree().change_scene_to_file("res://scenes/game.tscn")
