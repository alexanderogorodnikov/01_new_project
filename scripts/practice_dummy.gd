extends StaticBody3D
## Simple hit target for Stage 1–2 throw testing (placeholder for Stage 3 bots).

@export var damage_id: StringName = &"dummy"
@export var max_health: float = 100.0

var health: float = 100.0

@onready var mesh: MeshInstance3D = $Mesh


func _ready() -> void:
	add_to_group("damageable")
	health = max_health


func on_snowball_hit(damage: float, _attacker_id: StringName) -> void:
	health = maxf(0.0, health - damage)
	if mesh:
		var tween := create_tween()
		var base_scale := Vector3.ONE
		mesh.scale = base_scale * 1.08
		tween.tween_property(mesh, "scale", base_scale, 0.12)
	if health <= 0.0:
		health = max_health
		print("Practice dummy reset")
