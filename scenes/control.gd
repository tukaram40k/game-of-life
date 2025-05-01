extends Control

func _ready() -> void:
	# рефы к кнопкам
	var button1 = $Panel/TextureButton1
	var button2 = $Panel/TextureButton2
	var button3 = $Panel/TextureButton3
	
	var clear_button = $Panel3/ClearButton
	var reset_button = $Panel4/ResetButton
	
	# реф к main.gd
	var root = get_tree().get_root().get_child(0)
	
	# селектор клеток
	# сразу затемнить дефолт
	button1.modulate = Color(0.5, 0.5, 0.5)
	
	button1.pressed.connect(root._on_cell1_button_pressed)
	button1.pressed.connect(_on_button1_pressed)
	
	button2.pressed.connect(root._on_cell2_button_pressed)
	button2.pressed.connect(_on_button2_pressed)
	
	button3.pressed.connect(root._on_cell3_button_pressed)
	button3.pressed.connect(_on_button3_pressed)
	
	# кнопки clear и reset
	clear_button.pressed.connect(root._on_clear_button_pressed)
	reset_button.pressed.connect(root._on_reset_button_pressed)

# затемнение для активной кнопки
func _on_button1_pressed():
	$Panel/TextureButton1.modulate = Color(0.5, 0.5, 0.5)
	$Panel/TextureButton2.modulate = Color(1, 1, 1)
	$Panel/TextureButton3.modulate = Color(1, 1, 1)
	
func _on_button2_pressed():
	$Panel/TextureButton2.modulate = Color(0.5, 0.5, 0.5)
	$Panel/TextureButton1.modulate = Color(1, 1, 1)
	$Panel/TextureButton3.modulate = Color(1, 1, 1)

func _on_button3_pressed():
	$Panel/TextureButton3.modulate = Color(0.5, 0.5, 0.5)
	$Panel/TextureButton1.modulate = Color(1, 1, 1)
	$Panel/TextureButton2.modulate = Color(1, 1, 1)

# назад в главное меню
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")
