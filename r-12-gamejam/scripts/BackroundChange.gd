extends VideoStreamPlayer
@onready var level_announcer = get_node("/root/Game/ScoreUI").find_child("level_announcer", true, false)
var active_pulse: Tween
var main_vid = preload("res://assets/video2.ogv")
@onready var lines_node = $"../ActivePiece"

var current_level = 1

func _ready():
	stream = main_vid
	play()
	loop = true 

func _process(_delta):
	if lines_node:
		var lines = lines_node.total_lines_cleared
		# Eri levelien muutokset taustaan
		if lines >= 20 and current_level < 5:
			apply_level_effects(5, 4, 0.8, Color(1, 0, 0))
			show_level_announcement(5)
		elif lines >= 15 and current_level < 4:
			apply_level_effects(4, 3, 0.6, Color(1, 0.5, 0))
			show_level_announcement(4)
		elif lines >= 10 and current_level < 3:
			apply_level_effects(3, 2, 0.4, Color(0.6, 0, 1))
			show_level_announcement(3)
		elif lines >= 5 and current_level < 2:
			apply_level_effects(2, 1, 0.2, Color(0, 0.8, 1))
			show_level_announcement(2)

func apply_level_effects(new_level: int, speed: float, darkness: float, tint: Color):
	current_level = new_level
	
	var dark_tween = create_tween()
	dark_tween.tween_property(get_node("../SkyDimmer"), "color:a", darkness, 2.0)
	
	var tint_tween = create_tween()
	tint_tween.tween_property(self, "modulate", tint, 3.0)

	if active_pulse:
		active_pulse.kill()
	
	var pulse_time = 1.0
	if new_level == 3: pulse_time = 0.8
	if new_level == 4: pulse_time = 0.6
	if new_level == 5: pulse_time = 0.4
	
	active_pulse = create_tween().set_loops()
	active_pulse.tween_property(self, "modulate", tint * 1.5, pulse_time)
	active_pulse.tween_property(self, "modulate", tint, pulse_time)

func show_level_announcement(new_level: int):
	if level_announcer:
		level_announcer.text = "LEVEL " + str(new_level)
		level_announcer.visible = true
		level_announcer.modulate.a = 0.0
		level_announcer.scale = Vector2(0.5, 0.5)
		level_announcer.pivot_offset = level_announcer.size / 2
		
		var lt = create_tween()
		# Appear and "Pop"
		lt.set_parallel(true)
		lt.tween_property(level_announcer, "modulate:a", 1.0, 0.4)
		lt.tween_property(level_announcer, "scale", Vector2(1.3, 1.3), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		# Wait
		lt.set_parallel(false)
		lt.tween_interval(1.5)
		
		# Disappear
		lt.tween_property(level_announcer, "modulate:a", 0.0, 0.5)
		lt.tween_callback(func(): level_announcer.visible = false)
