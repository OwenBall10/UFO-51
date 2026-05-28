extends RigidBody3D

@export var max_health: float = 100.0
var current_health: float

# --- State Trackers --- 
var is_invincible: bool = false
var is_dead: bool = false

# --- Node References ---
@onready var mesh = $MeshInstance3D # Make sure this matches your mesh name!
@onready var health_ui = $HealthUI

func _ready() -> void:
	current_health = max_health
	update_health_text()

func take_damage(damage_amount: float) -> void:
	if is_invincible or is_dead:
		return
		
	current_health -= damage_amount
	update_health_text()
	
	if current_health <= 0:
		die()
	else:
		trigger_invincibility_flash()

func update_health_text() -> void:
	health_ui.text = "HP: " + str(round(current_health)) + " / " + str(max_health)

func trigger_invincibility_flash() -> void:
	is_invincible = true
	
	for i in range(5):
		mesh.hide()
		await get_tree().create_timer(0.1).timeout
		mesh.show()
		await get_tree().create_timer(0.1).timeout
		
	is_invincible = false

func die() -> void:
	is_dead = true
	health_ui.hide() 
	
	
	axis_lock_angular_x = false
	axis_lock_angular_z = false
	
	var tip_direction = global_transform.basis.z 
	apply_central_impulse(tip_direction * 5.0)
	
	print("Unit Defeated!")
