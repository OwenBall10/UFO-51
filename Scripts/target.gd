class_name Target extends Node3D


enum Team { NEUTRAL, RED, BLUE }
@export var team: Team = Team.NEUTRAL

@export var max_health: float = 100.0
var current_health: float

func _ready() -> void:
	current_health = max_health

# Every single target shares this exact damage math
func take_damage(amount: float) -> void:
	current_health -= amount
	print(name, " (Team ", team, ") took ", amount, " damage! HP: ", current_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	print(name, " was destroyed!")
	queue_free() # Removes the piece from the board
