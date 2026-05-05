extends CanvasLayer

@onready var score_label = $ScoreLabel
@onready var lines_label = $LinesLabel

var total_score = 0
var total_lines = 0

func _ready():
	update_ui()

# This function will be called when the signal is received
func _on_lines_cleared(points: int, line_count: int):
	total_score += points
	total_lines += line_count
	update_ui()

func update_ui():
	score_label.text = "Score: \n" + str(total_score)
	lines_label.text = "Lines: \n" + str(total_lines)

func _on_points_earned(points: int):
	total_score += points
	update_ui()
