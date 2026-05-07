extends TileMapLayer

@onready var score_popup = $"../ScoreUI/ScorePopUp"
var points_tween: Tween
@onready var pohja_layer = $"../Pohja" 
@onready var next_display = $"../UI/NextPieceDisplay"
@onready var game_over_menu = $"../UI/GameOverMenu"
@onready var hold_display = $"../UI/HoldPieceDisplay"
@onready var pause_menu = $"../UI/PauseMenu"

signal lines_cleared(points: int, line_count: int)
signal points_earned(points: int)
signal level_changed(new_level: int)

var level: int = 1
var total_lines_cleared: int = 0
var fall_timer: Timer
var held_piece_data = null
var can_swap: bool = true
var lock_delay_timer: float = 0.0
var lock_delay_max: float = 0.5
var is_touching_ground: bool = false

var current_pos: Vector2i
var current_shape: Array
var current_color_index: int
var next_pieces_queue: Array = []
var current_bag: Array = [] 

var move_delay = 0.15
var move_interval = 0.05
var time_since_move = 0.0
var move_held_time = 0.0
var move_down_timer = 0.0


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
	for i in range(3):
		add_random_piece_to_queue()
	fall_timer = Timer.new()
	add_child(fall_timer)
	fall_timer.wait_time = 0.5
	fall_timer.timeout.connect(move_down)
	fall_timer.start() 
	spawn_piece()

func _input(event):
	if event.is_action_pressed("rotation"):
		rotate_piece()
	# Insta pudotus
	elif event.is_action_pressed("hard_drop"):
		hard_drop()
	# Palikan vaihto
	elif event.is_action_pressed("swap_piece"):
		swap_piece()

func hard_drop():
	while can_move(current_pos + Vector2i(0, 1)):
		current_pos += Vector2i(0, 1)
		# Antaa 2 pistettä per solu
		points_earned.emit(2)
		
	lock_piece()

func rotate_piece():
	var new_shape = []
	for cell in current_shape:
		# Rotaatio: (x, y) -> (-y, x)
		var rotated_cell = Vector2i(-cell.y, cell.x)
		new_shape.append(rotated_cell)
	# Chekkaa seinien collision
	if can_move_with_shape(current_pos, new_shape):
		current_shape = new_shape
		if is_touching_ground:
			lock_delay_timer = 0.0
		draw_active_piece()
		get_parent().get_node("RotateSound").play()
		
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		pause_game()
	time_since_move += delta
	if Input.is_action_pressed("move_down"):
		#tämä saa palikan tippumaan vauhdilla
		move_down_timer += delta * 9
		if move_down_timer > fall_timer.wait_time:
			move_down(true)
			move_down_timer = 0
	var move_dir = 0
	if Input.is_action_pressed("move_left"):
		move_dir = -1
	elif Input.is_action_pressed("move_right"):
		move_dir = 1
	
	if move_dir != 0:
		move_held_time += delta
		if move_held_time == delta or (move_held_time > move_delay and time_since_move > move_interval):
			move_horizontal(move_dir)
			time_since_move = 0.0
	else:
		move_held_time = 0.0
		time_since_move = 0.0
	
	# LUKITUKSEN VIIVELOGIIKKA
	if is_touching_ground:
		lock_delay_timer += delta
		if lock_delay_timer >= lock_delay_max:
			lock_piece()
			is_touching_ground = false
			lock_delay_timer = 0.0
	
	if is_touching_ground and can_move(current_pos + Vector2i(0, 1)):
		is_touching_ground = false
		lock_delay_timer = 0.0

func pause_game():
	# Näytetään pause-valikko (Varmista että polku on oikea!)
	# Jos PauseMenu on UI-noden alla: $"../UI/PauseMenu".show()
	var pause_menu = get_tree().root.find_child("PauseMenu", true, false)
	if pause_menu:
		pause_menu.show()
		get_tree().paused = true

func _on_continue_button_pressed():
	# Tämä funktio kytketään Continue-napin 'pressed'-signaaliin
	var pause_menu = get_tree().root.find_child("PauseMenu", true, false)
	if pause_menu:
		pause_menu.hide()
	get_tree().paused = false

func can_move_with_shape(target_pos: Vector2i, shape_to_test: Array) -> bool:
	for cell in shape_to_test:
		var map_pos = target_pos + cell
		if map_pos.x < 0 or map_pos.x >= 10 or map_pos.y >= 20:
			return false
		if pohja_layer.get_cell_source_id(map_pos) != -1:
			return false
	return true


func spawn_piece():
	current_pos = Vector2i(5, 1)
	var next_data = next_pieces_queue.pop_front()
	current_shape = shapes[next_data["type"]]
	current_color_index = next_data["color"]
	if not can_move(current_pos):
		game_over()
		return
	add_random_piece_to_queue()
	draw_next_pieces_display()
	draw_active_piece()

func swap_piece():
	if not can_swap:
		return
	
	clear()
	
	var old_current_data = {"type": get_current_type_name(), "color": current_color_index}
	
	if held_piece_data == null: # Ensimmäinen vaihto hold laatikkoon ja luo uuden palikan
		held_piece_data = old_current_data
		spawn_piece()
	else:
		# Seuraavat vaihdot: vaihtaa nykyisen ja hold laatikossa olevan
		var temp = held_piece_data
		held_piece_data = old_current_data
		# Vaihtaa hold laatikosta nykyiseen
		current_pos = Vector2i(5, 1)
		current_shape = shapes[temp["type"]]
		current_color_index = temp["color"]
		draw_active_piece()
	
	can_swap = false # Lukitse vaihtaminen kunnes seuraava palikka on maassa (lukittu)
	draw_hold_display()

