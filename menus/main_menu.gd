extends Control

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

# потом че-то пихну сюда
func _on_controls_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/controls_menu.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()
