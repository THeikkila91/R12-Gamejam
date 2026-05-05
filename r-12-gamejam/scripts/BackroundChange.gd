extends VideoStreamPlayer

# esilataa videot
var level1_vid = preload("res://assets/vecteezy_cloudy-sky-animation-animated-clouds-timelapse-in-blue-sky_1956763211.ogv")
var level2_vid = preload("res://assets/backround_video3.ogv")
var level3_vid = preload("res://assets/backround_video3.ogv")

@onready var sky_dimmer = $"../SkyDimmer"
@onready var scorer_node = $"../ScoreUI" # tällä haetaan total score

var current_level = 1

func _ready():
	stream = level1_vid
	play()

func _process(_delta):
	var total_score = scorer_node.total_score
	
	# määritetään level scoren mukaan
	if total_score >= 3000 and current_level < 3:
		change_to_level(3)
	elif total_score >= 1500 and current_level < 2:
		change_to_level(2)

func change_to_level(new_level: int):
	current_level = new_level
	
	match new_level:
		2:
			update_sky(level2_vid, 0)
		3:
			update_sky(level3_vid, 0)

func update_sky(new_video: VideoStream, target_darkness: float):
	var tween = create_tween()
	# muuttaa peitteen täysin mustaksi puolessa sekunnissa
	tween.tween_property(sky_dimmer, "color:a", 1.0, 0.5)
	
	# kun peite tumma niin video vaihtuu
	tween.tween_callback(func():
		if stream != new_video:
			stream = new_video
			play()
	)

	# tummennus hälvenee
	tween.tween_property(sky_dimmer, "color:a", target_darkness, 1.0)
