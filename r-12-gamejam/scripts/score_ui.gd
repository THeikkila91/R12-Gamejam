extends CanvasLayer

@onready var score_label = $ScoreLabel
@onready var lines_label = $LinesLabel
@onready var level_label = $LevelLabel

var total_score = 0
var total_lines = 0
var current_level = 1

var highscores: Array = [0, 0, 0, 0, 0]
const SAVE_PATH = "user://highscores.save"


func _ready():
	load_highscores()
	update_ui()
	update_highscore_display()

func load_highscores():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		highscores = file.get_var()
	else:
		highscores = [0, 0, 0, 0, 0]

func save_highscores():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(highscores)

func check_for_new_highscore():
	highscores.append(total_score)
	highscores.sort() # Järjestää pienimmästä isoimpaan
	highscores.reverse()
	highscores = highscores.slice(0, 5) # Pidä vain top 5
	
	save_highscores()
	update_highscore_display()

func update_highscore_display():
	
	var pause_container = get_node("../UI/PauseMenu/VBoxContainer/HighscorePanel/MarginContainer/HighscoreContainer")
	var gameover_container = get_node("../UI/GameOverMenu/VBoxContainer/HighscorePanel/MarginContainer/GameOverHighscoreContainer")
	
	var containers = [pause_container, gameover_container]
	
	for container in containers:
		if container:
			print("Highscore container found!")
			var children = container.get_children()
		
			for i in range(1, children.size()):
				var score_index = i - 1
			
				if children[i] is Label and score_index < highscores.size():
					children[i].text = str(highscores[score_index])
		else:
			print("Error: Could not find HighscoreContainer!")

# Tätä funktiota kutsutaan kun signaali on saatu
func _on_lines_cleared(points: int, line_count: int):
	total_score += points
	total_lines += line_count
	update_ui()

func update_ui():
	score_label.text = "Score: \n" + str(total_score)
	lines_label.text = "Lines: \n" + str(total_lines)
	level_label.text = "Level: \n" + str(current_level)

func _on_points_earned(points: int):
	total_score += points
	update_ui()

func _on_level_changed(new_level: int):
	current_level = new_level
	update_ui()
