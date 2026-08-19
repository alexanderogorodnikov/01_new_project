extends MeshInstance3D
## Adds irregular snow clumps so the ball reads less like a perfect sphere.

@export var lump_count: int = 5


func _ready() -> void:
	var base_mat := material_override
	if base_mat == null and get_surface_override_material(0):
		base_mat = get_surface_override_material(0)
	if base_mat == null:
		base_mat = load("res://resources/materials/snowball_mat.tres")

	for i in lump_count:
		var lump := MeshInstance3D.new()
		lump.name = "Lump%d" % i
		var mesh := SphereMesh.new()
		var r := randf_range(0.035, 0.06)
		mesh.radius = r
		mesh.height = r * 2.0
		mesh.radial_segments = 10
		mesh.rings = 6
		lump.mesh = mesh
		lump.material_override = base_mat
		var dir := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		lump.position = dir * randf_range(0.07, 0.11)
		add_child(lump)
