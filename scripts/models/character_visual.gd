extends Node3D
class_name CharacterVisual
## Builds a readable winter humanoid from primitives (coat, limbs, head, gear).

@export_enum("player", "bot") var palette: String = "bot"
@export var show_face: bool = true

## Root mesh used by hit-flash code (torso/coat).
var body_mesh: MeshInstance3D

var _coat_mat: StandardMaterial3D


func _ready() -> void:
	_build()


func get_flash_mesh() -> MeshInstance3D:
	return body_mesh


func _build() -> void:
	for child in get_children():
		child.queue_free()

	var colors := _palette_colors(palette)
	_coat_mat = _mat(colors.coat)

	# Soft winter silhouette, feet at y≈0.
	body_mesh = _add_mesh("BodyMesh", _capsule(0.28, 0.78), _coat_mat, Vector3(0, 1.18, 0))
	_add_mesh("Belly", _sphere(0.3, 0.42), _coat_mat, Vector3(0, 1.05, 0.04))
	_add_mesh("CoatHem", _cylinder(0.32, 0.12, 0.26), _coat_mat, Vector3(0, 0.86, 0))

	_add_mesh("Pelvis", _sphere(0.24, 0.28), _mat(colors.pants), Vector3(0, 0.74, 0))
	_add_mesh("LegL", _capsule(0.1, 0.55), _mat(colors.pants), Vector3(-0.12, 0.4, 0))
	_add_mesh("LegR", _capsule(0.1, 0.55), _mat(colors.pants), Vector3(0.12, 0.4, 0))
	_add_mesh("BootL", _box(Vector3(0.18, 0.14, 0.32)), _mat(colors.boots), Vector3(-0.12, 0.09, 0.05))
	_add_mesh("BootR", _box(Vector3(0.18, 0.14, 0.32)), _mat(colors.boots), Vector3(0.12, 0.09, 0.05))

	# Ready-to-throw arm pose.
	_add_mesh("ArmL", _capsule(0.08, 0.5), _coat_mat, Vector3(-0.38, 1.22, 0.05), Vector3(deg_to_rad(-25), 0, deg_to_rad(18)))
	_add_mesh("ArmR", _capsule(0.08, 0.5), _coat_mat, Vector3(0.4, 1.28, -0.08), Vector3(deg_to_rad(-55), deg_to_rad(-10), deg_to_rad(-25)))
	_add_mesh("MittL", _sphere(0.11), _mat(colors.mitts), Vector3(-0.48, 0.92, 0.14))
	_add_mesh("MittR", _sphere(0.11), _mat(colors.mitts), Vector3(0.55, 1.02, -0.32))
	_add_mesh("MittThumbL", _sphere(0.045), _mat(colors.mitts), Vector3(-0.4, 0.98, 0.2))
	_add_mesh("MittThumbR", _sphere(0.045), _mat(colors.mitts), Vector3(0.48, 1.08, -0.22))

	_add_mesh("Collar", _torusish(0.22, 0.07), _mat(colors.scarf), Vector3(0, 1.52, 0.02))
	_add_mesh("ScarfTail", _box(Vector3(0.14, 0.4, 0.09)), _mat(colors.scarf), Vector3(0.16, 1.28, 0.14), Vector3(deg_to_rad(18), 0, deg_to_rad(-22)))

	var head := _add_mesh("Head", _sphere(0.18), _mat(colors.skin), Vector3(0, 1.72, 0))
	_add_mesh("HatCrown", _sphere(0.19, 0.26), _mat(colors.hat), Vector3(0, 1.88, 0))
	_add_mesh("HatBrim", _cylinder(0.26, 0.035), _mat(colors.hat), Vector3(0, 1.76, 0))
	_add_mesh("PomPom", _sphere(0.07), _mat(colors.pompom), Vector3(0, 2.05, 0))

	if show_face:
		_add_mesh("EyeL", _sphere(0.032), _mat(Color(0.08, 0.1, 0.14)), Vector3(-0.055, 1.74, -0.15))
		_add_mesh("EyeR", _sphere(0.032), _mat(Color(0.08, 0.1, 0.14)), Vector3(0.055, 1.74, -0.15))
		_add_mesh("EyeWhiteL", _sphere(0.018), _mat(Color(0.95, 0.95, 0.97)), Vector3(-0.05, 1.745, -0.17))
		_add_mesh("EyeWhiteR", _sphere(0.018), _mat(Color(0.95, 0.95, 0.97)), Vector3(0.05, 1.745, -0.17))
		_add_mesh("Nose", _sphere(0.035, 0.05), _mat(Color(0.95, 0.55, 0.35)), Vector3(0, 1.69, -0.17))
		_add_mesh("CheekL", _sphere(0.04), _mat(Color(1.0, 0.62, 0.55)), Vector3(-0.1, 1.67, -0.11))
		_add_mesh("CheekR", _sphere(0.04), _mat(Color(1.0, 0.62, 0.55)), Vector3(0.1, 1.67, -0.11))
		_add_mesh("Smile", _box(Vector3(0.08, 0.015, 0.02)), _mat(Color(0.55, 0.25, 0.28)), Vector3(0, 1.63, -0.16))

	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func flash_hit(duration: float = 0.12) -> void:
	if body_mesh == null or not (body_mesh.material_override is StandardMaterial3D):
		return
	var mat := body_mesh.material_override as StandardMaterial3D
	var original := mat.albedo_color
	mat.albedo_color = Color(1.0, 0.42, 0.42)
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(mat):
		mat.albedo_color = original


func _palette_colors(kind: String) -> Dictionary:
	if kind == "player":
		return {
			"coat": Color(0.32, 0.55, 0.42),
			"pants": Color(0.22, 0.28, 0.34),
			"boots": Color(0.18, 0.14, 0.12),
			"mitts": Color(0.92, 0.9, 0.86),
			"scarf": Color(0.86, 0.28, 0.28),
			"hat": Color(0.86, 0.28, 0.28),
			"pompom": Color(0.95, 0.95, 0.92),
			"skin": Color(0.92, 0.78, 0.68),
		}
	return {
		"coat": Color(0.2, 0.42, 0.62),
		"pants": Color(0.16, 0.2, 0.28),
		"boots": Color(0.12, 0.1, 0.1),
			"mitts": Color(0.98, 0.93, 0.78),
			"scarf": Color(0.9, 0.55, 0.18),
			"hat": Color(0.78, 0.2, 0.22),
			"pompom": Color(0.95, 0.95, 0.9),
			"skin": Color(0.86, 0.68, 0.56),
		}


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.82
	return m


func _add_mesh(node_name: String, mesh: Mesh, material: Material, pos: Vector3, euler: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation = euler
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mi)
	return mi


func _capsule(radius: float, height: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = height
	m.radial_segments = 16
	return m


func _sphere(radius: float, height: float = -1.0) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = height if height > 0.0 else radius * 2.0
	m.radial_segments = 18
	m.rings = 10
	return m


func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


func _cylinder(radius: float, height: float, bottom_radius: float = -1.0) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = bottom_radius if bottom_radius > 0.0 else radius
	m.height = height
	m.radial_segments = 16
	return m


func _torusish(radius: float, thickness: float) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = maxf(0.01, radius - thickness)
	m.outer_radius = radius
	m.rings = 18
	m.ring_segments = 12
	return m
