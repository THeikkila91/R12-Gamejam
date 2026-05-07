extends VBoxContainer

func _on_start_game_pressed():
	get_node("../buttonpresssound").play()
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_quit_pressed():
	get_node("../buttonpresssound").play()
	await get_tree().create_timer(0.4).timeout
	get_tree().quit()
	
func _on_start_game_mouse_entered():
	get_node("../hover").play()

func _on_quit_mouse_entered():
	get_node("../hover").play()
