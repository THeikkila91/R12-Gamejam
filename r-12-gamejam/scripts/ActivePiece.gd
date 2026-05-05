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
	elif event.is_action_pressed("rotation"): # Palikan rotaatio/kierto
		rotate_piece()

func rotate_piece():
	var new_shape = []
	for cell in current_shape:
		# Rotaatio: (x, y) -> (-y, x)
		var rotated_cell = Vector2i(-cell.y, cell.x)
		new_shape.append(rotated_cell)
	
	# Chekkaa seinien collision
	if can_move_with_shape(current_pos, new_shape):
		current_shape = new_shape
		draw_active_piece()

func can_move_with_shape(target_pos: Vector2i, shape_to_test: Array) -> bool:
	for cell in shape_to_test:
		var map_pos = target_pos + cell
		if map_pos.x < 0 or map_pos.x >= 10 or map_pos.y >= 20:
			return false
		if pohja_layer.get_cell_source_id(map_pos) != -1:
			return false
	return true


func spawn_piece():
	current_pos = Vector2i(5, 0)
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
	check_full_rows() 
	spawn_piece()

func check_full_rows():
	var rows_cleared = 0
	var y = 19
	while y >= 0:
		var is_full = true
		for x in range(10):
			if pohja_layer.get_cell_source_id(Vector2i(x, y)) == -1:
				is_full = false
				break
		
		if is_full:
			delete_row_and_shift(y) #tässä tuhotaan ja pudotetaan
			rows_cleared += 1
		else:
			y -= 1
	
	if rows_cleared > 0:
		calculate_score(rows_cleared)

func delete_row_and_shift(row_to_clear: int):
	# Poisto
	for x in range(10):
		pohja_layer.set_cell(Vector2i(x, row_to_clear), -1)
	
	#pudotus ylhäältä alas
	for y in range(row_to_clear, 0, -1):
		for x in range(10):
			var source_id = pohja_layer.get_cell_source_id(Vector2i(x, y - 1))
			var atlas_coords = pohja_layer.get_cell_atlas_coords(Vector2i(x, y - 1))
			pohja_layer.set_cell(Vector2i(x, y), source_id, atlas_coords)
			pohja_layer.set_cell(Vector2i(x, y - 1), -1)

func calculate_score(amount: int):
	var points = 0
	if amount == 1: points = 100
	elif amount == 2: points = 300
	elif amount == 3: points = 500
	elif amount == 4: points = 800
	
	print("Sait ", points, " pistettä! (", amount, " riviä)")
