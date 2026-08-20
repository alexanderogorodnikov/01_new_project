extends RigidBody3D
class_name Snowball
## Physical snowball with mass, friction, hit detection, and break VFX.

signal broken(position: Vector3)

const BREAK_SPEED := 2.5
const HIT_DAMAGE := 20.0
const LIFETIME_SEC := 12.0

@export var owner_id: StringName = &"player"
@export var damage: float = HIT_DAMAGE

var _held: bool = false
var _thrown: bool = false
var _lifetime: float = 0.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var break_particles: GPUParticles3D = $BreakParticles


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	freeze = true
	_held = true


func _physics_process(delta: float) -> void:
	if _held:
		return
	_lifetime += delta
	if _lifetime >= LIFETIME_SEC:
		_break_apart()


func is_in_flight() -> bool:
	return _thrown and not _held


func attach_to(parent: Node3D) -> void:
	_held = true
	_thrown = false
	freeze = true
	collision.disabled = true
	reparent(parent, true)
	global_transform = parent.global_transform
	position = Vector3.ZERO
	rotation = Vector3.ZERO


func throw_with_velocity(world_velocity: Vector3) -> void:
	var world_pos := global_position
	var world_basis := global_basis
	var tree := get_tree()
	if tree == null:
		return

	var target_parent := _resolve_world_parent(tree)
	if target_parent:
		reparent(target_parent, true)
	global_position = world_pos
	global_basis = world_basis

	collision.disabled = false
	freeze = false
	_held = false
	_thrown = true
	linear_velocity = world_velocity
	angular_velocity = world_velocity.cross(Vector3.UP) * 0.35


func _resolve_world_parent(tree: SceneTree) -> Node:
	if tree.current_scene:
		return tree.current_scene
	var main := tree.root.get_node_or_null("Main")
	if main:
		return main
	# Last resort: first non-autoload child under root.
	for child in tree.root.get_children():
		var name_str := String(child.name)
		if name_str != "XRManager" and name_str != "GameState":
			return child
	return tree.root


func _on_body_entered(body: Node) -> void:
	if _held or not _thrown:
		return

	if body.is_in_group("damageable"):
		var target_id: StringName = &"unknown"
		if "damage_id" in body:
			target_id = body.damage_id
		# Ignore self-hits / friendly same-id collisions.
		if target_id == owner_id:
			return
		GameState.apply_damage(target_id, damage, owner_id)
		if body.has_method("on_snowball_hit"):
			body.on_snowball_hit(damage, owner_id)
		_break_apart()
		return

	if linear_velocity.length() >= BREAK_SPEED:
		_break_apart()


func _break_apart() -> void:
	if not is_inside_tree():
		return
	var pos := global_position
	broken.emit(pos)
	mesh.visible = false
	collision.set_deferred("disabled", true)
	freeze = true
	if break_particles:
		break_particles.global_position = pos
		break_particles.emitting = true
	await get_tree().create_timer(0.6).timeout
	queue_free()
