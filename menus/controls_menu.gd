extends Control

# кнопка back в меню controls
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")
