@tool
extends EditorScript


const CONTAINER_PATH := "Castle"  # path relative to the scene root

func _run() -> void:
	var root := get_scene()
	if root == null:
		push_error("Open your main scene first, then run this script.")
		return

	var container := root.get_node_or_null(CONTAINER_PATH) as Node3D
	if container == null:
		push_error("Couldn't find a Node3D at '%s' under the scene root." % CONTAINER_PATH)
		return

	var s := container.scale
	if not (is_equal_approx(s.x, s.y) and is_equal_approx(s.y, s.z)):
		push_error("Scale %s is non-uniform — bake that manually." % s)
		return

	var f := s.x
	if is_equal_approx(f, 1.0):
		print("'%s' already has scale 1 — nothing to do." % CONTAINER_PATH)
		return

	container.scale = Vector3.ONE
	var counts := {"moved": 0, "resized": 0}
	_bake(container, f, root, counts)

	print("Done. Baked scale %.3f into '%s': %d nodes repositioned, %d visuals/shapes resized."
		% [f, CONTAINER_PATH, counts["moved"], counts["resized"]])
	print("Remember: castle_wall.tscn's BoxMesh + BoxShape3D Size must be set to %.3f. Now save the scene." % f)


func _bake(node: Node, f: float, scene_root: Node, counts: Dictionary) -> void:
	for child in node.get_children():
		if not (child is Node3D):
			continue

		# Same world position, expressed without the parent scale.
		child.position *= f
		counts["moved"] += 1

		var is_body := child is PhysicsBody3D
		var is_instance := child.scene_file_path != ""

		if is_body:
		
			if not is_instance:
				_bake(child, f, scene_root, counts)
		elif is_instance:
			
			child.scale *= f
			counts["resized"] += 1
		elif child is MeshInstance3D or child is CollisionShape3D \
				or child is Label3D or child is CSGShape3D:
			# Leaf visuals / shapes built directly in this scene.
			child.scale *= f
			counts["resized"] += 1
			_bake(child, f, scene_root, counts)
		else:
			
			_bake(child, f, scene_root, counts)
