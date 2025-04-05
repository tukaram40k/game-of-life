extends Node2D

# сцена с клеткой, она видна в инспекторе
@export var cell_scene_basic : PackedScene

# размер карты и клеток
var row_count : int = 50
var column_count : int = 50
var cell_size: int = 50

# array для клеток
var cell_matrix: Array = []
var previous_cell_states: Array = []

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

func is_edge(column, row) -> bool:
	return row == 0 or column == 0 or row == row_count-1 or column == column_count -1

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

# апдейт, запускается при каждом кадре
func _process(delta):
	# копируем позицию каждой клетки в аррэй
	for column in range(column_count):
		for row in range(row_count):
			previous_cell_states[column][row] = cell_matrix[column][row].visible
	
	# обновляем стейт
	for column in range(column_count):
		for row in range(row_count):
			if !is_edge(column, row):
				cell_matrix[column][row].visible = get_next_state(column, row)
