extends Node3D 

# --- Weapon Stats ---
@export var aim_speed: float = 2.0 
@export var pre_aim_speed: float = 1.5  
@export var move_rotation_speed: float = 3.0  
@export var max_power: float = 50.0 
@export var projectile_scene: PackedScene
@export var tile_size: float = 2.0

# --- State Machine ---
enum CannonState { IDLE, AIM_HORIZONTAL, AIM_VERTICAL, POWER_SET, FIRED, MENU_OPEN, MOVING, PRE_AIM }
var current_state: CannonState = CannonState.IDLE

# --- Node References ---
@onready var barrel_pivot = $CannonBarrelPivot 
@onready var fire_point = $CannonBarrelPivot/FirePoint 
@onready var crosshair = $CannonBarrelPivot/FirePoint/CrosshairGraphic
@onready var power_bar = $UI/ProgressBar
@onready var horiz_meter = $UI/HorizontalMeter
@onready var horiz_ticker = $UI/HorizontalMeter/HorizTicker
@onready var vert_meter = $UI/VerticalMeter
@onready var vert_ticker = $UI/VerticalMeter/VertTicker
@export var attack_button: Button  
@onready var Camera = $CannonBarrelPivot/Camera3D

# --- Sweeping Variables --- 
var sweep_direction: int = 1
var vertical_sweep_dir: int = 1
var current_horizontal_angle: float = 0.0
var current_vertical_angle: float = 0.0
var current_power: float = 0.0
var power_direction: int = 1
 
# --- Extra --- 
var original_y: float = 0.0
var base_y_rotation: float = 0.0

@onready var target = $TargetComponent
var original_grid_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	power_bar.max_value = max_power
	power_bar.value = 0.0
	horiz_meter.hide()
	vert_meter.hide()
	power_bar.hide()
	crosshair.hide()
	if attack_button:
		attack_button.hide()

func _process(delta: float) -> void:
	update_meters()
	match current_state:
		CannonState.IDLE:
			pass
		CannonState.MOVING:
			var rotation_input := 0.0
			if Input.is_key_pressed(KEY_A):
				rotation_input -= 1.0
			if Input.is_key_pressed(KEY_D):
				rotation_input += 1.0
			rotation.y += rotation_input * move_rotation_speed * delta
			
			var mouse_pos = get_viewport().get_mouse_position()
			var camera = get_viewport().get_camera_3d()
			
			var ray_origin = camera.project_ray_origin(mouse_pos)
			var ray_dir = camera.project_ray_normal(mouse_pos)
			
			if not is_zero_approx(ray_dir.y):
				var t = (original_y - ray_origin.y) / ray_dir.y
				var target_pos = ray_origin + ray_dir * t
				
				
				var snapped = snap_to_grid(target_pos)
				
				if target:
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
				
			
		CannonState.PRE_AIM:
			var h_input := Input.get_axis("ui_left", "ui_right")
			var v_input := Input.get_axis("ui_down", "ui_up")
			
			current_horizontal_angle += h_input * pre_aim_speed * delta * -1.0
			current_vertical_angle += v_input * pre_aim_speed * delta
			
			current_horizontal_angle = clamp(current_horizontal_angle, -deg_to_rad(60.0), deg_to_rad(60.0))
			current_vertical_angle = clamp(current_vertical_angle, 0.0, deg_to_rad(60.0))
			
			rotation.y = base_y_rotation + current_horizontal_angle
			barrel_pivot.rotation.z = current_vertical_angle
			
		CannonState.AIM_HORIZONTAL:
			current_horizontal_angle += aim_speed * sweep_direction * delta
			
			if abs(current_horizontal_angle) >= deg_to_rad(60.0):
				current_horizontal_angle = sign(current_horizontal_angle) * deg_to_rad(60.0)
				sweep_direction *= -1 
				
			rotation.y = base_y_rotation + current_horizontal_angle
			
		CannonState.AIM_VERTICAL:
			
			current_vertical_angle += aim_speed * vertical_sweep_dir * delta
			
		
			if current_vertical_angle > deg_to_rad(60.0) or current_vertical_angle < 0.0:
				vertical_sweep_dir *= -1
				
			
			barrel_pivot.rotation.z = current_vertical_angle
			
		CannonState.POWER_SET:
			current_power += (max_power * aim_speed * 0.5) * power_direction * delta 
			
			if current_power > max_power:
				current_power = max_power
				power_direction = -1 
			elif current_power < 0.0: 
				current_power = 0.0
				power_direction = 1
				
			power_bar.value = current_power


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if current_state == CannonState.MOVING:
				drop()
				get_viewport().set_input_as_handled()
	
	if event.is_action_pressed("ui_accept"):
		match current_state:
			CannonState.PRE_AIM:
				current_state = CannonState.AIM_HORIZONTAL
				horiz_meter.show()
			CannonState.AIM_HORIZONTAL:
				current_state = CannonState.AIM_VERTICAL
				vert_meter.show()
			CannonState.AIM_VERTICAL:
				current_state = CannonState.POWER_SET
				power_bar.show()
			CannonState.POWER_SET:
				current_state = CannonState.FIRED
				fire_cannon() 

