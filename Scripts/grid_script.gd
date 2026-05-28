extends MeshInstance3D

const TILE_SIZE: float = 10.0 

# This function takes any 3D coordinate and returns the exact center of the nearest grid tile
func snap_to_grid(raw_position: Vector3) -> Vector3:
	var snapped_x = round(raw_position.x / TILE_SIZE) * TILE_SIZE
	var snapped_z = round(raw_position.z / TILE_SIZE) * TILE_SIZE
	
	# We leave Y alone so the cursor stays flat on the ground
	return Vector3(snapped_x, raw_position.y, snapped_z)

# We call this from  main camera or level script when the mouse moves
func update_position(mouse_hit_position: Vector3) -> void:
	global_position = snap_to_grid(mouse_hit_position)
	
	# Lift it 0.1 meters off the ground so it doesn't clip into the grass
	global_position.y = 0.1
