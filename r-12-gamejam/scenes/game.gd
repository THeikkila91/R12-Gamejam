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


func _on_h_slider_value_changed(value: float) -> void:

	# ääni
	if value <= -39:
		$AudioStreamPlayer.volume_db = -80
	else:
		$AudioStreamPlayer.volume_db = value

	# prosentti (ei yli 100%)
	var percent = clamp(int((value + 40) / 40 * 100), 0, 100)

	$Volume.text = "Volume: " + str(percent) + "%"
	
func _ready() -> void:
	$HSlider.value = -20
	_on_h_slider_value_changed(-20)
	
	$HSlider.focus_mode = Control.FOCUS_NONE
