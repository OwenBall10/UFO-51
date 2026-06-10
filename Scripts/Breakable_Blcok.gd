extends RigidBody3D

# ============================================================
# Breakable castle block.
# Starts frozen (set freeze = true in the scene) so the castle
# is rock solid on boot. A cannonball hit unfreezes it, shoves
# it, and wakes nearby blocks; moving blocks then chain-wake
# any frozen blocks they crash into, so walls actually crumble.
# ============================================================

@export var max_health: float = 100.0
## Impacts wake frozen neighbors within this distance (world units).
## Blocks are 0.5 wide, so 0.8 ≈ the ring of touching neighbors.
@export var wake_radius: float = 0.8
## A moving block must be going at least this fast (m/s) to
## chain-unfreeze a frozen block it collides with.
@export var chain_speed_threshold: float = 0.6

var current_health: float
var is_dead: bool = false

func _ready() -> void:
	current_health = max_health
	add_to_group("castle_blocks")

# Called by the cannonball: damage + a shove in the hit direction.
func take_hit(damage: float, impulse: Vector3) -> void:
	if is_dead:
		return

	current_health -= damage
	print(name, " took ", damage, " damage! HP: ", current_health)

	unfreeze()
	apply_central_impulse(impulse)

	# Wake the blocks touching this one so the wall can give way.
	for block in get_tree().get_nodes_in_group("castle_blocks"):
		if block != self and block.freeze \
				and block.global_position.distance_to(global_position) <= wake_radius:
			block.unfreeze()

	if current_health <= 0:
		die()

# Kept for compatibility with anything that calls plain take_damage().
func take_damage(damage: float) -> void:
	take_hit(damage, Vector3.ZERO)

func unfreeze() -> void:
	if not freeze:
		return
	freeze = false
	sleeping = false
	# Now that this block can move, let it report collisions so it
	# can chain-wake frozen blocks it crashes into.
	contact_monitor = true
	max_contacts_reported = 8
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Chain reaction: a moving block slamming into a frozen block wakes it.
	if body is RigidBody3D and body.is_in_group("castle_blocks") and body.freeze:
		if linear_velocity.length() > chain_speed_threshold:
			body.unfreeze()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	print(name, " was destroyed!")
	queue_free()
