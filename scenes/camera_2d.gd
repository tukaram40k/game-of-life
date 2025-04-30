extends Camera2D

@export var speed := 2000.0
@export var zoom_step := 0.2
@export var min_zoom := 0.5
@export var max_zoom := 5.0

func _process(delta):
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("camera_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("camera_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("camera_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("camera_up"):
		direction.y -= 1

	position += direction.normalized() * speed * delta

	# Handle zoom input
	if Input.is_action_just_released("Zoom_UP"):
		zoom_camera(-zoom_step)
	elif Input.is_action_just_released("Zoom_DOWN"):
		zoom_camera(zoom_step)

func zoom_camera(step):
	var new_zoom = zoom + Vector2(step, step)
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	zoom = new_zoom
