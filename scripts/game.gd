extends Node2D

# --- AI Configuration ---
const DIFFICULTY = {"EASY": 1, "HARD": 3}
var ai_depth = DIFFICULTY["HARD"]

# --- Piece Values (centipawns) ---
const PIECE_VALUES = {
	Globals.PIECE_TYPES.PAWN:   100,
	Globals.PIECE_TYPES.KNIGHT: 320,
	Globals.PIECE_TYPES.BISHOP: 330,
	Globals.PIECE_TYPES.ROOK:   500,
	Globals.PIECE_TYPES.QUEEN:  900,
	Globals.PIECE_TYPES.KING:   20000,
}

# --- Piece-Square Tables (White's perspective, row 0 = rank 8) ---
const PST_PAWN = [
	 0,  0,  0,  0,  0,  0,  0,  0,
	50, 50, 50, 50, 50, 50, 50, 50,
	10, 10, 20, 30, 30, 20, 10, 10,
	 5,  5, 10, 25, 25, 10,  5,  5,
	 0,  0,  0, 20, 20,  0,  0,  0,
	 5, -5,-10,  0,  0,-10, -5,  5,
	 5, 10, 10,-20,-20, 10, 10,  5,
	 0,  0,  0,  0,  0,  0,  0,  0,
]
const PST_KNIGHT = [
	-50,-40,-30,-30,-30,-30,-40,-50,
	-40,-20,  0,  0,  0,  0,-20,-40,
	-30,  0, 10, 15, 15, 10,  0,-30,
	-30,  5, 15, 20, 20, 15,  5,-30,
	-30,  0, 15, 20, 20, 15,  0,-30,
	-30,  5, 10, 15, 15, 10,  5,-30,
	-40,-20,  0,  5,  5,  0,-20,-40,
	-50,-40,-30,-30,-30,-30,-40,-50,
]
const PST_BISHOP = [
	-20,-10,-10,-10,-10,-10,-10,-20,
	-10,  0,  0,  0,  0,  0,  0,-10,
	-10,  0,  5, 10, 10,  5,  0,-10,
	-10,  5,  5, 10, 10,  5,  5,-10,
	-10,  0, 10, 10, 10, 10,  0,-10,
	-10, 10, 10, 10, 10, 10, 10,-10,
	-10,  5,  0,  0,  0,  0,  5,-10,
	-20,-10,-10,-10,-10,-10,-10,-20,
]
const PST_ROOK = [
	 0,  0,  0,  0,  0,  0,  0,  0,
	 5, 10, 10, 10, 10, 10, 10,  5,
	-5,  0,  0,  0,  0,  0,  0, -5,
	-5,  0,  0,  0,  0,  0,  0, -5,
	-5,  0,  0,  0,  0,  0,  0, -5,
	-5,  0,  0,  0,  0,  0,  0, -5,
	-5,  0,  0,  0,  0,  0,  0, -5,
	 0,  0,  0,  5,  5,  0,  0,  0,
]
const PST_QUEEN = [
	-20,-10,-10, -5, -5,-10,-10,-20,
	-10,  0,  0,  0,  0,  0,  0,-10,
	-10,  0,  5,  5,  5,  5,  0,-10,
	 -5,  0,  5,  5,  5,  5,  0, -5,
	  0,  0,  5,  5,  5,  5,  0, -5,
	-10,  5,  5,  5,  5,  5,  0,-10,
	-10,  0,  5,  0,  0,  0,  0,-10,
	-20,-10,-10, -5, -5,-10,-10,-20,
]
const PST_KING = [
	-30,-40,-40,-50,-50,-40,-40,-30,
	-30,-40,-40,-50,-50,-40,-40,-30,
	-30,-40,-40,-50,-50,-40,-40,-30,
	-30,-40,-40,-50,-50,-40,-40,-30,
	-20,-30,-30,-40,-40,-30,-30,-20,
	-10,-20,-20,-20,-20,-20,-20,-10,
	 20, 20,  0,  0,  0,  0, 20, 20,
	 20, 30, 10,  0,  0, 10, 30, 20,
]

func get_pst_value(piece_type, color, board_pos: Vector2) -> int:
	# Mirror row for Black (Black's row 0 is at the top, same as White's row 0 in PST)
	var col = int(board_pos.x)
	var row = int(board_pos.y) if color == Globals.COLORS.WHITE else 7 - int(board_pos.y)
	var idx = row * 8 + col
	match piece_type:
		Globals.PIECE_TYPES.PAWN:   return PST_PAWN[idx]
		Globals.PIECE_TYPES.KNIGHT: return PST_KNIGHT[idx]
		Globals.PIECE_TYPES.BISHOP: return PST_BISHOP[idx]
		Globals.PIECE_TYPES.ROOK:   return PST_ROOK[idx]
		Globals.PIECE_TYPES.QUEEN:  return PST_QUEEN[idx]
		Globals.PIECE_TYPES.KING:   return PST_KING[idx]
	return 0

