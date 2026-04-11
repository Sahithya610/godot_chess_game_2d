extends Node2D

# Game States
var game_over;
var player_color;
var status; # who is playing
var player2_type; # Where AI or Human is playing

# To drag piece
var is_dragging: bool;
var selected_piece = null;
var previous_position = null;
var move_indicators = []

@onready var board = $Board;
@onready var ui_control = $Control
@onready var win_label = $"Control/Win Label"

# Called when the node enters the scene tree for the first time.
func _ready():
	init_game()
	ui_control.hide()
	win_label.hide()
	
func _input(event):
	if game_over:
		return
	# Mouse left clicks/drags
	if Input.is_action_just_pressed("left_click"):
		var pos = get_pos_under_mouse()
		selected_piece = board.get_piece(pos)
		# Drag piece only if they are under the mouse or are of current player
		if selected_piece == null or selected_piece.color != status:
			return
		is_dragging = true
		previous_position = selected_piece.position
		selected_piece.z_index = 100
		show_valid_moves(selected_piece)
	elif event is InputEventMouseMotion and is_dragging:
		selected_piece.position = get_global_mouse_position()
	elif Input.is_action_just_released("left_click") and is_dragging:
		var is_valid_move = drop_piece()
		if !is_valid_move:
			selected_piece.position = previous_position
		selected_piece.z_index = 0
		clear_move_indicators()
		selected_piece = null
		is_dragging = false
		
		# Check whether game is over after user's move
		if evaluate_end_game():
			return
		
		# If playerA has made valid move, then switch to other player's move
		if is_valid_move:
			player2_move()

func init_game():
	game_over = false
	is_dragging = false 
	player_color = Globals.COLORS.WHITE
	status = Globals.COLORS.WHITE
	#player2_type = Globals.PLAYER_2_TYPE.HUMAN
	player2_type = Globals.PLAYER_2_TYPE.AI

func get_pos_under_mouse():
	var pos = get_global_mouse_position()
	pos.x = int(pos.x / 60)
	pos.y = int(pos.y / 60)
	return pos

func drop_piece():
	var to_move = get_pos_under_mouse()
	if valid_move(selected_piece.board_position, to_move):
		# For valid move:
		# - if target has piece, then replace it
		var dest_piece = board.get_piece(to_move)
		# Delete only if the target piece is of different color
		if dest_piece != null and dest_piece.color != selected_piece.color:
			board.delete_piece(dest_piece)
		selected_piece.move_position(to_move)
		# - change current status of active color
		status = Globals.COLORS.BLACK if status == Globals.COLORS.WHITE else Globals.COLORS.WHITE
		return true
	return false

func valid_move(from_pos, to_pos):
	var board_copy = board.clone()
	var src_piece = board_copy.get_piece(from_pos)
	
	# If we cannot move to threatened or moveable position
	if(
		to_pos not in src_piece.get_moveable_positions() 
		and 
		to_pos not in src_piece.get_threatened_positions()
	):
		return false
	
	
	var dst_piece = board_copy.get_piece(to_pos)
	if dst_piece != null:
		board_copy.delete_piece(dst_piece)
	src_piece.move_position(to_pos)
	
	# Check whether there is no check threaten the color
	for piece in board_copy.pieces:
		if status == Globals.COLORS.BLACK and board_copy.black_king_pos in piece.get_threatened_positions():
			return false
		if status == Globals.COLORS.WHITE and board_copy.white_king_pos in piece.get_threatened_positions():
			return false
	
	return true

func get_valid_moves():
	# Get possible moves for current player
	var valid_moves = []
	for piece in board.pieces:
		if piece.color == status:
			var candi_pos = piece.get_moveable_positions()
			if piece.piece_type == Globals.PIECE_TYPES.PAWN:
				candi_pos += piece.get_threatened_positions()
			candi_pos = unique(candi_pos)
			for pos in candi_pos:
				if valid_move(piece.board_position, pos):
					valid_moves.append([piece, pos])
	return valid_moves

func unique(arr: Array) -> Array:
	var dict = {}
	for a in arr:
		dict[a] = 1
	return dict.keys()


func player2_move():
	# Make a move when player2 is AI, else default controller is with user itself
	if player2_type == Globals.PLAYER_2_TYPE.AI:
		var valid_moves = get_valid_moves()
		if len(valid_moves) == 0:
			set_win(Globals.PLAYER.ONE)
			return
		var move = valid_moves.pick_random()
		var piece = move[0]
		var pos = move[1]
		var dest_piece = board.get_piece(pos)
		# Delete only if the target piece is found
		if dest_piece != null:
			board.delete_piece(dest_piece)
		piece.move_position(pos)
		status = Globals.COLORS.BLACK if status == Globals.COLORS.WHITE else Globals.COLORS.WHITE
		evaluate_end_game()

func evaluate_end_game():
	# Check whether the current user can make any legal move
	var moves = get_valid_moves()
	if len(moves) == 0:
		game_over = true
		set_win(Globals.PLAYER.TWO if status == player_color else Globals.PLAYER.ONE)
		return true
	return false

func set_win(who: Globals.PLAYER):
	game_over = true
	if who == Globals.PLAYER.ONE:
		win_label.text = "Player One Won"
	else:
		win_label.text = "Player Two Won"
	win_label.show()
	ui_control.show()


func _on_button_pressed():
	get_tree().reload_current_scene()

func show_valid_moves(piece):
	clear_move_indicators()
	
	var candi_pos = piece.get_moveable_positions()
	if piece.piece_type == Globals.PIECE_TYPES.PAWN:
		candi_pos += piece.get_threatened_positions()
	candi_pos = unique(candi_pos)
	
	for pos in candi_pos:
		if valid_move(piece.board_position, pos):
			create_move_indicator(pos)

func create_move_indicator(board_pos: Vector2):
	var indicator = ColorRect.new()
	var dot_size = 20
	indicator.size = Vector2(dot_size, dot_size)
	indicator.position = Vector2(
		board_pos.x * 60 + 30 - dot_size / 2,
		board_pos.y * 60 + 30 - dot_size / 2
	)
	
	# Check if there's a piece at this position (capture move)
	var target_piece = board.get_piece(board_pos)
	if target_piece != null and target_piece.color != status:
		# Red circle for capture moves
		indicator.color = Color(0.9, 0.2, 0.2, 0.6)
	else:
		# Green circle for regular moves
		indicator.color = Color(0.2, 0.8, 0.2, 0.6)
	
	indicator.z_index = 50
	board.add_child(indicator)
	move_indicators.append(indicator)

func clear_move_indicators():
	for indicator in move_indicators:
		indicator.queue_free()
	move_indicators.clear()
