extends Node2D
var total_time = 0.0
@onready var time_label = $UI/Timer

func _process(delta):
	total_time += delta
	update_timer_display()

func update_timer_display():
	var mils = fmod(total_time, 1.0) * 100
	var secs = fmod(total_time, 60)
	var mins = fmod(total_time, 3600) / 60
	
	var time_string = "%02d : %02d : %02d" % [mins, secs, mils]
	time_label.text = "TIME\n" + time_string
