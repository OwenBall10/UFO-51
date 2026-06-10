extends RigidBody3D

@export var max_health: float = 100.0
var current_health: float

# --- State Trackers --- 
var is_invincible: bool = false
var is_dead: bool = false

func _ready() -> void:
	current_health = max_health


func take_damage(damage_amount: float) -> void:
	if is_invincible or is_dead:
		return
		
	current_health -= damage_amount

	
	if current_health <= 0:
		die()
	


func die() -> void:
	is_dead = true
	
	
	axis_lock_angular_x = false
	axis_lock_angular_z = false
	
	var tip_direction = global_transform.basis.z 
	apply_central_impulse(tip_direction * 5.0)
	
	print("Unit Defeated!")
	
	
	