# --- Game States ---
var game_over;
var player_color;
var status; # who is playing
var player2_type; # Where AI or Human is playing

# AI threading
var ai_thread: Thread = null
var ai_thinking: bool = false

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
	if game_over or ai_thinking:
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


# ---------------------------------------------------------------------------
# Lightweight board representation for search (no scene nodes)
# Each piece is a dict: { type, color, pos: Vector2, moved }
# ---------------------------------------------------------------------------

func board_to_data(b) -> Array:
	var data = []
	for p in b.pieces:
		data.append({ "type": p.piece_type, "color": p.color, "pos": p.board_position, "moved": p.moved })
	return data

func data_get_piece(data: Array, pos: Vector2):
	for p in data:
		if p.pos == pos:
			return p
	return null

func data_get_king_pos(data: Array, color) -> Vector2:
	for p in data:
		if p.type == Globals.PIECE_TYPES.KING and p.color == color:
			return p.pos
	return Vector2(-1, -1)

func data_apply_move(data: Array, from_pos: Vector2, to_pos: Vector2) -> Array:
	# Returns a new array with the move applied (no mutation)
	var next = []
	for p in data:
		if p.pos == to_pos:
			continue  # captured piece removed
		var entry = p.duplicate()
		if entry.pos == from_pos:
			entry.pos = to_pos
			entry.moved = true
			# pawn promotion
			if entry.type == Globals.PIECE_TYPES.PAWN:
				if (entry.color == Globals.COLORS.BLACK and to_pos.y == 7) or \
				   (entry.color == Globals.COLORS.WHITE and to_pos.y == 0):
					entry.type = Globals.PIECE_TYPES.QUEEN
		next.append(entry)
	return next

func data_get_pseudo_moves(data: Array, piece: Dictionary) -> Array:
	# Generate pseudo-legal moves for a piece using the lightweight board
	var moves = []
	var t = piece.type
	var c = piece.color
	var x = int(piece.pos.x)
	var y = int(piece.pos.y)

	match t:
		Globals.PIECE_TYPES.ROOK:
			for inc in [[0,1],[0,-1],[1,0],[-1,0]]:
				moves += _beam(data, c, x, y, inc[0], inc[1])
		Globals.PIECE_TYPES.BISHOP:
			for inc in [[1,1],[1,-1],[-1,1],[-1,-1]]:
				moves += _beam(data, c, x, y, inc[0], inc[1])
		Globals.PIECE_TYPES.QUEEN:
			for inc in [[1,1],[1,-1],[-1,1],[-1,-1],[0,1],[0,-1],[1,0],[-1,0]]:
				moves += _beam(data, c, x, y, inc[0], inc[1])
		Globals.PIECE_TYPES.KNIGHT:
			for inc in [[2,1],[2,-1],[-2,1],[-2,-1],[1,2],[1,-2],[-1,2],[-1,-2]]:
				var nx = x + inc[0]; var ny = y + inc[1]
				if nx >= 0 and nx < 8 and ny >= 0 and ny < 8:
					var occ = data_get_piece(data, Vector2(nx, ny))
					if occ == null or occ.color != c:
						moves.append(Vector2(nx, ny))
		Globals.PIECE_TYPES.KING:
			for inc in [[1,-1],[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1],[0,-1]]:
				var nx = x + inc[0]; var ny = y + inc[1]
				if nx >= 0 and nx < 8 and ny >= 0 and ny < 8:
					var occ = data_get_piece(data, Vector2(nx, ny))
					if occ == null or occ.color != c:
						moves.append(Vector2(nx, ny))
		Globals.PIECE_TYPES.PAWN:
			var dir = 1 if c == Globals.COLORS.BLACK else -1
			# forward
			var fy = y + dir
			if fy >= 0 and fy < 8 and data_get_piece(data, Vector2(x, fy)) == null:
				moves.append(Vector2(x, fy))
				# double push
				if not piece.moved:
					var fy2 = y + dir * 2
					if fy2 >= 0 and fy2 < 8 and data_get_piece(data, Vector2(x, fy2)) == null:
						moves.append(Vector2(x, fy2))
			# captures
			for dx in [-1, 1]:
				var cx2 = x + dx; var cy2 = y + dir
				if cx2 >= 0 and cx2 < 8 and cy2 >= 0 and cy2 < 8:
					var occ = data_get_piece(data, Vector2(cx2, cy2))
					if occ != null and occ.color != c:
						moves.append(Vector2(cx2, cy2))
	return moves

