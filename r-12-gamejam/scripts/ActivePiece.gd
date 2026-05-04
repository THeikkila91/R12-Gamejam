extends TileMapLayer

# Viittaus passiiviseen Pohja-kerrokseen
@onready var pohja_layer = $"../Pohja" 

var current_pos: Vector2i
var current_shape: Array
var current_color_index: int

# 8 PALAN MÄÄRITTELY
var shapes = {
	"I": [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	"O": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	"T": [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)],
	"S": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1)],
	"Z": [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
	"J": [Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)],
	"L": [Vector2i(1, -1), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)],
	"X": [Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0)] # Esimerkki 8. palasta
}

func _ready():
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.5
	timer.timeout.connect(move_down)
	timer.start() 
	spawn_piece()

func _input(event):
	if event.is_action_pressed("move_left"):
		move_horizontal(-1)
	elif event.is_action_pressed("move_right"):
		move_horizontal(1)
	elif event.is_action_pressed("move_down"):
		move_down()

func spawn_piece():
	current_pos = Vector2i(5, 1)
	var keys = shapes.keys()
	
	# Arvotaan yksi kahdeksasta palasta
	current_shape = shapes[keys[randi() % keys.size()]] 
	
	# Arvotaan väri (0-7, eli yhteensä 8 eri vaihtoehtoa)
	current_color_index = randi() % 8 
	
	draw_active_piece()

func draw_active_piece():
	clear()
	for cell in current_shape:
		# Käytetään arvottua väri-indeksiä poimimaan oikea ruutu tilesetistä
		set_cell(current_pos + cell, 0, Vector2i(current_color_index, 0))

func move_horizontal(dir: int):
	var next_pos = current_pos + Vector2i(dir, 0)
	if can_move(next_pos):
		current_pos = next_pos
		draw_active_piece()

func move_down():
	var next_pos = current_pos + Vector2i(0, 1)
	if can_move(next_pos):
		current_pos = next_pos
		draw_active_piece()
	else:
		lock_piece()

func can_move(target_pos: Vector2i) -> bool:
	for cell in current_shape:
		var map_pos = target_pos + cell
		if map_pos.x < 0 or map_pos.x >= 10 or map_pos.y >= 20:
			return false
		if pohja_layer.get_cell_source_id(map_pos) != -1:
			return false
	return true

func lock_piece():
	for cell in current_shape:
		pohja_layer.set_cell(current_pos + cell, 0, Vector2i(current_color_index, 0))
	clear()
	spawn_piece()
