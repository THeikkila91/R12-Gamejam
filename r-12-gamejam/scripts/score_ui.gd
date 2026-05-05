extends CanvasLayer

@onready var score_label = $ScoreLabel
@onready var lines_label = $LinesLabel
@onready var level_label = $LevelLabel

var total_score = 0
var total_lines = 0
var current_level = 1

func _ready():
	update_ui()

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
