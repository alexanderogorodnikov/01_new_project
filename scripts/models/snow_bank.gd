extends Node3D
class_name SnowBank
## Soft snow cover pile made from overlapping spheres (visual + collision).

@export var bank_scale: Vector3 = Vector3(1, 1, 1)
@export var snow_material: Material


func _ready() -> void:
	scale = bank_scale
	_build()


func _build() -> void:
	var mat := snow_material
	if mat == null:
		mat = load("res://resources/materials/snow_ground.tres")

	var clumps := [
		{"pos": Vector3(0, 0.15, 0), "r": 0.85},
		{"pos": Vector3(0.55, 0.05, 0.2), "r": 0.55},
		{"pos": Vector3(-0.5, 0.0, -0.15), "r": 0.5},
		{"pos": Vector3(0.15, 0.35, -0.35), "r": 0.45},
		{"pos": Vector3(-0.2, 0.25, 0.4), "r": 0.4},
		{"pos": Vector3(0.7, -0.05, -0.35), "r": 0.35},
	]

	for i in clumps.size():
		var c: Dictionary = clumps[i]
		var mi := MeshInstance3D.new()
		mi.name = "Clump%d" % i
		var mesh := SphereMesh.new()
		mesh.radius = c.r
		mesh.height = c.r * 1.7
		mesh.radial_segments = 16
		mesh.rings = 8
		mi.mesh = mesh
		mi.material_override = mat
		mi.position = c.pos
		add_child(mi)

	# Simple collision hull approximating the pile.
	var body := get_parent() as StaticBody3D
	if body:
		var shape := CollisionShape3D.new()
		shape.name = "SnowBankCollision"
		var box := BoxShape3D.new()
		box.size = Vector3(2.2, 1.1, 1.8)
		shape.shape = box
		shape.position = Vector3(0, 0.35, 0)
		body.add_child.call_deferred(shape)
