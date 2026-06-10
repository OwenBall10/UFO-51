extends MeshInstance3D

const TILE_SIZE: float = 10.0 

func snap_to_grid(raw_position: Vector3) -> Vector3:
	var snapped_x = round(raw_position.x / TILE_SIZE) * TILE_SIZE
	var snapped_z = round(raw_position.z / TILE_SIZE) * TILE_SIZE
	
	return Vector3(snapped_x, raw_position.y, snapped_z)

func update_position(mouse_hit_position: Vector3) -> void:
	global_position = snap_to_grid(mouse_hit_position)
	
	global_position.y = 0.1