func _beam(data: Array, color, x: int, y: int, dx: int, dy: int) -> Array:
	var result = []
	var cx = x + dx; var cy = y + dy
	while cx >= 0 and cx < 8 and cy >= 0 and cy < 8:
		var occ = data_get_piece(data, Vector2(cx, cy))
		if occ != null:
			if occ.color != color:
				result.append(Vector2(cx, cy))
			break
		result.append(Vector2(cx, cy))
		cx += dx; cy += dy
	return result

func data_in_check(data: Array, color) -> bool:
	var king_pos = data_get_king_pos(data, color)
	if king_pos == Vector2(-1, -1):
		return true
	var opp = Globals.COLORS.WHITE if color == Globals.COLORS.BLACK else Globals.COLORS.BLACK
	for p in data:
		if p.color == opp:
			if king_pos in data_get_pseudo_moves(data, p):
				return true
	return false

func data_get_legal_moves(data: Array, color) -> Array:
	var legal = []
	for p in data:
		if p.color != color:
			continue
		for to_pos in data_get_pseudo_moves(data, p):
			var next = data_apply_move(data, p.pos, to_pos)
			if not data_in_check(next, color):
				legal.append([p.pos, to_pos])
	return legal

func data_order_moves(moves: Array, data: Array) -> Array:
	var captures = []
	var quiet = []
	for m in moves:
		if data_get_piece(data, m[1]) != null:
			captures.append(m)
		else:
			quiet.append(m)
	return captures + quiet

func data_evaluate(data: Array) -> int:
	var score = 0
	for p in data:
		var v = PIECE_VALUES[p.type] + get_pst_value(p.type, p.color, p.pos)
		score += v if p.color == Globals.COLORS.BLACK else -v
	return score

func minimax(data: Array, depth: int, alpha: int, beta: int, is_maximizing: bool) -> int:
	if depth == 0:
		return data_evaluate(data)

	var color = Globals.COLORS.BLACK if is_maximizing else Globals.COLORS.WHITE
	var moves = data_get_legal_moves(data, color)
	moves = data_order_moves(moves, data)

	if moves.is_empty():
		return -99000 if is_maximizing else 99000

	if is_maximizing:
		var best = -999999
		for m in moves:
			var next = data_apply_move(data, m[0], m[1])
			var score = minimax(next, depth - 1, alpha, beta, false)
			if score > best:
				best = score
			if best > alpha:
				alpha = best
			if beta <= alpha:
				break
		return best
	else:
		var best = 999999
		for m in moves:
			var next = data_apply_move(data, m[0], m[1])
			var score = minimax(next, depth - 1, alpha, beta, true)
			if score < best:
				best = score
			if best < beta:
				beta = best
			if beta <= alpha:
				break
		return best

func player2_move():
	var all_moves = get_valid_moves()
	if all_moves.is_empty():
		set_win(Globals.PLAYER.ONE)
		return

	ai_thinking = true
	var data_snapshot = board_to_data(board)

	ai_thread = Thread.new()
	ai_thread.start(_ai_search.bind(data_snapshot))

func _ai_search(data_snapshot: Array):
	var moves = data_get_legal_moves(data_snapshot, Globals.COLORS.BLACK)
	moves = data_order_moves(moves, data_snapshot)

	var best_score = -999999
	var best_from = null
	var best_to   = null

	for m in moves:
		var next = data_apply_move(data_snapshot, m[0], m[1])
		var score = minimax(next, ai_depth - 1, -999999, 999999, false)
		if score > best_score:
			best_score = score
			best_from  = m[0]
			best_to    = m[1]

	call_deferred("_apply_ai_move", best_from, best_to)

func _apply_ai_move(from_pos, to_pos):
	ai_thread.wait_to_finish()
	ai_thread = null
	ai_thinking = false

	if from_pos == null:
		return

	var piece = board.get_piece(from_pos)
	if piece == null:
		return
	move_piece(piece, to_pos)

func evaluate_board(board_state) -> int:
	# Thin wrapper kept for compatibility — delegates to data evaluator
	return data_evaluate(board_to_data(board_state))

func order_moves(moves: Array, board_state) -> Array:
	return data_order_moves(
		moves.map(func(m): return [m[0].board_position, m[1]]),
		board_to_data(board_state)
	)

func move_piece(piece, pos):
	var dest_piece = board.get_piece(pos)
	if dest_piece != null and dest_piece.color != piece.color:
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
