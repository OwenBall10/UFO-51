extends Node3D

@export var move_speed: float = 15.0

var target_y_rotation: float = 0.0

# --- ZOOM VARIABLES ---
@onready var camera = $Camera3D 

var target_fov: float = 75.0 
var min_fov: float = 30.0   
var max_fov: float = 90.0   
var zoom_step: float = 5.0  

func _process(delta: float) -> void:
	handle_movement(delta)
	handle_rotation(delta)
	handle_zoom(delta)

func handle_movement(delta: float) -> void:
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if input_dir != Vector2.ZERO:
		
		var forward = global_transform.basis.z
		var right = global_transform.basis.x
		
		forward.y = 0.0
		forward = forward.normalized()
		
		right.y = 0.0
		right = right.normalized()
		
		var move_dir = (right * input_dir.x + forward * input_dir.y).normalized()
		
		global_position += move_dir * move_speed * delta

func handle_rotation(delta: float) -> void:

	if Input.is_key_pressed(KEY_Q):
		target_y_rotation += deg_to_rad(90.0)
		set_process(false)
		await get_tree().create_timer(0.2).timeout
		set_process(true)
		
	elif Input.is_key_pressed(KEY_E):
		target_y_rotation -= deg_to_rad(90.0)
		set_process(false)
		await get_tree().create_timer(0.2).timeout
		set_process(true)
		
	rotation.y = lerp_angle(rotation.y, target_y_rotation, 10.0 * delta)

func handle_zoom(delta: float) -> void:
	camera.fov = lerp(camera.fov, target_fov, 10.0 * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_fov = clamp(target_fov - zoom_step, min_fov, max_fov)
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_fov = clamp(target_fov + zoom_step, min_fov, max_fov)
