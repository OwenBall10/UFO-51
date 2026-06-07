extends Node3D

@export var move_speed: float = 15.0

# --- GRID & RAYCAST VARIABLES ---
@export var grid_cursor: Node3D # We will assign this in the editor
@export var cannon: Node3D 
const FLOOR_COLLISION_MASK: int = 1 # We only want to hit the grass (Layer 1)

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
		
		# --- ZOOM CONTROLS ---
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_fov = clamp(target_fov - zoom_step, min_fov, max_fov)
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_fov = clamp(target_fov + zoom_step, min_fov, max_fov)
			
		# --- TABLETOP DROP CONTROLS ---
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if cannon != null and "current_state" in cannon:
				var state_moving = cannon.CannonState.MOVING if "CannonState" in cannon else 6
				
				# If we are holding the piece in the air, slam it down!
				if cannon.current_state == state_moving:
					cannon.drop()
					get_viewport().set_input_as_handled() # Clean up the input stream

func _physics_process(delta: float) -> void:
	if grid_cursor == null:
		return
		
	# 1. Hide the grid ONLY if aiming or in menus (Idle is 0, Moving is the pickup state)
	if cannon != null and "current_state" in cannon:
		# If the cannon has a state machine, let's get its named states safely
		var state_idle = cannon.CannonState.IDLE if "CannonState" in cannon else 0
		var state_moving = cannon.CannonState.MOVING if "CannonState" in cannon else 6
		
		# Hide the grid if the cannon is doing an action that isn't Idle or Moving
		if cannon.current_state != state_idle and cannon.current_state != state_moving:
			grid_cursor.hide()
			return
			
	grid_cursor.show()
	
	# 2. Mouse Raycasting Math
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = FLOOR_COLLISION_MASK
	
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(query)
	
	if result:
		# Update the visual blue grid square position on the floor
		grid_cursor.update_position(result.position)
		
		# 3. Tactile Piece Hover Logic
		# If the cannon is currently picked up, force its X and Z coordinates to match the grid tile
		if cannon != null and "current_state" in cannon:
			var state_moving = cannon.CannonState.MOVING if "CannonState" in cannon else 6
			if cannon.current_state == state_moving:
				cannon.global_position.x = grid_cursor.global_position.x
				cannon.global_position.z = grid_cursor.global_position.z
