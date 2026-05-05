extends VideoStreamPlayer

# esiladataan videot
var level1_vid = preload("res://assets/vecteezy_cloudy-sky-animation-animated-clouds-timelapse-in-blue-sky_1956763211.ogv")
var level2_vid = preload("res://assets/backround_video3.ogv")
var level3_vid = preload("res://assets/backround_video3.ogv")

@onready var sky_dimmer = $"../SkyDimmer"

func _ready():
	get_parent().level_changed.connect(_on_level_changed)
	
	stream = level1_vid
	play()
	sky_dimmer.color.a = 0.0

func _on_level_changed(new_level: int):
	match new_level:
		1: 
			update_sky(level1_vid, 0.0)
		2: 
			update_sky(level2_vid, 0.25)
		3: 
			update_sky(level3_vid, 0.6)

func update_sky(new_video: VideoStream, darkness: float):
	if stream != new_video:
		stream = new_video
		play()
	
	# feidaava himmennys
	var tween = create_tween()
	tween.tween_property(sky_dimmer, "color:a", darkness, 2.0)
