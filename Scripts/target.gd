class_name TargetComponent extends Node

enum Team { NEUTRAL, RED, BLUE }
@export var team: Team = Team.NEUTRAL

@export var max_health: float = 100.0
var current_health: float

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float) -> void:
	current_health -= amount
	print(get_parent().name, " (Team ", team, ") took ", amount, " damage! HP: ", current_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	print(get_parent().name, " was destroyed!")
	get_parent().queue_free() # Destroys the main piece, not just the component!
