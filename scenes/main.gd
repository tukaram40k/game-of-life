extends Node2D

# сцена с клеткой, она видна в инспекторе
@export var cell_scene_basic : PackedScene

# продолжительность цикла игры
@export var update_interval: float = 0.5

# референс на нод с таймером
@onready var timer: Timer = $Timer

var paused: bool = false

# размер карты и клеток
var row_count : int = 50
var column_count : int = 50
var cell_size: int = 140

# чтобы клетки рисовать
var mouse_dragging := false
var last_edited_cell := Vector2(-1, -1)

# array для клеток
var cell_matrix: Array = []
var previous_cell_states: Array = []

# эта херь запускается 1 раз на старте игры
func _ready():
	get_window().mode = Window.MODE_FULLSCREEN
	
	var rng = RandomNumberGenerator.new()
	
	# пихаем клетки в 2d array
	for column in range(column_count):
		cell_matrix.push_back([])
		previous_cell_states.push_back([])
		
		for row in range(row_count):
			var cell = cell_scene_basic.instantiate()
			self.add_child(cell)
			
			cell.position = Vector2(column * cell_size, row * cell_size)
			
			if rng.randi_range(0,1) or is_edge(column, row):
				cell.visible = false
				previous_cell_states[column].push_back(false)
			else:
				previous_cell_states[column].push_back(true)
			cell_matrix[column].push_back(cell)
	
	# стартует таймер
	timer.wait_time = update_interval
	timer.timeout.connect(update_game_state)
	
	# ВАЖНО: эта херня не дает другим нодам видеть нажатие ESC
	# с этим можно проебаться потом
	process_mode = Node.PROCESS_MODE_ALWAYS

# чекает если позиция это край карты
func is_edge(column, row) -> bool:
	return row == 0 or column == 0 or row == row_count-1 or column == column_count -1

# возвращает количество живых соседей
func get_alive_neighbours(column, row) -> int:
	var count = 0
	for x in range(-1, 2):
		for y in range(-1, 2):
			if not (x == 0 and y == 0):
				if previous_cell_states[column + x][row + y]:
					count += 1
	return count

# возвращает следующий стейт
func get_next_state(column, row) -> bool:
	var current = previous_cell_states[column][row]
	var neighbours_alive = get_alive_neighbours(column, row)
	
	if current == true:
		# если живой
		if neighbours_alive > 3:
			return false
		elif neighbours_alive < 2:
			return false
	else:
		# если мертвый
		if neighbours_alive == 3:
			return true
	return current

# эта херь чекает нажатие кнопок каждый кадр
func _input(event):
	# реагирует на spacebar/enter
	if event.is_action_pressed("ui_accept"):
		paused = !paused
		timer.paused = paused
	
	# реагирует на esc
	if event.is_action_pressed("ui_cancel"):
		# назад в главное меню
		get_tree().change_scene_to_file("res://menus/main_menu.tscn")
		
	# реагирует на мышку
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_dragging = event.pressed
			if mouse_dragging:
				handle_cell_edit(get_global_mouse_position())
			else:
				last_edited_cell = Vector2(-1, -1)
	
	elif event is InputEventMouseMotion and mouse_dragging:
		handle_cell_edit(get_global_mouse_position())

# эта херь рисует новые клетки когда жмешь мышку
func handle_cell_edit(mouse_position: Vector2):
	var local_pos = to_local(mouse_position)
	var column = int(local_pos.x / cell_size)
	var row = int(local_pos.y / cell_size)
	
	if column <= 0 or column >= column_count - 1:
		return
	if row <= 0 or row >= row_count - 1:
		return
	
	if Vector2(column, row) != last_edited_cell:
		last_edited_cell = Vector2(column, row)
		
		cell_matrix[column][row].visible = !cell_matrix[column][row].visible
		previous_cell_states[column][row] = cell_matrix[column][row].visible

# апдейт, запускается при каждом кадре
func update_game_state():
	# копируем позицию каждой клетки в аррэй
	for column in range(column_count):
		for row in range(row_count):
			previous_cell_states[column][row] = cell_matrix[column][row].visible
	
	# обновляем стейт
	for column in range(column_count):
		for row in range(row_count):
			if !is_edge(column, row):
				cell_matrix[column][row].visible = get_next_state(column, row)
