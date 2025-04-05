extends Node2D

# сцена с клеткой, она видна в инспекторе
@export var cell_scene_basic : PackedScene

# размер карты и клеток
var row_count : int = 100
var column_count : int = 100
var cell_width: int = 50

func _ready():
	get_window().mode = Window.MODE_FULLSCREEN
	
	# пихаем клетки в 2d array
	for column in range(column_count):
		for row in range(row_count):
			var cell = cell_scene_basic.instantiate()
			self.add_child(cell)
			cell.position = Vector2(column * cell_width, row * cell_width)

# апдейт, запускается при каждом кадре
func _process(delta: float) -> void:
	pass