# --- Action Functions ---
func fire_cannon() -> void:
	print("BOOM! Cannon Fired!")
	print("Final Power: ", current_power)
	print("Horizontal Angle: ", rad_to_deg(current_horizontal_angle))
	print("Vertical Angle: ", rad_to_deg(current_vertical_angle))
	
	if projectile_scene == null:
		print("Cannon not loaded in inspector")
		return 
	
	var ball = projectile_scene.instantiate()
	ball.stored_power = current_power
	get_tree().root.add_child(ball)
	
	ball.global_position = fire_point.global_position
	
	var aim_direction: Vector3 = barrel_pivot.global_transform.basis.x.normalized()
	ball.apply_central_impulse(aim_direction * current_power) 
	
	GameManager.register_cannon_fire()
	
	await get_tree().create_timer(1.5).timeout
	reset_cannon()
# --- UI Functions ---
func update_meters() -> void:
	var h_percent = (current_horizontal_angle + deg_to_rad(60.0)) / deg_to_rad(120.0)
	horiz_ticker.position.x = h_percent * (horiz_meter.size.x - horiz_ticker.size.x)
	
	var v_percent = current_vertical_angle / deg_to_rad(60.0)
	vert_ticker.position.x = v_percent * (vert_meter.size.x - vert_ticker.size.x)
	

func reset_cannon() -> void:
	current_horizontal_angle = 0.0
	current_vertical_angle = 0.0
	current_power = 0.0
	sweep_direction = 1
	vertical_sweep_dir = 1
	power_direction = 1
	
	rotation.y = base_y_rotation
	barrel_pivot.rotation.z = 0.0
	
	power_bar.value = 0.0
	power_bar.hide()
	horiz_meter.hide()
	vert_meter.hide()
	crosshair.hide()
	if attack_button:
		attack_button.hide()
	Camera.clear_current()
	
	current_state = CannonState.IDLE
	print("Cannon Reloaded and IDLE.")


func _on_selection_area_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		
		if target and target.team != GameManager.current_turn:
			print("Not your turn!")
			return
		# --- LEFT CLICK: Grab the piece ---
		if event.button_index == MOUSE_BUTTON_LEFT:
			if current_state == CannonState.IDLE:
				pick_up()
				
				get_viewport().set_input_as_handled() 
				
		# --- RIGHT CLICK: Open the Attack Menu ---
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if current_state == CannonState.IDLE:
				current_state = CannonState.MENU_OPEN
				if attack_button:
					attack_button.show()
				get_viewport().set_input_as_handled()


func _on_attack_button_pressed() -> void:
	if attack_button and current_state == CannonState.MENU_OPEN:
		attack_button.hide()
		
		base_y_rotation = rotation.y 
		
		current_horizontal_angle = 0.0 
		
		
		current_vertical_angle = barrel_pivot.rotation.z
		current_state = CannonState.PRE_AIM
		crosshair.show()
		Camera.make_current()


func pick_up() -> void:
	current_state = CannonState.MOVING
	original_y = global_position.y 
	original_grid_pos = snap_to_grid(global_position)
	global_position.y += 0.5 
	set_mesh_transparency(self, 0.6)

func drop() -> void:
	current_state = CannonState.IDLE
	var final_pos = snap_to_grid(global_position)
	
	
	if target.team == TargetComponent.Team.BLUE:
		var steps_x = int(round((final_pos.x - original_grid_pos.x) / tile_size))
		var steps_z = int(round((final_pos.z - original_grid_pos.z) / tile_size))
		var total_steps = steps_x + steps_z
		
		if total_steps > 0:
			GameManager.blue_ap -= total_steps
			print("Blue moved ", total_steps, " spaces. Remaining AP: ", GameManager.blue_ap)
	
	
	global_position.y = original_y
	global_position.x = final_pos.x
	global_position.z = final_pos.z
	set_mesh_transparency(self, 0.0)


func snap_to_grid(raw_position: Vector3) -> Vector3:
	var snapped_x = round(raw_position.x / tile_size) * tile_size
	var snapped_z = round(raw_position.z / tile_size) * tile_size
	return Vector3(snapped_x, raw_position.y, snapped_z)
func set_mesh_transparency(node: Node, alpha: float) -> void:
	if node is MeshInstance3D:
		node.transparency = alpha
	for child in node.get_children():
		set_mesh_transparency(child, alpha)