func get_current_type_name() -> String:
	for key in shapes.keys():
		if shapes[key] == current_shape:
			return key
	return "I"

func draw_hold_display():
	if hold_display and held_piece_data:
		hold_display.clear()
		var shape_data = shapes[held_piece_data["type"]]
		var color_idx = held_piece_data["color"]
		for cell in shape_data:
			hold_display.set_cell(Vector2i(2, 2) + cell, 0, Vector2i(color_idx, 0))

func game_over():
	print("Peli loppui!")
	#soitetaan ääni
	get_parent().get_node("GameoverSound").play()
	#pysäytetään ajastin
	if get_parent().has_method("stop_timer"):
		get_parent().stop_timer()
	else:
		get_parent().is_running = false
	#palikoiden pysäytys
	set_process(false) 
	fall_timer.stop() 
	#gameover ruutu näkyviin 
	if game_over_menu:
		game_over_menu.show()
	
#nappulat
func _on_retry_button_pressed():
	#ottaa paussin pois
	get_tree().paused = false
	get_parent().get_node("ButtonpressSound").play()
	await get_tree().create_timer(0.1).timeout
	get_tree().reload_current_scene()
func _on_quit_button_pressed():
	get_parent().get_node("ButtonpressSound").play()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()
	
func _on_retry_button_mouse_entered():
	get_parent().get_node("HoverSound").play()

func _on_quit_button_mouse_entered():
	get_parent().get_node("HoverSound").play()

func draw_active_piece():
	clear()
	
	# 1. Laske haamu palikan paikka (ennakoiva outline)
	var ghost_pos = current_pos
	while can_move(ghost_pos + Vector2i(0, 1)):
		ghost_pos += Vector2i(0, 1)
		
	# 2. Piirrä haamu piece
	for cell in current_shape:
		set_cell(ghost_pos + cell, 1, Vector2i(current_color_index, 0))
	
	# 3. Piirrä oikea "Active Piece"
	for cell in current_shape:
		#käytetään arvottua väri-indeksiä poimimaan oikea ruutu tilesetistä
		set_cell(current_pos + cell, 0, Vector2i(current_color_index, 0))


func move_horizontal(dir: int):
	var next_pos = current_pos + Vector2i(dir, 0)
	if can_move(next_pos):
		current_pos = next_pos
		if is_touching_ground:
			lock_delay_timer = 0.0
		draw_active_piece()

func move_down(is_manual: bool = false):
	var next_pos = current_pos + Vector2i(0, 1)
	if can_move(next_pos):
		current_pos = next_pos
		draw_active_piece()
		is_touching_ground = false
		lock_delay_timer = 0.0 
		
		# Jos pelaaja painaa alas, anna 1 piste
		if is_manual:
			points_earned.emit(1)
	else:
		is_touching_ground = true

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
	get_parent().get_node("DropSound").play()
	check_full_rows()
	can_swap = true # Mahdollistaa vaihdon seuraavalle palikalle 
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
			get_parent().get_node("ExplodeSound").play()
			delete_row_and_shift(y) #tässä tuhotaan ja pudotetaan
			rows_cleared += 1
		else:
			y -= 1
	
	if rows_cleared > 0:
		calculate_score(rows_cleared)

func delete_row_and_shift(row_to_clear: int):
	#poisto
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
	total_lines_cleared += amount
	
	var points = 0
	if amount == 1: points = 100
	elif amount == 2: points = 300
	elif amount == 3: points = 500
	elif amount == 4: points = 800
	
	var earned_points = points * level
	lines_cleared.emit(earned_points, amount)
	
	print("You got ", points, " points!")
	show_points_popup(earned_points)
	
	if total_lines_cleared >= level * 5:
		level_up()
	
func level_up():
	level += 1
	
	get_parent().get_node("LevelupSound").play()
	# Laske uusi nopeus 
	# Esimerkki: laske wait_time 10% joka taso, mutta älä mene alle 0.1s
	var new_speed = 0.5 * pow(0.6, level - 1)
	fall_timer.wait_time = max(0.0, new_speed)
	
	level_changed.emit(level)
	print("Level Up! Current Level: ", level, " Speed: ", fall_timer.wait_time)
	
	
func add_random_piece_to_queue():
	#pussi on tyhjä, sekoitetaan se
	if current_bag.is_empty():
		#lisätään muotojen nimet pussiin
		current_bag = shapes.keys() 
		current_bag.shuffle() #sekoitetaan pussukka
	#nostetaan pussista muoto
	var random_key = current_bag.pop_back()
	#lisätään se jonoon
	next_pieces_queue.append({"type": random_key, "color": randi() % 8})

func draw_next_pieces_display():
	next_display.clear()
	var offset_y = 0
	for piece in next_pieces_queue:
		var shape_data = shapes[piece["type"]]
		var color_idx = piece["color"]
		for cell in shape_data:
			var draw_pos = Vector2i(2, 2 + offset_y) + cell
			next_display.set_cell(draw_pos, 0, Vector2i(color_idx, 0))
		offset_y += 4
		
func show_points_popup(value: int):
	if score_popup:
		score_popup.text = "+" + str(value)
		score_popup.visible = true
		score_popup.modulate.a = 1.0 
		
		if points_tween:
			points_tween.kill()
			
		points_tween = create_tween()
		
		points_tween.set_parallel(true)
		points_tween.tween_property(score_popup, "modulate:a", 0.0, 1.5)
		
		points_tween.set_parallel(false)
		score_popup.scale = Vector2(0.5, 0.5)
		points_tween.tween_property(score_popup, "scale", Vector2(1.2, 1.2), 0.2)
		
		points_tween.tween_callback(func(): score_popup.visible = false)
