extends Node2D

# сцена с клеткой, она видна в инспекторе
@export var cell_scene_basic : PackedScene
@export var cell_scene_1 : PackedScene
@export var cell_scene_2 : PackedScene

# продолжительность цикла игры
@export var update_interval: float = 0.5

# референс на нод с таймером
@onready var timer: Timer = $Timer

var paused: bool = false

# размер карты и клеток
var row_count : int = 100
var column_count : int = 100
var cell_size: int = 140

# чтобы клетки рисовать
var mouse_dragging := false
var last_edited_cell := Vector2(-1, -1)
var current_cell_type := 0 # 0 = basic, 1 = type1, 2 = type2

# array для клеток
var cell_matrix: Array = []
var cell_types: Array = [] # 0 = basic, 1 = type1, 2 = type2
var previous_cell_states: Array = []
var previous_cell_types: Array = []

# эта херь запускается 1 раз на старте игры
func _ready():
	get_window().mode = Window.MODE_FULLSCREEN
	draw_inverted_zone()
	
	var rng = RandomNumberGenerator.new()
	
	# проверяем что у нас есть хотя бы базовая клетка
	if cell_scene_basic == null:
		push_error("Error: cell_scene_basic is not assigned in the Inspector!")
		return
	
	# проверяем другие типы клеток, и если их нет, используем базовую
	if cell_scene_1 == null:
		cell_scene_1 = cell_scene_basic
	if cell_scene_2 == null:
		cell_scene_2 = cell_scene_basic
	
	# пихаем клетки в 2d array
	for column in range(column_count):
		cell_matrix.push_back([])
		previous_cell_states.push_back([])
		cell_types.push_back([])
		previous_cell_types.push_back([])
		
		for row in range(row_count):
			# Начинаем с разными типами клеток для интересного старта
			var cell_type = 0 # По умолчанию базовая клетка
			
			# Рандомно выбираем тип клетки (но с малой вероятностью для не-базовых)
			var rand_val = rng.randi_range(0, 20)
			if rand_val == 1:
				cell_type = 1
			elif rand_val == 2:
				cell_type = 2
			
			var cell
			match cell_type:
				0: cell = cell_scene_basic.instantiate()
				1: cell = cell_scene_1.instantiate()
				2: cell = cell_scene_2.instantiate()
			
			self.add_child(cell)
			cell.position = Vector2(column * cell_size, row * cell_size)
			
			if rng.randi_range(0, 1) or is_edge(column, row):
				cell.visible = false
				previous_cell_states[column].push_back(false)
			else:
				previous_cell_states[column].push_back(true)
			
			cell_matrix[column].push_back(cell)
			cell_types[column].push_back(cell_type)
			previous_cell_types[column].push_back(cell_type)
	
	# стартует таймер
	timer.wait_time = update_interval
	timer.timeout.connect(update_game_state)
	
	# ВАЖНО: эта херь не дает другим нодам видеть нажатие ESC
	# с этим можно проебаться потом
	process_mode = Node.PROCESS_MODE_ALWAYS

# чекает если позиция это край карты
func is_edge(column, row) -> bool:
	return row == 0 or column == 0 or row == row_count-1 or column == column_count -1

