extends RigidBody3D

var stored_power: float = 0.0
var has_hit: bool = false


@export var impulse_transfer: float = 0.3

@export var despawn_delay: float = 3.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	var damage: float = stored_power * 2.0

	if body.has_method("take_hit"):
		var dir: Vector3 = (body.global_position - global_position).normalized()
		body.take_hit(damage, dir * stored_power * impulse_transfer)
	elif body.has_method("take_damage"):
		body.take_damage(damage)

	if not has_hit:
		has_hit = true
		await get_tree().create_timer(despawn_delay).timeout
		queue_free()
