extends Node3D
class_name MittHand
## Soft winter mitt / controller proxy for VR hands.

@export var cuff_color: Color = Color(0.32, 0.55, 0.42)
@export var mitt_color: Color = Color(0.93, 0.91, 0.86)


func _ready() -> void:
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()

	var cuff := MeshInstance3D.new()
	cuff.name = "Cuff"
	var cuff_mesh := CylinderMesh.new()
	cuff_mesh.top_radius = 0.035
	cuff_mesh.bottom_radius = 0.04
	cuff_mesh.height = 0.08
	cuff_mesh.radial_segments = 12
	cuff.mesh = cuff_mesh
	cuff.material_override = _mat(cuff_color)
	cuff.position = Vector3(0, 0, 0.04)
	cuff.rotation = Vector3(deg_to_rad(90), 0, 0)
	add_child(cuff)

	var palm := MeshInstance3D.new()
	palm.name = "Palm"
	var palm_mesh := SphereMesh.new()
	palm_mesh.radius = 0.055
	palm_mesh.height = 0.09
	palm_mesh.radial_segments = 14
	palm_mesh.rings = 8
	palm.mesh = palm_mesh
	palm.material_override = _mat(mitt_color)
	palm.position = Vector3(0, 0, -0.02)
	add_child(palm)

	var thumb := MeshInstance3D.new()
	thumb.name = "Thumb"
	var thumb_mesh := CapsuleMesh.new()
	thumb_mesh.radius = 0.018
	thumb_mesh.height = 0.07
	thumb.mesh = thumb_mesh
	thumb.material_override = _mat(mitt_color)
	thumb.position = Vector3(0.045, 0.01, -0.01)
	thumb.rotation = Vector3(0, 0, deg_to_rad(35))
	add_child(thumb)

	for i in 3:
		var finger := MeshInstance3D.new()
		finger.name = "Finger%d" % i
		var fm := CapsuleMesh.new()
		fm.radius = 0.014
		fm.height = 0.06
		finger.mesh = fm
		finger.material_override = _mat(mitt_color)
		finger.position = Vector3((-0.025 + i * 0.025), 0.0, -0.055)
		finger.rotation = Vector3(deg_to_rad(70), 0, 0)
		add_child(finger)


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.88
	return m