# Function which helps to identify visually the inverted zone
func draw_inverted_zone():
	# Create a border around the inverted zone
	var border = ColorRect.new()
	border.name = "InvertedZoneBorder"
	
	# Set the position and size based on the inverted zone coordinates
	var start_x = 20 * cell_size
	var start_y = 20 * cell_size
	var width = 10 * cell_size
	var height = 10 * cell_size
	
	# Position the border
	border.position = Vector2(start_x, start_y)
	border.size = Vector2(width, height)
	
	# Make it hollow by setting only the border color
	border.color = Color(1, 0, 0, 0.1)  # Semi-transparent red fill
	
	# Add to the scene
	add_child(border)
	
	# Add a border line using Line2D
	var border_line = Line2D.new()
	border_line.name = "InvertedZoneLine"
	border_line.width = 2.0
	border_line.default_color = Color(1, 0, 0, 0.8)  # Red border
	
	# Add points to create the rectangle
	border_line.add_point(Vector2(start_x, start_y))  # Top-left
	border_line.add_point(Vector2(start_x + width, start_y))  # Top-right
	border_line.add_point(Vector2(start_x + width, start_y + height))  # Bottom-right
	border_line.add_point(Vector2(start_x, start_y + height))  # Bottom-left
	border_line.add_point(Vector2(start_x, start_y))  # Back to top-left to close the rectangle
	
	# Add the line to the scene
	add_child(border_line)
	
	# Optional: Add a label to identify the zone
	var label = Label.new()
	label.name = "InvertedZoneLabel"
	label.text = "Inverted Zone"
	label.position = Vector2(start_x + width/2 - 40, start_y - 20)  # Position above the zone
	label.modulate = Color(1, 0, 0)  # Red text
	add_child(label)

# Inverted zone, where rules changes
func is_in_inverted_zone(x: int, y: int) -> bool:
	return x >= 20 and x < 30 and y >= 20 and y < 30

# возвращает количество живых соседей (по типам)
func get_alive_neighbours_by_type(column, row) -> Dictionary:
	var counts = {
		"total": 0,
		"basic": 0,  # тип 0
		"type1": 0,  # тип 1
		"type2": 0   # тип 2
	}
	
	for x in range(-1, 2):
		for y in range(-1, 2):
			if not (x == 0 and y == 0):
				var c = column + x
				var r = row + y
				
				if previous_cell_states[c][r]:
					counts["total"] += 1
					
					match previous_cell_types[c][r]:
						0: counts["basic"] += 1
						1: counts["type1"] += 1
						2: counts["type2"] += 1
	
	return counts

# возвращает количество живых соседей (общее)
func get_alive_neighbours(column, row) -> int:
	var count = 0
	for x in range(-1, 2):
		for y in range(-1, 2):
			if not (x == 0 and y == 0):
				if previous_cell_states[column + x][row + y]:
					count += 1
	return count

# взаимодействие клеток между собой (возвращает новый тип или -1 если клетка должна умереть)
func process_cell_interaction(cell_type, neighbours_by_type) -> int:
	# "Камень-ножницы-бумага" принцип:
	# basic (0) уничтожает type1 (1)
	# type1 (1) уничтожает type2 (2)
	# type2 (2) уничтожает basic (0)
	
	# Проверяем есть ли угроза для текущей клетки
	match cell_type:
		0: # basic под угрозой от type2
			if neighbours_by_type["type2"] >= 2:
				return -1  # уничтожена
		1: # type1 под угрозой от basic
			if neighbours_by_type["basic"] >= 2:
				return -1  # уничтожена
		2: # type2 под угрозой от type1
			if neighbours_by_type["type1"] >= 2:
				return -1  # уничтожена
	
	# Если клетка не была уничтожена, она может трансформироваться
	# Если много соседей противоположного типа, клетка может изменить свой тип
	match cell_type:
		0: # basic может стать type2 если рядом много type2
			if neighbours_by_type["type2"] == 1 and neighbours_by_type["total"] >= 3:
				return 2
		1: # type1 может стать basic если рядом много basic
			if neighbours_by_type["basic"] == 1 and neighbours_by_type["total"] >= 3:
				return 0
		2: # type2 может стать type1 если рядом много type1
			if neighbours_by_type["type1"] == 1 and neighbours_by_type["total"] >= 3:
				return 1
	
	# Если никаких изменений не требуется, возвращаем текущий тип
	return cell_type

