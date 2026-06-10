@tool
class_name TargetComponent extends Node

enum Team { NEUTRAL, RED, BLUE }

@export var team: Team = Team.NEUTRAL:
	set(value):
		team = value
		
		if is_inside_tree(): 
			apply_team_color()

@export var max_health: float = 100.0
var current_health: float

func _ready() -> void:
	current_health = max_health
	
	
	call_deferred("apply_team_color")

func take_damage(amount: float) -> void:
	current_health -= amount
	print(get_parent().name, " (Team ", team, ") took ", amount, " damage! HP: ", current_health)
	
	var parent = get_parent()
	if parent is RigidBody3D:
		parent.freeze = false
	elif parent is StaticBody3D:
		
		pass
	if current_health <= 0:
		die()

func die() -> void:
	print(get_parent().name, " was destroyed!")
	get_parent().queue_free()

# --- LIVE COLOR LOGIC ---

func apply_team_color() -> void:
	
	var parent = get_parent()
	if parent == null:
		return
	
	var new_material = null 
	
	if team == Team.RED:
		new_material = StandardMaterial3D.new()
		new_material.albedo_color = Color(0.8, 0.1, 0.1)
		new_material.roughness = 1.0
	elif team == Team.BLUE:
		new_material = StandardMaterial3D.new()
		new_material.albedo_color = Color(0.1, 0.3, 0.8)
		new_material.roughness = 1.0

	paint_all_meshes(get_parent(), new_material)

func paint_all_meshes(node: Node, material: StandardMaterial3D) -> void:
	if node is MeshInstance3D:
	
		node.material_override = material
		
	for child in node.get_children():
		paint_all_meshes(child, material)
