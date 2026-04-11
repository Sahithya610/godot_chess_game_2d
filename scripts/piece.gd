extends Node2D

@onready var spirte = $Sprite2D

const SPRITE_SIZE = 16
const CELL_SIZE = 60

const X_OFFSET = 30
const Y_OFFSET = 30

@export var piece_type: Globals.PIECE_TYPES
@export var color: Globals.COLORS
@export var board_position: Vector2

var board_handle;

@export var moved: bool;

func init_piece(
	type: Globals.PIECE_TYPES,
	col: Globals.COLORS,
	board_pos: Vector2,
	board
):
	piece_type = type
	color = col
	board_position = board_pos
	board_handle = board
	moved = false
	
	update_sprite()
	
	position = Vector2(
		X_OFFSET + board_position[0] * CELL_SIZE,
		Y_OFFSET + board_position[1] * CELL_SIZE,
	)
	
func update_sprite():
	if spirte:
		var region_pos = Globals.SPRITE_MAPPING[color][piece_type]
		spirte.region_rect = Rect2(
			region_pos.y * SPRITE_SIZE,
			region_pos.x * SPRITE_SIZE,
			SPRITE_SIZE,
			SPRITE_SIZE
		)

func move_position(to_move: Vector2):
	moved = true
	board_position = to_move
	position = Vector2(
		X_OFFSET + board_position[0] * CELL_SIZE,
		Y_OFFSET + board_position[1] * CELL_SIZE,
	)
	# Update king position if they are moved
	if piece_type == Globals.PIECE_TYPES.KING:
		board_handle.register_king(board_position, color)
	
	# Promotion for pawns to queen
	if piece_type == Globals.PIECE_TYPES.PAWN and (
		(color == Globals.COLORS.BLACK and to_move[1] == 7) or 
		(color == Globals.COLORS.WHITE and to_move[1] == 0)
	):
		piece_type = Globals.PIECE_TYPES.QUEEN
		update_sprite()

func clone(_board):
	var piece = self.duplicate()
	piece.board_handle = _board
	return piece
	
func get_moveable_positions():
	match piece_type:
		Globals.PIECE_TYPES.PAWN: return pawn_threat_pos()
		Globals.PIECE_TYPES.BISHOP: return bishop_threat_pos()
		Globals.PIECE_TYPES.ROOK: return rook_threat_pos()
		Globals.PIECE_TYPES.KNIGHT: return knight_threat_pos()
		Globals.PIECE_TYPES.QUEEN: return queen_threat_pos()
		Globals.PIECE_TYPES.KING: return king_threat_pos()
		_: return []

func get_threatened_positions():
	match piece_type:
		Globals.PIECE_TYPES.PAWN: return pawn_move_pos()
		Globals.PIECE_TYPES.BISHOP: return bishop_threat_pos()
		Globals.PIECE_TYPES.ROOK: return rook_threat_pos()
		Globals.PIECE_TYPES.KNIGHT: return knight_threat_pos()
		Globals.PIECE_TYPES.QUEEN: return queen_threat_pos()
		Globals.PIECE_TYPES.KING: return king_threat_pos()
		_: return []


# Pawn Moves
const PAWN_SPOT_INCREMENTS_MOVE = [[0, 1]] # Pawn move only one
const PAWN_SPOT_INCREMENTS_MOVE_FIRST = [[0, 1], [0, 2]]  # Pawn can move one and two times initially
const PAWN_SPOT_INCREMENTS_TAKE = [[-1, 1], [1, 1]] # Pawn taking other peice at side

func pawn_threat_pos():
	var positions = []
	
	for inc in PAWN_SPOT_INCREMENTS_TAKE:
		var pos = board_handle.spot_search_threat(
			color,
			board_position[0], board_position[1],
			inc[0], inc[1] if color == Globals.COLORS.BLACK else -inc[1],
			true, false
		)
		if pos != null:
			positions.append(pos)
	return positions

func pawn_move_pos():
	var positions = []
	
	var increments = PAWN_SPOT_INCREMENTS_MOVE if moved else PAWN_SPOT_INCREMENTS_MOVE_FIRST
	for inc in increments:
		var pos = board_handle.spot_search_threat(
			color,
			board_position[0], board_position[1],
			inc[0], inc[1] if color == Globals.COLORS.BLACK else -inc[1],
			false, true
		)
		if pos != null:
			positions.append(pos)
		else:
			# if there is something blocking in 1st pos
			# then second pos can't be moved
			break
		
	for inc in PAWN_SPOT_INCREMENTS_TAKE:
		var pos = board_handle.spot_search_threat(
			color,
			board_position[0], board_position[1],
			inc[0], inc[1] if color == Globals.COLORS.BLACK else -inc[1],
			true, false
		)
		if pos != null:
			positions.append(pos)
	return positions

# Bishop Moves
const BISHOP_BEAM_INCREMENTS = [[1, 1], [1, -1], [-1, 1], [-1, -1]]
func bishop_threat_pos():
	var positions = []
	for inc in BISHOP_BEAM_INCREMENTS:
		positions += board_handle.beam_search_threat(
			color,
			board_position[0], board_position[1],
			inc[0], inc[1]
		)
	return positions

# Rook Moves
const ROOK_BEAM_INCREMENTS = [[0, 1], [0, -1], [1, 0], [-1, 0]]
func rook_threat_pos():
	var positions = []
	for inc in ROOK_BEAM_INCREMENTS:
		positions += board_handle.beam_search_threat(
			color,
			board_position[0], board_position[1],
			inc[0], inc[1]
		)
	return positions

# Knight Moves
const KNIGHT_SPOT_INCREMENTS =[[2, 1], [2, -1], [-2, 1], [-2, -1], [1, 2], [1, -2], [-1, 2], [-1, -2]];
func knight_threat_pos():
	var positions = []
	for inc in KNIGHT_SPOT_INCREMENTS:
		var pos = board_handle.spot_search_threat(
			color,
			board_position[0], board_position[1],
			inc[0], inc[1]
		)
		if pos != null:
			positions.append(pos)
	return positions

# Queen Moves
const QUEEN_BEAM_INCREMENTS = [[1, 1], [1, -1], [-1, 1], [-1, -1], [0, 1], [0, -1], [1, 0], [-1, 0]];
func queen_threat_pos():
	var positions = []
	for inc in QUEEN_BEAM_INCREMENTS:
		positions += board_handle.beam_search_threat(
			color,
			board_position[0], board_position[1],
			inc[0], inc[1]
		)
	return positions

# King Moves
const KING_SPOT_INCREMENTS = [[1, -1], [1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0], [-1, -1], [0, -1]];
func king_threat_pos():
	var positions = []
	for inc in KING_SPOT_INCREMENTS:
		var pos = board_handle.spot_search_threat(
			color,
			board_position[0], board_position[1],
			inc[0], inc[1]
		)
		if pos != null:
			positions.append(pos)
	return positions