# возвращает следующий стейт для базовой клетки с учетом инвертированной зоны
func get_next_state_basic(column, row, neighbours_by_type) -> Dictionary:
	var current = previous_cell_states[column][row]
	var neighbours_alive = neighbours_by_type["total"]
	var result = {"alive": current, "type": 0}
	
	# Проверяем, находится ли клетка в инвертированной зоне
	var in_inverted_zone = is_in_inverted_zone(column, row)
	
	if current == true:  # если клетка живая
		if in_inverted_zone:
			# ИНВЕРТИРОВАННЫЕ ПРАВИЛА: клетка выживает при <2 или >3 соседях
			if neighbours_alive == 2 or neighbours_alive == 3:
				result["alive"] = false  # умирает
			else:
				# Взаимодействие с другими типами
				var interaction_result = process_cell_interaction(0, neighbours_by_type)
				if interaction_result == -1:
					result["alive"] = false
				else:
					result["type"] = interaction_result
		else:
			# СТАНДАРТНЫЕ ПРАВИЛА: клетка умирает при <2 или >3 соседях
			if neighbours_alive > 3 or neighbours_alive < 2:
				result["alive"] = false
			else:
				# Взаимодействие с другими типами
				var interaction_result = process_cell_interaction(0, neighbours_by_type)
				if interaction_result == -1:
					result["alive"] = false
				else:
					result["type"] = interaction_result
	else:  # если клетка мертвая
		if in_inverted_zone:
			# ИНВЕРТИРОВАННЫЕ ПРАВИЛА: клетка оживает, когда НЕ 3 соседа
			if neighbours_alive != 3:
				result["alive"] = true
				
				# Определяем тип новой клетки в зависимости от соседей
				if neighbours_by_type["type1"] > neighbours_by_type["basic"] and neighbours_by_type["type1"] > neighbours_by_type["type2"]:
					result["type"] = 1
				elif neighbours_by_type["type2"] > neighbours_by_type["basic"] and neighbours_by_type["type2"] > neighbours_by_type["type1"]:
					result["type"] = 2
				else:
					result["type"] = 0
		else:
			# СТАНДАРТНЫЕ ПРАВИЛА: клетка оживает только при 3 соседях
			if neighbours_alive == 3:
				result["alive"] = true
				
				# Определяем тип новой клетки в зависимости от соседей
				if neighbours_by_type["type1"] > neighbours_by_type["basic"] and neighbours_by_type["type1"] > neighbours_by_type["type2"]:
					result["type"] = 1
				elif neighbours_by_type["type2"] > neighbours_by_type["basic"] and neighbours_by_type["type2"] > neighbours_by_type["type1"]:
					result["type"] = 2
				else:
					result["type"] = 0
	
	return result

# Правила для типа 1: Выживает при 2-4 соседях, рождается при 3-4 соседях
# возвращает следующий стейт для клетки типа 1 с учетом инвертированной зоны
func get_next_state_type1(column, row, neighbours_by_type) -> Dictionary:
	var current = previous_cell_states[column][row]
	var neighbours_alive = neighbours_by_type["total"]
	var result = {"alive": current, "type": 1}
	
	# Проверяем, находится ли клетка в инвертированной зоне
	var in_inverted_zone = is_in_inverted_zone(column, row)
	
	if current == true:  # если клетка живая
		if in_inverted_zone:
			# ИНВЕРТИРОВАННЫЕ ПРАВИЛА: выживает при <2 или >4 соседях
			if neighbours_alive >= 2 and neighbours_alive <= 4:
				result["alive"] = false  # умирает
			else:
				# Взаимодействие с другими типами
				var interaction_result = process_cell_interaction(1, neighbours_by_type)
				if interaction_result == -1:
					result["alive"] = false
				else:
					result["type"] = interaction_result
		else:
			# СТАНДАРТНЫЕ ПРАВИЛА: тип 1 выживает при 2-4 соседях
			if neighbours_alive < 2 or neighbours_alive > 4:
				result["alive"] = false
			else:
				# Взаимодействие с другими типами
				var interaction_result = process_cell_interaction(1, neighbours_by_type)
				if interaction_result == -1:
					result["alive"] = false
				else:
					result["type"] = interaction_result
	else:  # если клетка мертвая
		if in_inverted_zone:
			# ИНВЕРТИРОВАННЫЕ ПРАВИЛА: клетка оживает, когда НЕ 3-4 соседей
			if neighbours_alive < 3 or neighbours_alive > 4:
				result["alive"] = true
				
				# Определяем тип новой клетки в зависимости от соседей
				if neighbours_by_type["basic"] > neighbours_by_type["type1"] and neighbours_by_type["basic"] > neighbours_by_type["type2"]:
					result["type"] = 0
				elif neighbours_by_type["type2"] > neighbours_by_type["basic"] and neighbours_by_type["type2"] > neighbours_by_type["type1"]:
					result["type"] = 2
				else:
					result["type"] = 1
		else:
			# СТАНДАРТНЫЕ ПРАВИЛА: тип 1 оживает при 3-4 соседях
			if neighbours_alive >= 3 and neighbours_alive <= 4:
				result["alive"] = true
				
				# Определяем тип новой клетки в зависимости от соседей
				if neighbours_by_type["basic"] > neighbours_by_type["type1"] and neighbours_by_type["basic"] > neighbours_by_type["type2"]:
					result["type"] = 0
				elif neighbours_by_type["type2"] > neighbours_by_type["basic"] and neighbours_by_type["type2"] > neighbours_by_type["type1"]:
					result["type"] = 2
				else:
					result["type"] = 1
	
	return result

