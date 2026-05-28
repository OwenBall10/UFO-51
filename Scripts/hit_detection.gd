extends RigidBody3D

var stored_power: float = 0.0 

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		
		var calculated_damage = stored_power * 2.0 
		
		body.take_damage(calculated_damage)
