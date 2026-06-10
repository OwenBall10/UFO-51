extends RigidBody3D

@export var is_general: bool = false 
@onready var target = $TargetComponent

@export var move_rotation_speed: float = 3.0
@export var max_health: float = 100.0

@export var lift_height: float = 0.5

@export var start_frozen: bool = true

@export var tile_size: float = 1.5

var current_health: float
var is_invincible: bool = false
var is_dead: bool = false

var original_y: float = 0.0
var original_grid_pos: Vector3 = Vector3.ZERO
var is_being_dragged: bool = false

func _ready() -> void:
	current_health = max_health
	if start_frozen:
		freeze = true
	original_grid_pos = global_position

func take_damage(damage_amount: float) -> void:
	if is_invincible or is_dead:
		return
	
	current_health -= damage_amount
	print(name, " took ", damage_amount, " damage! HP: ", current_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	
	if is_general:
		GameManager.game_over(target.team)
	else:
		GameManager.register_soldier_death(target.team)
	
	freeze = false
	axis_lock_angular_x = false
	axis_lock_angular_z = false
	
	var tip_direction = global_transform.basis.z 
	apply_central_impulse(tip_direction * 5.0)
	
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _process(delta: float) -> void:
	if is_being_dragged:
		var mouse_pos = get_viewport().get_mouse_position()
		var camera = get_viewport().get_camera_3d()
		
		var rotation_input := 0.0
		if Input.is_key_pressed(KEY_A):
			rotation_input -= 1.0
		if Input.is_key_pressed(KEY_D):
			rotation_input += 1.0
		
		rotation.y += rotation_input * move_rotation_speed * delta

		
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_dir = camera.project_ray_normal(mouse_pos)
		
		if not is_zero_approx(ray_dir.y):
			var t = (original_y - ray_origin.y) / ray_dir.y
			var target_pos = ray_origin + ray_dir * t
			
			var snapped = snap_to_grid(target_pos)
			
			if target.team == TargetComponent.Team.RED:
				snapped.x = original_grid_pos.x
				snapped.z = original_grid_pos.z
				
			elif target.team == TargetComponent.Team.BLUE:
				snapped.x = max(snapped.x, original_grid_pos.x)
				snapped.z = max(snapped.z, original_grid_pos.z)
				
				var steps_x = int(round((snapped.x - original_grid_pos.x) / tile_size))
				var steps_z = int(round((snapped.z - original_grid_pos.z) / tile_size))
				var total_steps = steps_x + steps_z
				
				if total_steps > GameManager.blue_ap:
					snapped.x = original_grid_pos.x
					snapped.z = original_grid_pos.z
					
			global_position.x = snapped.x
			global_position.z = snapped.z

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not is_being_dragged:
			var camera = get_viewport().get_camera_3d()
			var mouse_pos = get_viewport().get_mouse_position()
			
			var ray_origin = camera.project_ray_origin(mouse_pos)
			var ray_dir = camera.project_ray_normal(mouse_pos)
			
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_dir * 1000.0)
			var result = space_state.intersect_ray(query)
			
			if result and result.collider == self:
				
				if target.team != GameManager.current_turn:
					InGameTerminal.log_msg("Not your turn!")
					return
				pick_up()
				get_tree().root.set_input_as_handled()
		elif not event.pressed and is_being_dragged:
			drop()
			get_tree().root.set_input_as_handled()

func pick_up() -> void:
	if is_dead:
		return
	is_being_dragged = true
	original_y = global_position.y
	original_grid_pos = snap_to_grid(global_position)
	global_position.y += lift_height
	
	set_transparency(0.6)
func drop() -> void:
	is_being_dragged = false
	var final_pos = snap_to_grid(global_position)
	
	# --- SPEND GLOBAL AP ---
	if target.team == TargetComponent.Team.BLUE:
		var steps_x = int(round((final_pos.x - original_grid_pos.x) / tile_size))
		var steps_z = int(round((final_pos.z - original_grid_pos.z) / tile_size))
		var total_steps = steps_x + steps_z
		
		if total_steps > 0:
			GameManager.blue_ap -= total_steps
			InGameTerminal.log_msg(str("Blue moved ", total_steps, " spaces. Remaining AP: ", GameManager.blue_ap))
	
	freeze = true  
	global_position = Vector3(final_pos.x, original_y, final_pos.z)
	set_transparency(0.0)

func snap_to_grid(raw_position: Vector3) -> Vector3:
	var snapped_x = round(raw_position.x / tile_size) * tile_size
	var snapped_z = round(raw_position.z / tile_size) * tile_size
	return Vector3(snapped_x, raw_position.y, snapped_z)

func set_transparency(alpha: float) -> void:
	for child in get_children():
		if child is MeshInstance3D:
			child.transparency = alpha
		elif child is Node3D:
			_set_transparency_recursive(child, alpha)

func _set_transparency_recursive(node: Node, alpha: float) -> void:
	if node is MeshInstance3D:
		node.transparency = alpha
	for child in node.get_children():
		_set_transparency_recursive(child, alpha)