# Правила для типа 2: Выживает при 1-5 соседях, рождается только при точно 2 соседях
# возвращает следующий стейт для клетки типа 2 с учетом инвертированной зоны
func get_next_state_type2(column, row, neighbours_by_type) -> Dictionary:
	var current = previous_cell_states[column][row]
	var neighbours_alive = neighbours_by_type["total"]
	var result = {"alive": current, "type": 2}
	
	# Проверяем, находится ли клетка в инвертированной зоне
	var in_inverted_zone = is_in_inverted_zone(column, row)
	
	if current == true:  # если клетка живая
		if in_inverted_zone:
			# ИНВЕРТИРОВАННЫЕ ПРАВИЛА: выживает при <1 или >5 соседях
			if neighbours_alive >= 1 and neighbours_alive <= 5:
				result["alive"] = false  # умирает
			else:
				# Взаимодействие с другими типами
				var interaction_result = process_cell_interaction(2, neighbours_by_type)
				if interaction_result == -1:
					result["alive"] = false
				else:
					result["type"] = interaction_result
		else:
			# СТАНДАРТНЫЕ ПРАВИЛА: тип 2 выживает при 1-5 соседях
			if neighbours_alive < 1 or neighbours_alive > 5:
				result["alive"] = false
			else:
				# Взаимодействие с другими типами
				var interaction_result = process_cell_interaction(2, neighbours_by_type)
				if interaction_result == -1:
					result["alive"] = false
				else:
					result["type"] = interaction_result
	else:  # если клетка мертвая
		if in_inverted_zone:
			# ИНВЕРТИРОВАННЫЕ ПРАВИЛА: клетка оживает, когда НЕ 2 соседа
			if neighbours_alive != 2:
				result["alive"] = true
				
				# Определяем тип новой клетки в зависимости от соседей
				if neighbours_by_type["basic"] > neighbours_by_type["type1"] and neighbours_by_type["basic"] > neighbours_by_type["type2"]:
					result["type"] = 0
				elif neighbours_by_type["type1"] > neighbours_by_type["basic"] and neighbours_by_type["type1"] > neighbours_by_type["type2"]:
					result["type"] = 1
				else:
					result["type"] = 2
		else:
			# СТАНДАРТНЫЕ ПРАВИЛА: тип 2 оживает только при 2 соседях
			if neighbours_alive == 2:
				result["alive"] = true
				
				# Определяем тип новой клетки в зависимости от соседей
				if neighbours_by_type["basic"] > neighbours_by_type["type1"] and neighbours_by_type["basic"] > neighbours_by_type["type2"]:
					result["type"] = 0
				elif neighbours_by_type["type1"] > neighbours_by_type["basic"] and neighbours_by_type["type1"] > neighbours_by_type["type2"]:
					result["type"] = 1
				else:
					result["type"] = 2
	
	return result

# возвращает следующий стейт в зависимости от типа клетки
func get_next_state(column, row) -> Dictionary:
	var cell_type = cell_types[column][row]
	var neighbours_by_type = get_alive_neighbours_by_type(column, row)
	
	match cell_type:
		0: return get_next_state_basic(column, row, neighbours_by_type)
		1: return get_next_state_type1(column, row, neighbours_by_type)
		2: return get_next_state_type2(column, row, neighbours_by_type)
	
	return {"alive": false, "type": 0} # default case

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
	
	# переключение типа клетки с помощью цифр 1, 2, 3
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_1:
				current_cell_type = 0
				print("Выбран тип клетки: Базовая (0)")
			elif event.keycode == KEY_2:
				current_cell_type = 1
				print("Выбран тип клетки: Тип 1 (1)")
			elif event.keycode == KEY_3:
				current_cell_type = 2
				print("Выбран тип клетки: Тип 2 (2)")
	
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
		
		# Удаляем старую клетку
		if cell_matrix[column][row]:
			cell_matrix[column][row].queue_free()
		
		# Создаем новую клетку нужного типа
		var new_cell: Node2D
		match current_cell_type:
			0: new_cell = cell_scene_basic.instantiate()
			1: new_cell = cell_scene_1.instantiate()
			2: new_cell = cell_scene_2.instantiate()
			_: new_cell = cell_scene_basic.instantiate()
		
		self.add_child(new_cell)
		new_cell.position = Vector2(column * cell_size, row * cell_size)
		new_cell.visible = true
		
		cell_matrix[column][row] = new_cell
		previous_cell_states[column][row] = true
		cell_types[column][row] = current_cell_type

# апдейт, запускается при таймере
func update_game_state():
	# копируем позицию и тип каждой клетки в массивы
	for column in range(column_count):
		for row in range(row_count):
			previous_cell_states[column][row] = cell_matrix[column][row].visible
			previous_cell_types[column][row] = cell_types[column][row]
	
	# Создаем временный массив для хранения новых состояний
	var new_states = []
	for column in range(column_count):
		new_states.push_back([])
		for row in range(row_count):
			new_states[column].push_back({"alive": false, "type": 0})
	
	# обновляем стейт
	for column in range(1, column_count - 1):
		for row in range(1, row_count - 1):
			if !is_edge(column, row):
				var result = get_next_state(column, row)
				new_states[column][row] = result
	
	# применяем новые состояния и обновляем визуализацию
	for column in range(1, column_count - 1):
		for row in range(1, row_count - 1):
			if !is_edge(column, row):
				var new_state = new_states[column][row]
				var new_type = new_state["type"]
				
				# если тип изменился или клетка изменила состояние (жива/мертва)
				if new_type != cell_types[column][row] or new_state["alive"] != cell_matrix[column][row].visible:
					# Удаляем старую клетку
					if cell_matrix[column][row]:
						cell_matrix[column][row].queue_free()
					
					# Создаем новую клетку нужного типа
					var new_cell: Node2D
					match new_type:
						0: new_cell = cell_scene_basic.instantiate()
						1: new_cell = cell_scene_1.instantiate()
						2: new_cell = cell_scene_2.instantiate()
						_: new_cell = cell_scene_basic.instantiate()
					
					self.add_child(new_cell)
					new_cell.position = Vector2(column * cell_size, row * cell_size)
					new_cell.visible = new_state["alive"]
					
					cell_matrix[column][row] = new_cell
					cell_types[column][row] = new_type
				else:
					# Просто обновляем видимость
					cell_matrix[column][row].visible = new_state["alive"]

# конектится к кнопкам, не трогайте
func _on_cell1_button_pressed():
	current_cell_type = 0

func _on_cell2_button_pressed():
	current_cell_type = 1

func _on_cell3_button_pressed():
	current_cell_type = 2
